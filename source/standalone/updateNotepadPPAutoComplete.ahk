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



classDocs := getAllCommonDocs()

autoCompleteXMLs := generateXMLForClasses(classDocs)

autoCompleteFilePath := Config.path["AHK_SUPPORT"] "\notepadPPAutoComplete.xml"
originalXML := FileRead(autoCompleteFilePath)

newXML := originalXML
failedClasses := {}
For className,classXML in autoCompleteXMLs { ; GDB TODO break this section up more
	; Find the block in the original XML for this class
	startBlockComment := startClassCommentBase.replaceTag("CLASS_NAME", className)
	endBlockComment   := endClassCommentBase.replaceTag("CLASS_NAME", className)
	
	if(!newXML.contains(startBlockComment) || !newXML.contains(endBlockComment)) {
		failedClasses[className] := classXML
		Continue
	}
	
	xmlBefore := newXML.beforeString(startBlockComment)
	xmlAfter := newXML.afterString(endBlockComment)
	newXML := xmlBefore classXML xmlAfter
}

failedNameList := ""
failedBlocks   := ""
if(!DataLib.isNullOrEmpty(failedClasses)) {
	For className,classXML in failedClasses {
		failedNameList := failedNameList.appendPiece(className)
		
		startBlockComment := startClassCommentBase.replaceTag("CLASS_NAME", className)
		endBlockComment   := endClassCommentBase.replaceTag("CLASS_NAME", className)
		failedBlocks .= "`n`n" startBlockComment "`n" endBlockComment "`n" ; Made so it can be pasted at the end of the last line it should be after - extra line of space above and below the new block.
	}
	
	ClipboardLib.set(failedBlocks)
	new ErrorToast("Could not add some classes' XML to auto-complete file", "Could not find matching comment block for these classes: " failedNameList, "Comment blocks for all failed classes have been added to the clipboard - add them into the file in alphabetical order").blockingOn().showLong()
}

; clipboard := newXML
FileLib.replaceFileWithString(autoCompleteFilePath, newXML)

activeAutoCompleteFilePath := Config.path["PROGRAM_FILES"] "\Notepad++\autoCompletion\AutoHotkey.xml"
FileLib.replaceFileWithString(activeAutoCompleteFilePath, newXML)

new Toast("Updated both versions of the auto-complete file").blockingOn().showMedium()
ExitApp



getAllCommonDocs() {
	commonRoot := Config.path["AHK_SOURCE"] "\common\"
	
	docs := {}
	docs.appendObject(getDocsForAllScriptsInFolder(commonRoot "base"))
	docs.appendObject(getDocsForAllScriptsInFolder(commonRoot "class"))
	docs.appendObject(getDocsForAllScriptsInFolder(commonRoot "lib"))
	docs.appendObject(getDocsForAllScriptsInFolder(commonRoot "static"))
	; Deliberately leaving external\ out - don't want to try and document those myself, no good reason to.
	
	
	
	; tempClass := docs["ActionObjectBase"]
	; MsgBox, % "ActionObjectBase: " tempClass.generateXML()
	
	
	return docs
}



getDocsForAllScriptsInFolder(folderPath) {
	docs := {}
	Loop, Files, %folderPath%\*.ahk, RF ; Recursive, files (not directories)
	{ ; GDB TODO: should we just make this an infinite loop (or do some pre-processing before-hand) so we don't need to have the inBlock/outOfScope stuff?
		linesAry := FileLib.fileLinesToArray(A_LoopFileLongPath)
		
		; Find groups of lines that give us info about a function - basically the stuff between two docSeparator lines, and the line following (which should have the name).
		inBlock := false
		outOfScope := false
		headerLines := []
		
		; currClassName := ""
		
		; classDocs := {} ; {className: {className.memberName: docInfo}}
		
		For lineNumber,line in linesAry {
			line := line.withoutWhitespace()
			
			; Finishing a block - grab the name from the next line (which should be a definition line) and store everything off.
			if(inBlock) {
				if(line = docSeparator) {
					headerLines.push(line)
					defLine := linesAry[lineNumber + 1]
					
					member := new AutoCompleteMember(defLine, headerLines)
					classObj.addMember(member)
					
					
					
					; AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
					
					; ; Properties get special handling to call them out as properties (not functions), since you have to use an open paren to get the popup to display.
					; retValue := ""
					; if(!defLine.contains("("))
						; retValue := returnValueProperty
					
					; headerText := "`n" headerIndent headerLines.join("`n" headerIndent) ; Add a newline at the start to separate the header from the definition line in the popup
					; headerText := headerText.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
					
					; dotName := "." name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
					; classDocs[currClassName, dotName] := {"NAME":name, "RETURNS":retValue, "DESCRIPTION":headerText, "PARAMS_ARY":paramsAry, "PARENT_CLASS":currParentClassName}
					
					
					
					headerLines := []
					inBlock := false
				} else {
					headerLines.push(line)
				}
				Continue
			}
			
			; Ignore stuff that's in a private or debug scope.
			if(line = scopeStartPrivate || line = scopeStartDebug) {
				outOfScope := true
			}
			if(outOfScope) {
				if(line = scopeStartPublic || line = scopeEnd)
					outOfScope := false
				else
					Continue
			}
			
			if(line = docSeparator) {
				headerLines.push(line)
				inBlock := true
				Continue
			}
			
			; Class declaration
			if(line.startsWith("class ") && line.endsWith(" {") && line != "class {") {
				classObj := new AutoCompleteClass(line)
				docs[classObj.name] := classObj ; Point to class (which is what we'll actually be updating) from docs
				
				Continue
			}
		}
		
		; docs.appendObject(classDocs)
	}
	
	return docs
}

generateXMLForClasses(classDocs) {
	allXML := {} ; {className: classXML}
	
	; Generate XML for each class
	For _,classObj in classDocs {
		; Add any inherited functions (only 1 layer deep) into the array of info for this class ; GDB TODO make this a pre-processing step, after we have all info but before we start generating any XML
		if(classObj.parentName != "") {
			For _,member in classDocs[classObj.parentName].members
				classObj.addMemberIfNew(member)
		}
		
		; Debug.popup("classObj",classObj, "classObj.generateXML()",classObj.generateXML())
		
		; Skip classes with no members
		if(classObj.members.count() = 0)
			Continue
		
		; classXML := class.generateXML()
		
		; ; Add an XML comment to say we're starting a block
		; startBlockComment := startClassCommentBase.replaceTag("CLASS_NAME", className)
		; classXML .= startBlockComment
		
		; For _,docs in class {
			; ; Debug.popup("className",className, "docs",docs)
			; memberXML := generateMemberXML(className, docs)
			; classXML := classXML.appendPiece(memberXML, "`n")
		; }
		
		; ; Add an XML comment to say we're ending a block
		; endBlockComment := endClassCommentBase.replaceTag("CLASS_NAME", className)
		; classXML := classXML.appendPiece(endBlockComment, "`n")
		
		; Flush to allXML
		; Debug.popup("class",class, "class.generateXML()",class.generateXML())
		allXML[classObj.name] := classObj.generateXML()
	}
	
	
	
	return allXML
	
}



; GDB TODO have these classes generate their own XMLs

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
	
	
	__New(defLine) {
		this.name := defLine.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
		if(defLine.contains(" extends "))
			this.parentName := defLine.firstBetweenStrings(" extends ", " {")
		
		; Debug.popup("this",this, "this.generateXML()",this.generateXML())
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
