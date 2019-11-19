#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

global startBlockCommentBaseXML := "
	(
        <!-- *gdb START CLASS: <CLASS_NAME> -->
	)"
global endBlockCommentBaseXML := "
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
For className,classXML in autoCompleteXMLs {
	; Find the block in the original XML for this class
	startBlockComment := startBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
	endBlockComment   := endBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
	
	if(!newXML.contains(startBlockComment) || !newXML.contains(endBlockComment)) {
		failedClasses[className] := classXML
		Continue
	}
	
	xmlBefore := newXML.beforeString(startBlockComment)
	xmlAfter := newXML.afterString(endBlockComment)
	newXML := xmlBefore classXML xmlAfter
}

failedNameList := ""
failedBlocks := ""
if(!DataLib.isNullOrEmpty(failedClasses)) {
	For className,classXML in failedClasses {
		failedNameList := failedNameList.appendPiece(className)
		
		startBlockComment := startBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
		endBlockComment   := endBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
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
	docs.mergeFromObject(getDocsForScriptsInFolder(commonRoot "base"))
	docs.mergeFromObject(getDocsForScriptsInFolder(commonRoot "class"))
	docs.mergeFromObject(getDocsForScriptsInFolder(commonRoot "lib"))
	docs.mergeFromObject(getDocsForScriptsInFolder(commonRoot "static"))
	; Deliberately leaving external\ out - don't want to try and document those myself, no good reason to.
	
	return docs
}



getDocsForScriptsInFolder(path) {
	docs := {}
	Loop, Files, %path%\*.ahk, RF ; Recursive, files (not directories)
	{
		linesAry := FileLib.fileLinesToArray(A_LoopFileLongPath)
		
		; Find groups of lines that give us info about a function - basically the stuff between two docSeparator lines, and the line following (which should have the name).
		inBlock := false
		outOfScope := false
		docLines := []
		
		currClassName := ""
		
		classDocs := {} ; {className: {className.memberName: docInfo}}
		
		For lineNumber,line in linesAry {
			line := line.withoutWhitespace()
			
			; Finishing a block - grab the name from the next line (which should be a definition line) and store everything off.
			if(inBlock) {
				if(line = docSeparator) {
					docLines.push(line)
					
					defLine := linesAry[lineNumber + 1]
					AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
					
					; Properties get special handling to call them out as properties (not functions), since you have to use an open paren to get the popup to display.
					retValue := ""
					if(!defLine.contains("("))
						retValue := returnValueProperty
					
					headerText := "`n" headerIndent docLines.join("`n" headerIndent) ; Add a newline at the start to separate the header from the definition line in the popup
					headerText := headerText.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
					
					; if(name = currClassName ".__New")
						; dotName := currClassName
					; else
						; dotName := currClassName "." name
					
					dotName := "." name
					classDocs[currClassName, dotName] := {"NAME":name, "RETURNS":retValue, "DESCRIPTION":headerText, "PARAMS_ARY":paramsAry, "PARENT_CLASS":currParentClassName}
					
					docLines := []
					inBlock := false
				} else {
					docLines.push(line)
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
				docLines.push(line)
				inBlock := true
				Continue
			}
			
			; Class declaration - any functions below this should start with "<className>."
			if(line.startsWith("class ") && line.endsWith(" {") && line != "class {") {
				; Get new class name
				currClassName := line.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
				currParentClassName := ""
				if(line.contains(" extends "))
					currParentClassName := line.firstBetweenStrings(" extends ", " {")
			}
		}
		
		docs.mergeFromObject(classDocs)
	}
	
	return docs
}

generateXMLForClasses(classDocs) {
	allXML := {} ; {className: classXML}
	
	; Generate XML for each class
	For className,classMembers in classDocs {
		
		; Add any inherited functions (only 1 layer deep) into the array of info for this class
		For _,keywordTags in classMembers {
			parentClassName := keywordTags["PARENT_CLASS"]
			
			if(parentClassName != "") {
				
				For parentMemberDotName,parentKeywordTags in classDocs[parentClassName] {
					; Debug.popup("parentClassName",parentClassName, "parentMemberDotName",parentMemberDotName, "parentKeywordTags",parentKeywordTags)
					
					if(classMembers.HasKey(parentMemberDotName)) ; Child object should win
						Continue
					
					classMembers[parentMemberDotName] := parentKeywordTags
				}
			}
			Break
		}
		
		classXML := ""
		
		; Add an XML comment to say we're starting a block
		startBlockComment := startBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
		classXML .= startBlockComment
		
		For _,docs in classMembers {
			; Debug.popup("className",className, "docs",docs)
			memberXML := generateMemberXML(className, docs)
			classXML := classXML.appendPiece(memberXML, "`n")
		}
		
		; Add an XML comment to say we're ending a block
		endBlockComment := endBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
		classXML := classXML.appendPiece(endBlockComment, "`n")
		
		; Flush to allXML
		allXML[className] := classXML
	}
	
	
	
	return allXML
	
}

generateMemberXML(className, docs) {
	xml := keywordBaseXML
	
	; Full name is "<class>.<member>", except for constructors which are just "<class>".
	if(docs["NAME"] = "__New")
		fullName := className
	else
		fullName := className "." docs["NAME"]
	
	xml := xml.replaceTag("FULL_NAME",   fullName)
	xml := xml.replaceTag("RETURNS",     docs["RETURNS"])
	xml := xml.replaceTag("DESCRIPTION", docs["DESCRIPTION"])
	xml := xml.replaceTag("PARAMS_XML",  getParamsXML(docs["PARAMS_ARY"]))
	
	return xml
}

getParamsXML(paramsAry) {
	if(DataLib.isNullOrEmpty(paramsAry))
		return ""
	
	paramsXML := ""
	For _,paramName in paramsAry {
		paramName := paramName.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
		xml := paramBaseXML.replaceTag("PARAM_NAME", paramName)
		
		paramsXML := paramsXML.appendPiece(xml, "`n")
	}
	
	return "`n" paramsXML ; Newline before the whole params block
}
