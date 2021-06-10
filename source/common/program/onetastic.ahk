class Onetastic {
	; #INTERNAL#
	
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
		Onetastic.openEditXMLPopup()
		xml := ControlGetText("Edit1", "A")
		
		ClipboardLib.set(xml) ; Can't use ClipboardLib.setAndToast() because we don't want to show all of the XML
		if(Clipboard = "")
			new ErrorToast("Failed to get XML").showMedium()
		else
			new Toast("Clipboard set to new XML").showMedium()
		
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
		
		Onetastic.openEditXMLPopup()
		ControlSetText, Edit1, % newXML, A
		Send, {Space} ; Parsed value doesn't update unless we actually change something (setting the field doesn't count), so add a space (which is ignored by the parser).
		Send, !o ; OK out of window
		
		; Wait for window to close fully
		Onetastic.waitMacroEditorWindowActive()
	}

	;---------
	; DESCRIPTION:    "Refresh" a macro and all of its functions to match the given XML and its
	;                 recursive dependencies from .xml files.
	; PARAMETERS:
	;  macroXML (I,REQ) - New XML for the macro.
	;---------
	refreshMacroFromXML(macroXML) {
		if(!macroXML) {
			new ErrorToast("Could not import dependencies", "No macro XML given.").showMedium()
			return
		}
		
		if(!GuiLib.showConfirmationPopup("Are you sure you want to overwrite this macro and its functions?", "Update macro from XML"))
			return
		
		; Update the macro XML
		Control, Choose, 1, ComboBox1, A ; Switch to Main() - always the first item
		Onetastic.setCurrentXML(macroXML)
		
		; Delete all existing functions, we'll be "importing" them from scratch.
		Onetastic.deleteAllUserFunctions()
		
		; Import all needed dependencies.
		dependencyXMLsAry := Onetastic.getAllDependencyXMLs(macroXML)
		For _,functionXML in dependencyXMLsAry
			Onetastic.importFunction(functionXML)
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Delete all user-created functions in the macro (everything except Main()).
	;---------
	deleteAllUserFunctions() {
		; Find out how many functions there are, then focus the last one (deletion moves to the previous function).
		functionList := ControlGet("List", "", "ComboBox1", "A")
		functionCount := functionList.countMatches("`n") ; Counting the `ns gives us the number of lines - 1, which is the number of functions excluding Main().
		; Debug.toast("functionCount",functionCount, "functionList",functionList)
		
		Control, Choose, % functionCount + 1, ComboBox1, A ; +1 to account for Main()
		Loop {
			; Finished when we reach Main().
			if(Onetastic.isMainFunctionOpen())
				Break
			
			; Safety check so we can't infinitely loop.
			counter++
			if(counter > functionCount)
				Break
			
			Onetastic.deleteCurrentFunction(true)
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
		
		; Read in info about all functions
		allFunctionData := Onetastic.getFunctionDataFromFiles()
		
		; Start with dependencies directly listed in start XML
		startDependenciesAry := Onetastic.getDependenciesFromXML(startXML)
		; Debug.popup("startXML",startXML, "startDependenciesAry",startDependenciesAry)
		
		; Generate an array of the total dependencies in depth-first order
		totalDependenciesAry := []
		For _,functionName in startDependenciesAry {
			functionDependenciesAry := Onetastic.compileDependenciesForFunction(functionName, allFunctionData["DEPENDENCIES"])
			totalDependenciesAry.appendArray(functionDependenciesAry)
		}
		totalDependenciesAry.removeDuplicates() ; Remove duplicates as we can't import functions more than once
		
		; Generate final array of XMLs in same order
		totalXMLsAry := []
		For _,dependencyName in totalDependenciesAry
			totalXMLsAry.push(allFunctionData["XML", dependencyName])
		
		; Debug.toast("totalXMLsAry",totalXMLsAry)
		return totalXMLsAry
	}
	
	;---------
	; DESCRIPTION:    Read all functions' XML and dependencies from files into an associative array.
	; RETURNS:        Array of function data. Format:
	;                    data["DEPENDENCIES", functionName] := [dependencyFunctionName1, ...]
	;                    data["XML",          functionName] := function XML
	;---------
	getFunctionDataFromFiles() {
		allFunctionData := {} ; {"DEPENDENCIES":{functionName: [dependencyNames]}, "XML":{functionName: xml}}
		
		settings := new TempSettings().workingDirectory(Config.path["ONETASTIC_FUNCTIONS"])
		Loop, Files, % "*.xml"
		{
			; Skip files that start with . (like function template)
			if(A_LoopFileName.startsWith("."))
				Continue
			
			xml := FileRead(A_LoopFileName)
			name := xml.firstBetweenStrings("<Comment text=""", "(") ; Function signature is in first comment line, i.e. <Comment text="addWideOutlineToPage($page)" />
			if(!name)
				Continue
			
			allFunctionData["DEPENDENCIES", name] := Onetastic.getDependenciesFromXML(xml)
			allFunctionData["XML",          name] := xml
		}
		settings.restore()
		
		; Debug.popup("allFunctionData",allFunctionData)
		return allFunctionData
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
	; RETURNS:        Array of dependency (function) names.
	;---------
	getDependenciesFromXML(xml) {
		dependenciesStart := "<Comment text=""DEPENDENCIES"" />" ; <Comment text="DEPENDENCIES" />
		dependenciesEnd   := "<Comment text="""" />"             ; <Comment text="" /> (empty comment is ending edge)
		
		if(!xml.contains(dependenciesStart))
			return []
		
		dependencyListXML := xml.firstBetweenStrings(dependenciesStart, dependenciesEnd)
		; Debug.popup("xml",xml, "dependencyListXML",dependencyListXML)
		
		bitsToDropRegex := "<Comment text="" |"" />" ; <Comment text=" |" />
		dependencyList := dependencyListXML.removeRegEx(bitsToDropRegex)
		
		dependenciesAry := []
		Loop, Parse, dependencyList, `r`n ; This technically breaks on every `r OR `n, but this should be fine since we're ignoring empty strings.
			if(A_LoopField != "") ; Ignore empty lines
				dependenciesAry.push(A_LoopField)
		; Debug.popup("dependencyList",dependencyList, "dependenciesAry",dependenciesAry)
		
		return dependenciesAry
	}

	;---------
	; DESCRIPTION:    Recursive function to generate an array of all dependencies for the given
	;                 function. The array is built in a depth-first manner, recursing through all
	;                 dependencies of each function.
	; PARAMETERS:
	;  functionName            (I,REQ) - Name of the function to generate a total dependency array for.
	;  allFunctionDependencies (I,REQ) - Associative array of dependencies for each function. Format:
	;                                       allFunctionDependencies[functionName] := [dependencyName1, dependencyName2, ...]
	; RETURNS:        Array of all dependencies required by the given function, in depth-first order.
	; NOTES:          There's no checking for duplicates as we generate the array.
	;---------
	compileDependenciesForFunction(functionName, allFunctionDependencies) {
		outAry := [functionName]
		if(functionName = "")
			return outAry
		
		For _,dependencyName in allFunctionDependencies[functionName] {
			subDependenciesAry := Onetastic.compileDependenciesForFunction(dependencyName, allFunctionDependencies)
			outAry.appendArray(subDependenciesAry)
			; Debug.popup("functionName",functionName, "dependencyName",dependencyName, "subDependenciesAry",subDependenciesAry, "outAry",outAry)
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
			new ErrorToast("Cannot import", "No function XML found").showMedium()
			return
		}
		
		; First line should be a comment with the exact function signature
		functionSignature := functionXML.firstBetweenStrings("<Comment text=""", """ />")
		
		; Add function signature
		Send, ^{NumpadAdd} ; New function
		WinWaitActive, Function Signature Editor
		ControlSetText, Edit1, % functionSignature, A
		Send, {Space} ; Parsed value doesn't update unless we actually change something (setting the field doesn't count), so add a space (which is ignored by the parser).
		Send, !o ; OK out of window
		
		; Wait to get back to main macro editor window
		Onetastic.waitMacroEditorWindowActive()
		
		; Replace any instances of the special <CURRENT_MACHINE> tag with the AHK value for our current machine.
		functionXML := functionXML.replaceTag("CURRENT_MACHINE", Config.machine)
		
		Onetastic.setCurrentXML(functionXML)
	}

	;---------
	; DESCRIPTION:    Waits until the main macro editor window becomes active.
	;---------
	waitMacroEditorWindowActive() {
		settings := new TempSettings().titleMatchMode(TitleMatchMode.Contains)
		WinWaitActive, % " - Macro Editor"
		settings.restore()
	}
	; #END#
}
