#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

startBlockCommentBaseXML := "
	(
        <!-- *gdb START CLASS: <CLASS_NAME> -->
	)"
endBlockCommentBaseXML := "
	(
        <!-- *gdb END CLASS: <CLASS_NAME> -->
	)"


commonRoot := Config.path["AHK_SOURCE"] "\common"

classInfos := {}
classInfos.mergeFromObject(getAutoCompleteInfoForFolder(commonRoot "\base"))
classInfos.mergeFromObject(getAutoCompleteInfoForFolder(commonRoot "\class"))
classInfos.mergeFromObject(getAutoCompleteInfoForFolder(commonRoot "\lib"))
classInfos.mergeFromObject(getAutoCompleteInfoForFolder(commonRoot "\static"))
; Debug.popup("classInfos",classInfos)

autoCompleteXMLs := generateXMLForClasses(classInfos)

autoCompleteFilePath := Config.path["AHK_SUPPORT"] "\AutoHotkey.xml"
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

getAutoCompleteInfoForFolder(path) {
	classInfos := {}
	Loop, Files, %path%\*.ahk, RF ; Recursive, files (not directories)
	{
		classInfos.mergeFromObject(getAutoCompleteInfoFromScript(A_LoopFileLongPath))
	}
	return classInfos
}

generateXMLForClasses(classInfos) {
	; Debug.popup("classInfos",classInfos)
	
	startBlockCommentBaseXML := "
		(
        <!-- *gdb START CLASS: <CLASS_NAME> -->
		)"
	endBlockCommentBaseXML := "
		(
        <!-- *gdb END CLASS: <CLASS_NAME> -->
		)"
	keywordBaseXML := "
		(
        <KeyWord name=""<NAME>"" func=""<IS_FUNC>"">
            <Overload retVal=""<RETURNS>"" descr=""<DESCRIPTION>""><PARAMS>
            </Overload>
        </KeyWord>
		)" ; <PARAMS> has no indent/newline so each line of the params can indent itself the same.
	paramBaseXML := "
		(
                <Param name=""<PARAM>"" />
		)"
	
	allXML := {}
	
	; Generate XML for each class
	For className,classInfo in classInfos {
		
		; Add any inherited functions (only 1 layer deep) into the array of info for this class
		For dotFunctionName,keywordTags in classInfo {
			parentClassName := keywordTags["PARENT_CLASS"]
			
			
			if(parentClassName != "") {
				; Debug.popup("className",className, "parentClassName",parentClassName, "dotFunctionName",dotFunctionName, "keywordTags",keywordTags, "classInfos[parentClassName]",classInfos[parentClassName])
				
				For parentDotFunctionName,parentKeywordTags in classInfos[parentClassName] {
					; Debug.popup("parentClassName",parentClassName, "parentDotFunctionName",parentDotFunctionName, "parentKeywordTags",parentKeywordTags)
					
					if(parentDotFunctionName = ".__New")
						parentDotFunctionName := "." className
					if(classInfo.HasKey(parentDotFunctionName)) ; Child object should win
						Continue
					
					classInfo[parentDotFunctionName] := parentKeywordTags
				}
			}
			Break
		}
		
		classXML := ""
		
		; Debug.popup("className",className, "classInfo",classInfo)
		
		; Add an XML comment to say we're starting a block
		startBlockComment := startBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
		classXML .= startBlockComment
		
		; Debug.popup("className",className)
		
		For dotFunctionName,keywordTags in classInfo {
			; Debug.popup("className",className, "dotFunctionName",dotFunctionName, "keywordTags",keywordTags)
			
			paramsAry := keywordTags["PARAMS_ARY"]
			
			allParamsXML := ""
			if(!DataLib.isNullOrEmpty(paramsAry)) {
				For _,param in paramsAry {
					param := param.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
					paramXML := paramBaseXML.replaceTag("PARAM", param)
					allParamsXML := allParamsXML.appendPiece(paramXML, "`n")
				}
				allParamsXML := "`n" allParamsXML ; Newline before the whole params block
			}
			
			keywordTags["PARAMS"] := allParamsXML
			
			functionName := dotFunctionName.removeFromStart(".")
			if(functionName = "__New")
				functionName := className
			else
				functionName := className "." functionName
			keywordTags["NAME"] := functionName
			
			; if(functionName.contains("contains"))
				; Debug.popup("keywordTags",keywordTags)
			
			functionXML := keywordBaseXML.replaceTags(keywordTags)
			classXML := classXML.appendPiece(functionXML, "`n")
		}
		
		; Add an XML comment to say we're ending a block
		endBlockComment := endBlockCommentBaseXML.replaceTag("CLASS_NAME", className)
		classXML := classXML.appendPiece(endBlockComment, "`n")
		
		; Flush to allXML
		allXML[className] := classXML
		
		; Debug.popup("className",className, "classXML",classXML)
	}
	
	
	
	return allXML
	
}

getAutoCompleteInfoFromScript(path) {
	docSeparator := ";---------"
	publicScopeStart  := "; #PUBLIC#"
	privateScopeStart := "; #PRIVATE#"
	debugScopeStart   := "; #DEBUG#"
	allScopeEnd       := "; #END#"
	
	
	linesAry := FileLib.fileLinesToArray(path)
	; Debug.popup("linesAry",linesAry)
	
	; Find groups of lines that give us info about a function - basically the stuff between two docSeparator lines, and the line following (which should have the name).
	inBlock := false
	outOfScope := false
	docLines := []
	
	classXML := ""
	currClassName := ""
	
	classFunctions := {} ; {functionName: keywordTags}
	classInfos := {} ; {className: classFunctions}
	
	For lineNumber,line in linesAry {
		line := line.withoutWhitespace()
		
		; Finishing a block - grab the name from the next line (which should be a definition line) and store everything off.
		if(inBlock) {
			if(line = docSeparator) {
				docLines.push(line)
				
				defLine := linesAry[lineNumber + 1]
				defLine := defLine.withoutWhitespace().beforeString(" {")
				name := getNameFromDefLine(defLine)
				params := getParamsListFromDefinitionLine(defLine)
				
				; Properties get special handling to call them out as properties (not functions), since you have to use an open paren to get the popup to display.
				retValue := ""
				if(!defLine.contains("(")) {
					retValue := "[Property]"
				}
				
				headerIndent := StringLib.getTabs(7) ; We can indent with tabs and it's ignored - cleaner XML and result looks the same.
				headerText := "`n" headerIndent docLines.join("`n" headerIndent) ; Add a newline at the start to separate the header from the definition line in the popup
				headerText := headerText.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
				
				paramsAry := []
				if(params != "")
					paramsAry := splitVarList(params)
				
				isFunc := "yes" ; Always "yes" - allows me to type an open paren and get the popup of info.
				
				; Store function info with an index preceded by a dot - otherwise we run into conflicts with things like contains(), which is actually a function for the object in question.
				classFunctions["." name] := {"NAME":name, "IS_FUNC":isFunc, "RETURNS":retValue, "DESCRIPTION":headerText, "PARAMS_ARY":paramsAry, "PARENT_CLASS":currParentClassName}
				
				; if(currParentClassName != "")
					; Debug.popup("currClassName",currClassName, "name",name, "currParentClassName",currParentClassName)
				
				docLines := []
				inBlock := false
			} else {
				docLines.push(line)
			}
			Continue
		}
		
		; Ignore stuff that's in a private or debug scope.
		if(line = privateScopeStart || line = debugScopeStart) {
			outOfScope := true
		}
		if(outOfScope) {
			if(line = publicScopeStart || line = allScopeEnd)
				outOfScope := false
			else
				Continue
		}
		
		if(line = docSeparator) {
			docLines.push(line)
			inBlock := true
			Continue
		}
		
		; Class declaration - anything below this should start with "<className>."
		if(line.startsWith("class ") && line.endsWith(" {") && line != "class {") {
			; If there was a class open before, add a closing comment for it.
			if(currClassName != "") {
				; Save off all functions in this class to class object
				if(!DataLib.isNullOrEmpty(classFunctions)) { ; Only add to allXML if we actually have documented functions to include
					classInfos[currClassName] := classFunctions
				}
				
				classFunctions := {}
			}
			
			; Get new class name
			currClassName := line.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
			currParentClassName := ""
			if(line.contains(" extends "))
				currParentClassName := line.firstBetweenStrings(" extends ", " {")
		}
	}
	
	; If there was a class open at the end, finish it off.
	if(currClassName != "") {
		; Save off all functions in this class to class object
		if(!DataLib.isNullOrEmpty(classFunctions)) { ; Only add to allXML if we actually have documented functions to include
			classInfos[currClassName] := classFunctions
			; Debug.popup("currClassName2",currClassName)
		}
		
		classFunctions := {}
	}
	
	; Get new class name
	currClassName := line.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
	
	; ; Add an XML comment to say we're starting a block
	; startBlockComment := startBlockCommentBaseXML.replaceTag("CLASS_NAME", currClassName)
	; classXML .= startBlockComment
	
	; Debug.popup("classInfos",classInfos)
	
	return classInfos
	
	
}

getNameFromDefLine(defLine) {
	defLine := defLine.beforeString("(") ; If it's a function, stop at the open paren.
	defLine := defLine.beforeString("[") ; If it's a property with parameters, stop at the open bracket.
	defLine := defLine.beforeString(" ").beforeString(":") ; If it's a variable, drop any assignment or anything else that comes after the name.
	return defLine ; If it's a property without parameters (or one of the above left only the name) then the whole thing is the name.
}

getParamsListFromDefinitionLine(definitionLine) {
	; Function
	if(definitionLine.contains("("))
		return definitionLine.firstBetweenStrings("(", ")")
	
	; Property with brackets
	if(definitionLine.contains("["))
		return definitionLine.firstBetweenStrings("[", "]")
	
	return ""
}
splitVarList(varList) {
	QUOTE := """" ; Double-quote character
	paramsAry := []
	
	currentName := ""
	openParens := 0
	openQuotes := 0
	Loop, Parse, varList
	{
		char := A_LoopField
		
		; Track open parens/quotes.
		if(char = "(")
			openParens++
		if(char = ")")
			openParens--
		if(char = QUOTE)
			openQuotes := mod(openQuotes + 1, 2) ; Quotes close other quotes, so just swap between open and closed
		
		; Split on commas, but only if there are no open parens or quotes.
		if(char = "," && openParens = 0 && openQuotes = 0) {
			paramsAry.push(currentName.withoutWhitespace())
			currentName := ""
			Continue
		}
		
		currentName .= char
	}
	paramsAry.push(currentName.withoutWhitespace())
	
	return paramsAry
}