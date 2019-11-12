#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

allXML := ""

commonRoot := Config.path["AHK_ROOT"] "\source\common"

; clipboard := getAutoCompleteXMLForScript(commonRoot "\class\selector.ahk")
; clipboard := getAutoCompleteXMLForScript(commonRoot "\static\debug.ahk")
clipboard := getAutoCompleteXMLForScript(commonRoot "\lib\clipboardLib.ahk")

; allXML .= getAutoCompleteXMLForFolder(commonRoot "\base")
; allXML .= getAutoCompleteXMLForFolder(commonRoot "\class")
; allXML .= getAutoCompleteXMLForFolder(commonRoot "\external")
; allXML .= getAutoCompleteXMLForFolder(commonRoot "\lib")
; allXML .= getAutoCompleteXMLForFolder(commonRoot "\static")
; clipboard := allXML

MsgBox, done

ExitApp

getAutoCompleteXMLForFolder(path) {
	Loop, Files, %path%\*.ahk, RF ; Recursive, files (not directories)
	{
		allXML .= getAutoCompleteXMLForScript(A_LoopFileLongPath)
	}
	
	return allXML
}

getAutoCompleteXMLForScript(path) {
	docSeparator := ";---------"
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
            <Overload retVal="""" descr=""<DESCRIPTION>""><PARAMS>
            </Overload>
        </KeyWord>
		)" ; retVal attribute seems required for auto-completion to work correctly, <PARAMS> has no indent so each line of the params can indent itself the same.
	paramBaseXML := "
		(
                <Param name=""<PARAM>"" />
		)"
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
	
	allXML := ""
	classXML := ""
	currClassName := ""
	
	classFunctionXMLs := {} ; {functionName: keywordXML}
	
	For lineNumber,line in linesAry {
		line := line.withoutWhitespace()
		
		; Finishing a block - grab the name from the next line (which should be a definition line) and store everything off.
		if(inBlock) {
			if(line = docSeparator) {
				docLines.push(line)
				
				defLine := linesAry[lineNumber + 1]
				defLine := defLine.withoutWhitespace().beforeString(" {")
				name := getNameFromDefLine(defLine)
				params := NotepadPlusPlus.getParamsListFromDefinitionLine(defLine)
				
				if(currClassName != "") {
					if(name = "__New")
						name := currClassName
					else
						name := currClassName "." name
				}
				
				isFunc := "yes" ; or "no" ; GDB TODO
				
				headerIndent := StringLib.getTabs(7) ; We can indent with tabs and it's ignored - cleaner XML and result looks the same.
				headerText := "`n" headerIndent docLines.join("`n" headerIndent) ; Add a newline at the start to separate the header from the definition line in the popup
				headerText := headerText.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
				
				
				
				
				allParamsXML := ""
				if(params != "") {
					For _,param in params.split(",", " `t") {
						param := param.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
						paramXML := paramBaseXML.replaceTag("PARAM", param)
						allParamsXML := allParamsXML.appendPiece(paramXML, "`n")
					}
					allParamsXML := "`n" allParamsXML ; Newline before the whole params block
				}
				
				keywordTags := {"NAME":name, "IS_FUNC":isFunc, "DESCRIPTION":headerText, "PARAMS":allParamsXML}
				keywordXML := keywordBaseXML.replaceTags(keywordTags)
				
				; Debug.popup("name",name, "description",description, "parameters",parameters, "returns",returns, "sideEffects",sideEffects, "notes",notes, "keywordXML",keywordXML)
				; Debug.popup(keywordXML)
				
				classFunctionXMLs[name] := keywordXML
				
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
		if(line.startsWith("class ") && line.endsWith(" {")) {
			; If there was a class open before, add a closing comment for it.
			if(currClassName != "") {
				; Save off all functions in this class to class XML
				For _,xml in classFunctionXMLs { ; Should be looping in alphabetical order
					classXML := classXML.appendPiece(xml, "`n")
				}
				
				endBlockComment := endBlockCommentBaseXML.replaceTag("CLASS_NAME", currClassName)
				classXML := classXML.appendPiece(endBlockComment, "`n")
				classXML .= "`n" ; Add an extra newline after finishing a block
				
				; Flush to allXML and clear the class
				allXML .= classXML
				classXML := ""
				classFunctionXMLs := {}
			}
			
			; Get new class name
			currClassName := line.removeFromStart("class ").removeFromEnd(" {")
			
			; Add an XML comment to say we're starting a block
			startBlockComment := startBlockCommentBaseXML.replaceTag("CLASS_NAME", currClassName)
			classXML .= "`n" startBlockComment ; Add an extra newline before a new block
		}
	}
	
	; If there was a class open at the end, finish it off.
	if(currClassName != "") {
		; Save off all functions in this class to class XML
		For _,xml in classFunctionXMLs { ; Should be looping in alphabetical order
			classXML := classXML.appendPiece(xml, "`n")
		}
		
		endBlockComment := endBlockCommentBaseXML.replaceTag("CLASS_NAME", currClassName)
		classXML := classXML.appendPiece(endBlockComment, "`n")
		classXML .= "`n" ; Add an extra newline after finishing a block
		
		; Flush to allXML and clear the class
		allXML .= classXML
		classXML := ""
		classFunctionXMLs := {}
	}
	
	return allXML
}

getNameFromDefLine(defLine) {
	defLine := defLine.beforeString("(") ; If it's a function, stop at the open paren.
	defLine := defLine.beforeString("[") ; If it's a property with parameters, stop at the open bracket.
	return defLine ; If it's a property without parameters (or one of the above left only the name) then the whole thing is the name.
}