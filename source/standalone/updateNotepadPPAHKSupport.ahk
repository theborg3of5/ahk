#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; Constants we use to pick apart scripts for their component parts.
global Header_StartEnd    := ";---------"
global ScopeStart_Public  := "; #PUBLIC#"
global ScopeStart_Private := "; #PRIVATE#"
global ScopeStart_Debug   := "; #DEBUG#"
global ScopeEnd           := "; #END#"

completionFile       := Config.path["AHK_SUPPORT"]   "\notepadPPAutoComplete.xml"
completionFileActive := Config.path["PROGRAM_FILES"] "\Notepad++\autoCompletion\AutoHotkey.xml"
syntaxFile           := Config.path["AHK_SUPPORT"]   "\notepadPPSyntaxHighlighting.xml"
syntaxFileActive     := Config.path["USER_APPDATA"]  "\Notepad++\userDefineLang.xml"

; [[ Auto-complete ]]
; Read in the current XML, to update
autoCompleteXML := FileRead(completionFile)

; Get info about all classes we care about and use it to update the XML
classes := getAllCommonClasses()
if(!updateClassesInXML(classes, autoCompleteXML, failedClasses)) {
	handleFailedClasses(failedClasses)
	ExitApp
}

FileLib.replaceFileWithString(completionFile, autoCompleteXML)
FileLib.replaceFileWithString(completionFileActive, autoCompleteXML)

t := new Toast("Updated both versions of the auto-complete file").show()

; [[ Syntax highlighting ]]
; Get the <UserLang> tag from the support XML
syntaxXML := FileRead(syntaxFile)
langXML := syntaxXML.allBetweenStrings("<NotepadPlus>", "</NotepadPlus>").clean() ; Trim off the newlines and initial indentation too

; Replace the same tag in the active XML and write it to the active file
syntaxXMLActive := FileRead(syntaxFileActive)
beforeXML := syntaxXMLActive.beforeString("<UserLang name=""AutoHotkey""")
afterXML := syntaxXMLActive.afterString("<UserLang name=""AutoHotkey""").afterString("</UserLang>")
newSyntaxXML := beforeXML langXML afterXML
FileLib.replaceFileWithString(syntaxFileActive, newSyntaxXML)

t.setText("Updated syntax highlighting tag for Notepad++ (requires restart)").blockingOn().showMedium()

ExitApp


;---------
; DESCRIPTION:    Get AutoCompleteClass objects for all relevant classes in the common\ folder,
;                 excluding those with no public members.
; RETURNS:        An associative array of AutoCompleteClass objects, indexed by the class' names.
;---------
getAllCommonClasses() {
	commonRoot := Config.path["AHK_SOURCE"] "\common\"
	
	classes := {}
	classes.mergeFromObject(getClassesFromFolder(commonRoot "base"))
	classes.mergeFromObject(getClassesFromFolder(commonRoot "class"))
	classes.mergeFromObject(getClassesFromFolder(commonRoot "lib"))
	classes.mergeFromObject(getClassesFromFolder(commonRoot "static"))
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


;---------
; DESCRIPTION:    Get AutoCompleteClass objects for all classes in all scripts in the given folder.
; PARAMETERS:
;  folderPath (I,REQ) - The full path to the folder to read from.
; RETURNS:        An associative array of AutoCompleteClass objects, indexed by the class' names.
;---------
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
			if(line = Header_StartEnd) {
				; Store the full header in an array
				headerLines := [line]
				Loop {
					line := linesAry.next(ln)
					headerLines.push(line)
					
					if(line = Header_StartEnd)
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
			if(line = ScopeStart_Private || line = ScopeStart_Debug) {
				while(line != ScopeStart_Public && line != ScopeEnd) {
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

;---------
; DESCRIPTION:    Update the given XML with the XML of the given classes.
; PARAMETERS:
;  classes       (I,REQ) - An array of AutoCompleteClass objects to update in the XML.
;  xml          (IO,REQ) - The XML to update.
;  failedClasses (O,REQ) - If we can't find the right place to put any of the given classes, we'll
;                          return an array of the problematic AutoCompleteClass objects here.
; RETURNS:        true/false - were we able to add all classes?
;---------
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
		xmlBefore := xml.beforeString(startComment)
		xmlAfter := xml.afterString(endComment)
		xml := xmlBefore classObj.generateXML() xmlAfter
	}
	
	return (DataLib.isNullOrEmpty(failedClasses))
}

;---------
; DESCRIPTION:    Notify the user that we couldn't add some classes to the XML, and put the empty
;                 blocks for those on the clipboard for the user to add manually.
; PARAMETERS:
;  failedClasses (I,REQ) - An array of AutoCompleteClass objects for the classes we couldn't add
;                          to the auto-complete XML file.
;---------
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
	
	name       := "" ; The class' name
	parentName := "" ; The name of the class' parent (if it extends another class)
	members    := {} ; {.memberName: AutoCompleteMember}
	
	;---------
	; DESCRIPTION:    The starting comment for this class - this goes at the end of the XML block for
	;                 this class.
	;---------
	startComment {
		get {
			return this.CommentBase_Start.replaceTag("CLASS_NAME", this.name)
		}
	}
	
	;---------
	; DESCRIPTION:    The ending comment for this class - this goes at the end of the XML block for
	;                 this class.
	;---------
	endComment {
		get {
			return this.CommentBase_End.replaceTag("CLASS_NAME", this.name)
		}
	}
	
	;---------
	; DESCRIPTION:    The XML to give to the user when we don't have somewhere to put this class'
	;                 XML - just the starting and ending comments, plus newlines to space things
	;                 out nicely.
	;---------
	emptyBlock {
		get {
			; Extra newlines so we can paste this at the end of the line this should follow, leaving
			; an extra line of space above and below.
			return "`n" this.startComment "`n" this.endComment "`n"
		}
	}
	
	
	;---------
	; DESCRIPTION:    Create a new class representation.
	; PARAMETERS:
	;  defLine (I,REQ) - The definition line for the class - the one that starts with "class ".
	;---------
	__New(defLine) {
		this.name := defLine.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
		if(defLine.contains(" extends "))
			this.parentName := defLine.firstBetweenStrings(" extends ", " {")
	}
	
	;---------
	; DESCRIPTION:    Add the given member to this class.
	; PARAMETERS:
	;  member (I,REQ) - The member to add.
	;---------
	addMember(member) {
		if(member.name = "")
			return
		
		dotName := "." member.name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
		this.members[dotName] := member
	}
	;---------
	; DESCRIPTION:    Add the given member to this class, but only if a member with the same name
	;                 doesn't already exist.
	; PARAMETERS:
	;  member (I,REQ) - The member to add.
	;---------
	addMemberIfNew(member) {
		if(member.name = "")
			return
		
		dotName := "." member.name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
		if(this.members.HasKey(dotName))
			return
		
		this.members[dotName] := member
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this class and all of its members.
	; RETURNS:        The generated XML
	;---------
	generateXML() {
		xml := this.startComment
		
		For _,member in this.members
			xml .= "`n" member.generateXML(this.name)
		
		xml .= "`n" this.endComment
		
		; Debug.popup("AutoCompleteClass.generateXML()",, "this",this, "xml",xml)
		return xml
	}
	
	
	; #PRIVATE#
	
	; XML comments that go at the start/end of all members of the class.
	static CommentBase_Start := "
		(
        <!-- *gdb START CLASS: <CLASS_NAME> -->
		)"
	static CommentBase_End := "
		(
        <!-- *gdb END CLASS: <CLASS_NAME> -->
		)"
	
	
	; #DEBUG#
	
	getDebugTypeName() {
		return "AutoCompleteClass"
	}
	
	debugToString(ByRef builder) {
		builder.addLine("Name",        this.name)
		builder.addLine("Parent name", this.parentName)
		builder.addLine("Members",     this.members)
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
	
	;---------
	; DESCRIPTION:    Create a new member.
	; PARAMETERS:
	;  defLine     (I,REQ) - The definition line for the member - that is, its first line
	;                        (function definition, etc.).
	;  headerLines (I,REQ) - An array of lines making up the full header for this member.
	;---------
	__New(defLine, headerLines) {
		AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
		this.name      := name
		this.paramsAry := paramsAry
		
		; Properties get special handling to call them out as properties (not functions), since you have to use an open paren to get the popup to display.
		if(!defLine.contains("("))
			this.returns := this.ReturnValue_Property
		
		; The description is the actual function header, indented nicely.
		this.description := this.formatHeaderAsDescription(headerLines)
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this member.
	; PARAMETERS:
	;  className (I,REQ) - The class that this member belongs to.
	; RETURNS:        The XML for this member.
	;---------
	generateXML(className) {
		xml := this.BaseXML_Keyword
		
		xml := xml.replaceTag("FULL_NAME",   this.generateFullName(className))
		xml := xml.replaceTag("RETURNS",     this.returns)
		xml := xml.replaceTag("DESCRIPTION", this.description)
		xml := xml.replaceTag("PARAMS_XML",  this.generateParamsXML())
		
		return xml
	}
	
	
	; #PRIVATE#
	
	static ReturnValue_Property := "[Property]"
	; <PARAMS_XML> has no indent/newline so each line of the params can indent itself the same.
	; Always func="yes", because that allows us to get a popup with the info.
	static BaseXML_Keyword := "
		(
        <KeyWord name=""<FULL_NAME>"" func=""yes"">
            <Overload retVal=""<RETURNS>"" descr=""<DESCRIPTION>""><PARAMS_XML>
            </Overload>
        </KeyWord>
		)"
	static BaseXML_Param := "
		(
                <Param name=""<PARAM_NAME>"" />
		)"
	static Indent_Header := StringLib.getTabs(7) ; We can indent with tabs and it's ignored - cleaner XML and result looks the same.
	
	;---------
	; DESCRIPTION:    Turn the array of documentation lines into a single, indented, XML-safe string.
	; PARAMETERS:
	;  headerLines (I,REQ) - An array of lines containing the header for this member.
	; RETURNS:        The header string to plug into the XML description for the member.
	;---------
	formatHeaderAsDescription(headerLines) {
		; Put the lines back together
		headerText := headerLines.join("`n")
		
		; Replace double-quotes with their XML-safe equivalent
		headerText := headerText.replace("""", "&quot;")
		
		; Add a newline at the start to separate the header from the definition line in the popup
		headerText := "`n" headerText
		
		; Indent the whole thing with tabs (which appear in the XML but are ignored in the popup)
		headerText := headerText.replace("`n", "`n" this.Indent_Header)
		
		return headerText
	}
	
	;---------
	; DESCRIPTION:    Determine the full name of this member.
	; PARAMETERS:
	;  className (I,REQ) - The name of the class this member is part of.
	; RETURNS:        Either className.memberName, or just className for constructors.
	;---------
	generateFullName(className) {
		; Special case: constructors are just <className>
		if(this.name = "__New")
			return className
		
		; Full name is <class>.<member>
		return className "." this.name
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this member's parameters (if any).
	; RETURNS:        The generated XML
	;---------
	generateParamsXML() {
		if(DataLib.isNullOrEmpty(this.paramsAry))
			return ""
		
		paramsXML := ""
		For _,paramName in this.paramsAry {
			paramName := paramName.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
			xml := this.BaseXML_Param.replaceTag("PARAM_NAME", paramName)
			
			paramsXML .= "`n" xml ; Start with an extra newline to put the params block on a new line
		}
		
		return paramsXML
	}
	
	
	; #DEBUG#
	
	getDebugTypeName() {
		return "AutoCompleteMember"
	}
	buildDebugDisplay(ByRef builder) {
		builder.addLine("Name",         this.name)
		builder.addLine("Returns",      this.returns)
		builder.addLine("Description",  this.description)
		builder.addLine("Params array", this.paramsAry)
	}
	; #END#
}
