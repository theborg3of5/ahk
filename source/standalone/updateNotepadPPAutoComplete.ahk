#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; GDB TODO determine whether any of these constants should really live outside of the new class/member classes
global startClassCommentBase := "
	(
        <!-- *gdb START CLASS: <CLASS_NAME> -->
	)"
global endClassCommentBase := "
	(
        <!-- *gdb END CLASS: <CLASS_NAME> -->
	)"

; <PARAMS_XML> has no indent/newline so each line of the params can indent itself the same.
; Always func="yes", because that allows us to get a popup with the info.
global keywordBaseXML := "
	(
        <KeyWord name=""<FULL_NAME>"" func=""yes"">
            <Overload retVal=""<RETURNS>"" descr=""<DESCRIPTION>""><PARAMS_XML>
            </Overload>
        </KeyWord>
	)"
global paramBaseXML := "
	(
                <Param name=""<PARAM_NAME>"" />
	)"
global docSeparator := ";---------"
global scopeStartPublic  := "; #PUBLIC#"
global scopeStartPrivate := "; #PRIVATE#"
global scopeStartDebug   := "; #DEBUG#"
global scopeEnd          := "; #END#"
global headerIndent := StringLib.getTabs(7) ; We can indent with tabs and it's ignored - cleaner XML and result looks the same.
global returnValueProperty := "[Property]"

; Read in the current XML, to update
autoCompleteFilePath := Config.path["AHK_SUPPORT"] "\notepadPPAutoComplete.xml"
autoCompleteXML := FileRead(autoCompleteFilePath)

; Get info about all classes we care about and use it to update the XML
classes := getAllCommonClasses()
if(!updateClassesInXML(classes, autoCompleteXML, failedClasses)) {
	handleFailedClasses(failedClasses)
	ExitApp
}

; Update the version-controlled file
FileLib.replaceFileWithString(autoCompleteFilePath, autoCompleteXML)

; Update the file Notepad++ is actually using
activeAutoCompleteFilePath := Config.path["PROGRAM_FILES"] "\Notepad++\autoCompletion\AutoHotkey.xml"
FileLib.replaceFileWithString(activeAutoCompleteFilePath, autoCompleteXML)

; Notify the user that we're done and exit.
new Toast("Updated both versions of the auto-complete file").blockingOn().showMedium()
ExitApp



getAllCommonClasses() {
	commonRoot := Config.path["AHK_SOURCE"] "\common\"
	
	classes := {}
	classes.appendObject(getClassesFromFolder(commonRoot "base"))
	classes.appendObject(getClassesFromFolder(commonRoot "class"))
	classes.appendObject(getClassesFromFolder(commonRoot "lib"))
	classes.appendObject(getClassesFromFolder(commonRoot "static"))
	; Deliberately leaving external\ out - don't want to try and document those myself, no good reason to.
	
	; Post-processing
	classesToDelete := []
	For className,classObj in classes {
		; Mark any classes with no members for deletion
		if(classObj.members.count() = 0)
			classesToDelete.push(className)
		
		; Add any inherited members (only 1 layer deep) into the array of info for this class
		if(classObj.parentName != "") {
			For _,member in classes[classObj.parentName].members
				classObj.addMemberIfNew(member)
		}
	}
	For _,className in classesToDelete
		classes.Delete(className)
	
	return classes
}



getClassesFromFolder(folderPath) {
	classes := {}
	
	; Loop over all scripts in folder to find classes
	Loop, Files, %folderPath%\*.ahk, RF ; [R]ecursive, [F]iles (not [D]irectories)
	{
		linesAry := FileLib.fileLinesToArray(A_LoopFileLongPath, true)
		
		ln := 0 ; Lines start at 1 (and the loop starts by increasing the index).
		while(ln < linesAry.count()) {
			line := linesAry.next(ln)
			
			; Block of documentation - read the whole thing in and create a member.
			if(line = docSeparator) {
				; Store the full header in an array
				headerLines := [line]
				Loop {
					line := linesAry.next(ln)
					headerLines.push(line)
					
					if(line = docSeparator)
						Break
				}
				
				; Get the definition line (first line after the header), too.
				defLine := linesAry.next(ln)
				
				; Feed the data to a new member object and add that to our current class object.
				member := new AutoCompleteMember(defLine, headerLines)
				classObj.addMember(member)
				
				Continue
			}
			
			; Block of private/debug scope - ignore everything up until we hit a public/end of scope.
			if(line = scopeStartPrivate || line = scopeStartDebug) {
				while(line != scopeStartPublic && line != scopeEnd) {
					line := linesAry.next(ln)
				}
				
				Continue
			}
			
			; Class declaration
			if(line.startsWith("class ") && line.endsWith(" {") && line != "class {") {
				classObj := new AutoCompleteClass(line)
				classes[classObj.name] := classObj ; Point to classObj (which is what we'll actually be updating) from classes object
				
				Continue
			}
		}
	}
	
	return classes
}

updateClassesInXML(classes, ByRef xml, ByRef failedClasses) {
	failedClasses := []

	For _,classObj in classes {
		startComment := classObj.startComment
		endComment   := classObj.endComment
		
		; Fail this class if there's not already a block to replace in the XML.
		if(!xml.contains(startComment) || !xml.contains(endComment)) {
			failedClasses.push(classObj)
			Continue
		}
		
		; Find the block in the original XML for this class and replace it with the class' XML (which
		; includes the start/end comments).
		xmlBefore := xml.beforeString(classObj.startComment)
		xmlAfter := xml.afterString(classObj.endComment)
		xml := xmlBefore classObj.generateXML() xmlAfter
	}
	
	return (DataLib.isNullOrEmpty(failedClasses))
}


handleFailedClasses(failedClasses) {
	failedNames  := ""
	failedBlocks := ""
	
	For _,classObj in failedClasses {
		failedNames := failedNames.appendPiece(classObj.name, ",")
		failedBlocks .= "`n" classObj.emptyBlock
	}

	ClipboardLib.set(failedBlocks)
	new ErrorToast("Blocks for some classes could not be found in the existing file", "Could not find matching comment block for these classes: " failedNames, "Comment blocks for all failed classes have been added to the clipboard - add them into the file in alphabetical order").blockingOn().showLong()
}


; Represents an entire class that we want to add auto-complete info for.
class AutoCompleteClass {
	; #PUBLIC#
	
	; GDB TODO document class
	name       := ""
	parentName := ""
	members    := {} ; {.memberName: AutoCompleteMember}
	
	
	startComment {
		get {
			return startClassCommentBase.replaceTag("CLASS_NAME", this.name)
		}
	}
	
	endComment {
		get {
			return endClassCommentBase.replaceTag("CLASS_NAME", this.name)
		}
	}
	
	emptyBlock {
		get {
			; Extra newlines so we can paste this at the end of the line this should follow, leaving
			; an extra line of space above and below.
			return "`n" this.startComment "`n" this.endComment "`n"
		}
	}
	
	
	__New(defLine) {
		this.name := defLine.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
		if(defLine.contains(" extends "))
			this.parentName := defLine.firstBetweenStrings(" extends ", " {")
	}
	
	
	addMember(member) {
		if(member.name = "")
			return
		
		dotName := "." member.name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
		this.members[dotName] := member
	}
	addMemberIfNew(member) {
		if(member.name = "")
			return
		
		dotName := "." member.name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
		if(this.members.HasKey(dotName))
			return
		
		this.members[dotName] := member
	}
	
	generateXML() {
		xml := this.startComment
		
		For _,member in this.members
			xml .= "`n" member.generateXML(this.name)
		
		xml .= "`n" this.endComment
		
		; Debug.popup("AutoCompleteClass.generateXML()",, "this",this, "xml",xml)
		return xml
	}
	
	; #PRIVATE#
	
	
	
	
	; #DEBUG#
	
	debugName := "AutoCompleteClass"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Name", this.name)
		debugBuilder.addLine("Parent name", this.parentName)
		debugBuilder.addLine("Members", this.members)
	}
	; #END#
}

; Represents a single class member that we want to add auto-complete info for.
class AutoCompleteMember {
	; #PUBLIC#
	
	name        := ""
	returns     := ""
	description := ""
	paramsAry   := []
	
	
	__New(defLine, headerLines) {
		AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
		this.name      := name
		this.paramsAry := paramsAry
		
		; Properties get special handling to call them out as properties (not functions), since you have to use an open paren to get the popup to display.
		if(!defLine.contains("("))
			this.returns := returnValueProperty
		
		; The description is the actual function header, indented nicely.
		this.description := this.formatHeaderAsDescription(headerLines)
	}
	
	
	generateXML(className) {
		xml := keywordBaseXML
		
		xml := xml.replaceTag("FULL_NAME",   this.generateFullName(className))
		xml := xml.replaceTag("RETURNS",     this.returns)
		xml := xml.replaceTag("DESCRIPTION", this.description)
		xml := xml.replaceTag("PARAMS_XML",  this.generateParamsXML())
		
		return xml
	}
	
	
	; #PRIVATE#
	
	formatHeaderAsDescription(headerLines) {
		; Put the lines back together
		headerText := headerLines.join("`n")
		
		; Replace double-quotes with their XML-safe equivalent
		headerText := headerText.replace("""", "&quot;")
		
		; Add a newline at the start to separate the header from the definition line in the popup
		headerText := "`n" headerText
		
		; Indent the whole thing with tabs (which appear in the XML but are ignored in the popup)
		headerText := headerText.replace("`n", "`n" headerIndent)
		
		return headerText
	}
	
	generateFullName(className) {
		; Special case: constructors are just <className>
		if(this.name = "__New")
			return className
		
		; Full name is <class>.<member>
		return className "." this.name
	}
	
	generateParamsXML() {
		if(DataLib.isNullOrEmpty(this.paramsAry))
			return ""
		
		paramsXML := ""
		For _,paramName in this.paramsAry {
			paramName := paramName.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
			xml := paramBaseXML.replaceTag("PARAM_NAME", paramName)
			
			paramsXML .= "`n" xml ; Start with an extra newline to put the params block on a new line
		}
		
		return paramsXML
	}
	
	
	; #DEBUG#
	
	debugName := "AutoCompleteMember"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Name", this.name)
		debugBuilder.addLine("Returns", this.returns)
		debugBuilder.addLine("Description", this.description)
		debugBuilder.addLine("Params array", this.paramsAry)
	}
	; #END#
}
