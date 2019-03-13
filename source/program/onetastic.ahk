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
	^+x::
		onetasticOpenEditXMLPopup()
		
		clipboard := "" ; Clear the clipboard so we can tell when we have the new XML on it
		Send, ^c
		ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain the XML
		
		if(clipboard != "") {
			Toast.showMedium("Copied macro function XML")
		} else {
			Toast.showMedium("Failed to copy macro function XML")
			return
		}
		
		Send, !o ; Close the popup
	return
	
	; "Import" a full function from clipboard XML
	^+i::
		onetasticImportFunction() {
			functionXML := clipboard
			
			if(!functionXML) {
				Toast.showMedium("Cannot import: clipboard is blank.")
				return
			}
			
			; First line should be a comment with the exact function signature
			functionSignature := getFirstStringBetweenStr(functionXML, "<Comment text=""", """ />")
			
			; Add function signature 
			Send, ^{NumpadAdd} ; New macro
			WinWaitActive, Function Signature Editor
			sendTextWithClipboard(functionSignature)
			
			; Validate we were able to enter the right thing
			if(!onetasticFunctionSignatureIsCorrect(functionSignature)) {
				Sleep, 500
				sendTextWithClipboard(functionSignature) ; If we put in the wrong thing, try once more
			}
			if(!onetasticFunctionSignatureIsCorrect(functionSignature)) {
				Toast.showMedium("Could not import macro function: failed to insert function signature")
				return
			}
			
			; Accept out of the signature window to finish creating function
			Send, !o
			waitUntilWindowState("Active", " - Macro Editor", "", 2) ; Allow matching anywhere
			
			onetasticOpenEditXMLPopup()
			Send, ^v ; Paste full XML into window
			Send, !o ; OK out of window
		}
		
		
		oneTasticImportAllMacroDependencies() {
			macroName := "createPageAndLink_SpecificSection" ; GDB TODO figure out how to pick/figure out macro name (maybe put it in the macro's XML as the first comment?)
			masterDependenciesAry := onetasticGetAllMacroDependencies(macroName)
			DEBUG.popup("macroName",macroName, "masterDependenciesAry",masterDependenciesAry)
			
		}

		onetasticGetAllMacroDependencies(macroName) {
			if(macroName = "")
				return []
			
			macrosFolderPath := "C:\Users\gborg\OneTasticMacros"
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
			
			; Macro -> array of functionNames
			SetWorkingDir, % macrosFolderPath
			macroXML := FileRead(macroName ".xml")
			macroDependenciesAry := onetasticGetDependenciesFromXML(macroXML)
			; DEBUG.popup("macroXML",macroXML, "macroDependenciesAry",macroDependenciesAry)
			
			SetWorkingDir, % origWorkingDir
			
			; Function to get in-order array of all dependencies
				; Start with empty array
				; Function XML (from array) -> list of dependencies FOR this function
					; Add each function, then recurse (depth-first) and append recursive result to array before going to the next function
						; Appending - probably a new function in data.ahk
						; Don't worry about duplicates at this point, we'll filter them out at the end
			totalDependenciesAry := []
			For _,functionName in macroDependenciesAry {
				functionDependenciesAry := onetasticCompileDependenciesForFunction(functionName, functionsXMLAry, masterDependenciesAry)
				totalDependenciesAry := arrayAppend(totalDependenciesAry, functionDependenciesAry)
			}
			; DEBUG.popup("totalDependenciesAry",totalDependenciesAry)
			
			; Remove duplicates (probably new function in data.ahk)
			totalDependenciesAry := arrayDropDuplicates(totalDependenciesAry)
			; DEBUG.popup("totalDependenciesAry deduplicated",totalDependenciesAry)
			
			return totalDependenciesAry
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
			{
				functionName := A_LoopField
				
				; Ignore empty lines
				if(functionName = "")
					Continue
				
				dependenciesAry.push(functionName)
			}
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
		
	onetasticFunctionSignatureIsCorrect(correctSignature) {
		Send, {Home}{Shift Down}{End}{Shift Up} ; Select all (window doesn't support it natively)
		actualSignature := getSelectedText()
		return (actualSignature = correctSignature)
	}
	
	onetasticOpenEditXMLPopup() {
		Send, !u ; Function
		Send, x  ; Edit XML
		WinWaitActive, Edit XML
	}
#If
