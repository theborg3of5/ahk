#If MainConfig.isWindowActive("OneTastic Macro Editor")
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
	
	; Delete current macro
	^d::
		Send, !u ; Function
		Send, d  ; Delete Function
	return
	
	; Open XML window
	^+o::onetasticOpenEditXMLPopup()
	
	; Copy current function XML
	^+x::onetasticCopyXML()
	
	; "Import" all dependencies (recursively) based on the macro/function's listed dependencies
	^+i::
		onetasticImportAllDependencies() {
			; Get XML for the macro/function that's open
			onetasticCopyXML()
			
			masterDependencyXMLsAry := onetasticGetAllDependencyXMLs(clipboard)
			; DEBUG.popup("masterDependencyXMLsAry",masterDependencyXMLsAry)
			
			For _,functionXML in masterDependencyXMLsAry
				onetasticImportFunction(functionXML)
		}
		
	onetasticIsFunctionSignatureCorrect(correctSignature) {
		selectCurrentLine()
		actualSignature := getSelectedText()
		return (actualSignature = correctSignature)
	}
	
	onetasticOpenEditXMLPopup() {
		Send, !u ; Function
		Send, x  ; Edit XML
		WinWaitActive, Edit XML
	}
	
	onetasticCopyXML() {
		onetasticOpenEditXMLPopup()
		
		clipboard := "" ; Clear the clipboard so we can tell when we have the new XML on it
		Send, ^c
		ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain the XML
		
		if(clipboard != "") {
			Toast.showMedium("Copied XML")
		} else {
			Toast.showMedium("Failed to copy XML")
			return
		}
		
		Send, {Esc} ; Close the popup
	}
	
	onetasticIsFunctionXMLCorrect(correctXML) {
		WindowActions.selectAll()
		actualXML := getSelectedText()
		return (actualXML = correctXML)
	}
	
	onetasticGetAllDependencyXMLs(baseXML) {
		if(baseXML = "")
			return []
		
		
		functionsFolderPath := "C:\Users\gborg\OneTasticMacros\Functions"
		
		
		origWorkingDir := A_WorkingDir
		
		; Read all function files' XML into an array (all files in Functions\ folder): functionName => XML
			; Loop over all functions and populate a dependencies array: functionName => {requiredFunction1, requiredFunction2, ...}
		SetWorkingDir, % functionsFolderPath
		functionsXMLAry := []
		masterDependenciesAry := []
		Loop, Files, % "*.xml"
		{
			; Skip files that start with . (like template)
			if(stringStartsWith(A_LoopFileName, "."))
				Continue
			
			functionXML := FileRead(A_LoopFileName)
			functionName := getFirstStringBetweenStr(functionXML, "<Comment text=""", "(") ; Function signature is in first comment line, i.e. <Comment text="addWideOutlineToPage($page)" />
			if(!functionName)
				Continue
			
			functionsXMLAry[functionName] := functionXML
			masterDependenciesAry[functionName] := onetasticGetDependenciesFromXML(functionXML)
		}
		; DEBUG.popup("masterDependenciesAry",masterDependenciesAry, "functionsXMLAry",functionsXMLAry)
		
		; Base XML -> array of functionNames
		baseDependenciesAry := onetasticGetDependenciesFromXML(baseXML)
		; DEBUG.popup("baseXML",baseXML, "baseDependenciesAry",baseDependenciesAry)
		
		SetWorkingDir, % origWorkingDir
		
		; Function to get in-order array of all dependencies
			; Start with empty array
			; Function XML (from array) -> list of dependencies FOR this function
				; Add each function, then recurse (depth-first) and append recursive result to array before going to the next function
					; Appending - probably a new function in data.ahk
					; Don't worry about duplicates at this point, we'll filter them out at the end
		totalDependenciesAry := []
		For _,functionName in baseDependenciesAry {
			functionDependenciesAry := onetasticCompileDependenciesForFunction(functionName, functionsXMLAry, masterDependenciesAry)
			totalDependenciesAry := arrayAppend(totalDependenciesAry, functionDependenciesAry)
		}
		; DEBUG.popup("totalDependenciesAry",totalDependenciesAry)
		
		; Remove duplicates (probably new function in data.ahk)
		totalDependenciesAry := arrayDropDuplicates(totalDependenciesAry)
		; DEBUG.popup("totalDependenciesAry deduplicated",totalDependenciesAry)
		
		; Generate array of XMLs in same order
		totalDependencyXMLsAry := []
		For _,dependencyName in totalDependenciesAry
			totalDependencyXMLsAry.push(functionsXMLAry[dependencyName])
		
		return totalDependencyXMLsAry
	}

	onetasticGetDependenciesFromXML(xml) {
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

	; Add each function, then recurse (depth-first) and append recursive result to array before going to the next function
					; Appending - probably a new function in data.ahk
					; Don't worry about duplicates at this point, we'll filter them out at the end
	onetasticCompileDependenciesForFunction(functionName, functionsXMLAry, masterDependenciesAry) {
		outAry := [functionName]
		if(functionName = "")
			return outAry
		
		For _,dependencyName in masterDependenciesAry[functionName] {
			subDependenciesAry := onetasticCompileDependenciesForFunction(dependencyName, functionsXMLAry, masterDependenciesAry)
			outAry := arrayAppend(outAry, subDependenciesAry)
			; DEBUG.popup("functionName",functionName, "dependencyName",dependencyName, "subDependenciesAry",subDependenciesAry, "outAry",outAry)
		}
		
		return outAry
	}
	
	onetasticImportFunction(functionXML) {
		if(!functionXML) {
			Toast.showMedium("Cannot import: clipboard is blank.")
			return
		}
		
		; First line should be a comment with the exact function signature
		functionSignature := getFirstStringBetweenStr(functionXML, "<Comment text=""", """ />")
		
		; Add function signature 
		Send, ^{NumpadAdd} ; New function
		WinWaitActive, Function Signature Editor
		sendTextWithClipboard(functionSignature)
		
		; Validate we were able to enter the right thing
		if(!onetasticIsFunctionSignatureCorrect(functionSignature)) {
			Sleep, 500
			sendTextWithClipboard(functionSignature) ; If we put in the wrong thing, try once more
		}
		if(!onetasticIsFunctionSignatureCorrect(functionSignature)) {
			Toast.showMedium("Could not import function: failed to paste function signature")
			return
		}
		
		; Accept out of the signature window to finish creating function
		Send, !o
		waitUntilWindowState("Active", " - Macro Editor", "", 2) ; matchMode=2 - allow matching anywhere
		
		onetasticOpenEditXMLPopup()
		sendTextWithClipboard(functionXML)
		
		; Double-check that we got the right XML in place
		if(!onetasticIsFunctionXMLCorrect(functionXML)) {
			Sleep, 500
			sendTextWithClipboard(functionXML)
		}
		if(!onetasticIsFunctionXMLCorrect(functionXML)) {
			Toast.showMedium("Could not import function: failed to paste function XML")
			return
		}
		
		Send, !o ; OK out of window
	}
#If
