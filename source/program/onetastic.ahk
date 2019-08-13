#If MainConfig.isWindowActive("OneTastic Macro Editor")
	; Insert statement hotkeys
	^`;::!6 ; Insert comment 
	
	; Move line up/down
	!Up::  Send, ^{Up}
	!Down::Send, ^{Down}
	
	; Collapse/expand
	!Left:: Send, ^{Left}
	!Right::Send, ^{Right}
	
	; New macro function
	^n::^NumpadAdd
	
	; Open macro info window
	^i::
		Send, !f ; File
		Send, i  ; Edit Macro Info...
	return
	
	; Open function header edit window
	^e::^F2
	
	; Delete current function
	^d::OneTastic.deleteCurrentFunction()
	
	; Open XML window
	^+o::OneTastic.openEditXMLPopup()
	
	; Copy/set current function XML
	^+x::OneTastic.copyCurrentXML()
	^+s::OneTastic.setCurrentXML(clipboard)
	
	; Update the current macro using the XML on the clipboard.
	^!i::OneTastic.refreshMacroFromXML(clipboard)
#If	

class OneTastic {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Delete the currently visible function.
	;---------
	deleteCurrentFunction(autoConfirm := false) {
		Send, !u ; Function
		Send, d  ; Delete Function
		
		if(autoConfirm) {
			WinWaitActive, Delete Function ahk_class Onetastic Window
			Send, y ; Yes
		}
	}

	;---------
	; DESCRIPTION:    Open the XML popup for the current macro or function.        
	;---------
	openEditXMLPopup() {
		Send, !u ; Function
		Send, x  ; Edit XML
		WinWaitActive, Edit XML
	}

	;---------
	; DESCRIPTION:    Copy the XML for the current macro or function.
	;---------
	copyCurrentXML() {
		OneTastic.openEditXMLPopup()
		xml := ControlGetText("Edit1", "A")
		
		setClipboardAndToastState(xml, "XML")
		if(xml)
			Send, {Esc} ; Close the popup
	}

	;---------
	; DESCRIPTION:    Sets the XML for the current function to the given value.
	; PARAMETERS:
	;  newXML (I,REQ) - The new XML for the current function.
	;---------
	setCurrentXML(newXML) {
		if(newXML = "")
			return
		
		OneTastic.openEditXMLPopup()
		ControlSetText, Edit1, % newXML, A
		Send, {Space} ; Parsed value doesn't update unless we actually change something (setting the field doesn't count), so add a space (which is ignored by the parser).
		Send, !o ; OK out of window
		
		; Wait for window to close fully
		OneTastic.waitMacroEditorWindowActive()
	}

	;---------
	; DESCRIPTION:    "Refresh" a macro and all of its functions to match the given XML and its
	;                 recursive dependencies from .xml files.
	; PARAMETERS:
	;  macroXML (I,REQ) - New XML for the macro.
	;---------
	refreshMacroFromXML(macroXML) {
		if(!macroXML) {
			Toast.showError("Could not import dependencies", "No macro XML given.")
			return
		}
		
		if(!showConfirmationPopup("Are you sure you want to overwrite this macro and its functions?", "Update macro from XML"))
			return
		
		; Update the macro XML
		Control, Choose, 1, ComboBox1, A ; Switch to Main() - always the first item
		OneTastic.setCurrentXML(macroXML)
		
		; Delete all existing functions, we'll be "importing" them from scratch.
		OneTastic.deleteAllUserFunctions()
		
		; Import all needed dependencies.
		masterDependencyXMLsAry := OneTastic.getAllDependencyXMLs(macroXML)
		For _,functionXML in masterDependencyXMLsAry
			OneTastic.importFunction(functionXML)
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Delete all user-created functions in the macro (everything except Main()).
	;---------
	deleteAllUserFunctions() {
		; Find out how many functions there are, then focus the last one (deletion moves to the previous function).
		functionList := ControlGet("List", "", "ComboBox1", "A")
		StringReplace, functionList, functionList, `n, `n, UseErrorLevel ; Counting the `ns gives us the number of lines - 1, which is the number of functions excluding Main().
		functionCount := ErrorLevel
		Control, Choose, % functionCount + 1, ComboBox1, A ; +1 to account for Main()
		; DEBUG.toast("functionCount",functionCount, "functionList",functionList)
		
		Loop {
			; Finished when we reach Main().
			if(OneTastic.isMainFunctionOpen())
				Break
			
			; Safety check so we can't infinitely loop.
			counter++
			if(counter > functionCount)
				Break
			
			OneTastic.deleteCurrentFunction(true)
		}
	}

	;---------
	; DESCRIPTION:    Determine whether we're on the Main() function (which is the execution root
	;                 and cannot be deleted) or not.
	; RETURNS:        True if the Main() function is the one currently open, False otherwise.
	;---------
	isMainFunctionOpen() {
		return (ControlGetText("ComboBox1", "A") = "Main()")
	}

	;---------
	; DESCRIPTION:    Given the XML of a macro/function, generate an array of the XMLs of all
	;                 dependencies in a depth-first order.
	; PARAMETERS:
	;  startXML (I,REQ) - The XML of the macro or function to start from.
	; RETURNS:        Array of XML for all dependencies. Format:
	;                   totalDependenciesAry := [dependency1XML, dependency2XML, ...]
	;---------
	getAllDependencyXMLs(startXML) {
		if(startXML = "")
			return []
		
		; Read all functions' XML and corresponding dependencies into function-name-indexed arrays
		origWorkingDir := A_WorkingDir
		SetWorkingDir, % MainConfig.path["ONETASTIC_FUNCTIONS"]
		functionsXMLAry    := []
		allDependenciesAry := []
		Loop, Files, % "*.xml"
		{
			; Skip files that start with . (like function template)
			if(stringStartsWith(A_LoopFileName, "."))
				Continue
			
			functionXML := FileRead(A_LoopFileName)
			functionName := getFirstStringBetweenStr(functionXML, "<Comment text=""", "(") ; Function signature is in first comment line, i.e. <Comment text="addWideOutlineToPage($page)" />
			if(!functionName)
				Continue
			
			functionsXMLAry[functionName]    := functionXML
			allDependenciesAry[functionName] := OneTastic.getDependenciesFromXML(functionXML)
		}
		SetWorkingDir, % origWorkingDir
		; DEBUG.popup("allDependenciesAry",allDependenciesAry, "functionsXMLAry",functionsXMLAry)
		
		; Starting XML -> array of initial dependencies
		startDependenciesAry := OneTastic.getDependenciesFromXML(startXML)
		; DEBUG.popup("startXML",startXML, "startDependenciesAry",startDependenciesAry)
		
		; Generate an array of the total dependencies in depth-first order
		totalDependenciesAry := []
		For _,functionName in startDependenciesAry {
			functionDependenciesAry := OneTastic.compileDependenciesForFunction(functionName, functionsXMLAry, allDependenciesAry)
			totalDependenciesAry := arrayAppend(totalDependenciesAry, functionDependenciesAry)
		}
		; DEBUG.popup("totalDependenciesAry",totalDependenciesAry)
		totalDependenciesAry.removeDuplicates() ; Remove duplicates as we can't import functions more than once
		; DEBUG.popup("Removed duplicates","", "totalDependenciesAry",totalDependenciesAry)
		
		; Generate array of XMLs in same order
		totalDependencyXMLsAry := []
		For _,dependencyName in totalDependenciesAry
			totalDependencyXMLsAry.push(functionsXMLAry[dependencyName])
		
		; DEBUG.toast("masterDependencyXMLsAry",masterDependencyXMLsAry)
		return totalDependencyXMLsAry
	}

	;---------
	; DESCRIPTION:    Read the given macro/function's XML and extract an array of its dependencies (user-defined functions which it calls) from the comments at the top.
	; PARAMETERS:
	;  xml (I,REQ) - XML for the given function. The list of dependencies for the function is expected to be in the following format:
	;                  <Comment text="DEPENDENCIES" />
	;                  <Comment text=" _FUNCTION_NAME_1" />
	;                  <Comment text=" _FUNCTION_NAME_2" />
	;                  <Comment text="" />
	;                Note the "DEPENDENCIES" start comment and the empty ending comment, and that functions should have a single space at the start.
	; RETURNS:        Array of dependency names. Format:
	;                  dependenciesAry[functionName] := [dependencyName1, dependencyName2, ...]
	;---------
	getDependenciesFromXML(xml) {
		dependenciesStart := "<Comment text=""DEPENDENCIES"" />" ; <Comment text="DEPENDENCIES" />
		dependenciesEnd   := "<Comment text="""" />"             ; <Comment text="" /> (empty comment is ending edge)
		
		if(!stringContains(xml, dependenciesStart))
			return []
		
		dependenciesXML := getFirstStringBetweenStr(xml, dependenciesStart, dependenciesEnd)
		; DEBUG.popup("xml",xml, "dependenciesXML",dependenciesXML)
		
		bitsToDropRegex := "<Comment text="" |"" />" ; <Comment text=" |" />
		dependencies := RegExReplace(dependenciesXML, bitsToDropRegex)
		
		dependenciesAry := []
		Loop, Parse, dependencies, `r`n ; This technically breaks on every `r OR `n, but this should be fine since we're ignoring empty strings.
			if(A_LoopField != "") ; Ignore empty lines
				dependenciesAry.push(A_LoopField)
		; DEBUG.popup("dependencies",dependencies, "dependenciesAry",dependenciesAry)
		
		return dependenciesAry
	}

	;---------
	; DESCRIPTION:    Recursive function to generate an array of all dependencies for the given
	;                 function. The array is built in a depth-first manner, recursing through all
	;                 dependencies of each function.
	; PARAMETERS:
	;  functionName       (I,REQ) - Name of the function to generate a total dependency array for.
	;  functionsXMLAry    (I,REQ) - Array of XML strings for all functions that we might find in our
	;                               recursive search. Format:
	;                                functionsXMLAry[functionName] := functionXML
	;  allDependenciesAry (I,REQ) - Array of dependencies for each function. Format:
	;                                allDependenciesAry[functionName] := [dependencyName1, dependencyName2, ...]
	; RETURNS:        Array of all dependencies required by the given function, in depth-first order.
	; NOTES:          There's no checking for duplicates as we generate the array.
	;---------
	compileDependenciesForFunction(functionName, functionsXMLAry, allDependenciesAry) {
		outAry := [functionName]
		if(functionName = "")
			return outAry
		
		For _,dependencyName in allDependenciesAry[functionName] {
			subDependenciesAry := OneTastic.compileDependenciesForFunction(dependencyName, functionsXMLAry, allDependenciesAry)
			outAry := arrayAppend(outAry, subDependenciesAry)
			; DEBUG.popup("functionName",functionName, "dependencyName",dependencyName, "subDependenciesAry",subDependenciesAry, "outAry",outAry)
		}
		
		return outAry
	}

	;---------
	; DESCRIPTION:    "Import" a single macro function using the given XML code.
	; PARAMETERS:
	;  functionXML (I,REQ) - XML for the function. Note that the first line must be a comment with
	;                        the full function signature in it.
	;---------
	importFunction(functionXML) {
		if(!functionXML) {
			Toast.showError("Cannot import", "No function XML found")
			return
		}
		
		; First line should be a comment with the exact function signature
		functionSignature := getFirstStringBetweenStr(functionXML, "<Comment text=""", """ />")
		
		; Add function signature
		Send, ^{NumpadAdd} ; New function
		WinWaitActive, Function Signature Editor
		ControlSetText, Edit2, % functionSignature, A
		Send, {Space} ; Parsed value doesn't update unless we actually change something (setting the field doesn't count), so add a space (which is ignored by the parser).
		Send, !o ; OK out of window
		
		; Wait to get back to main macro editor window
		OneTastic.waitMacroEditorWindowActive()
		
		; Replace any instances of the special <CURRENT_MACHINE> tag with the AHK value for our current machine.
		functionXML := replaceTag(functionXML, "CURRENT_MACHINE", MainConfig.machine)
		
		OneTastic.setCurrentXML(functionXML)
	}

	;---------
	; DESCRIPTION:    Waits until the main macro editor window becomes active.
	;---------
	waitMacroEditorWindowActive() {
		origMatchMode := setTitleMatchMode(TITLE_MATCH_MODE_Contain)
		WinWaitActive, % " - Macro Editor"
		setTitleMatchMode(origMatchMode)
	}
}
