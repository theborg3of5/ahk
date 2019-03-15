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
	
	;---------
	; DESCRIPTION:    Open the XML popup for the current macro or function.        
	;---------
	onetasticOpenEditXMLPopup() {
		Send, !u ; Function
		Send, x  ; Edit XML
		WinWaitActive, Edit XML
	}
	
	;---------
	; DESCRIPTION:    Copy the XML for the current macro or function.
	;---------
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
	
	;---------
	; DESCRIPTION:    Given the XML of a macro/function, generate an array of the XMLs of all
	;                 dependencies in a depth-first order.
	; PARAMETERS:
	;  startXML (I,REQ) - The XML of the macro or function to start from.
	; RETURNS:        Array of XML for all dependencies. Format:
	;                   totalDependenciesAry := [dependency1XML, dependency2XML, ...]
	;---------
	onetasticGetAllDependencyXMLs(startXML) {
		if(startXML = "")
			return []
		
		; Read all functions' XML and corresponding dependencies into function-name-indexed arrays
		origWorkingDir := A_WorkingDir
		SetWorkingDir, % MainConfig.getPath("ONETASTIC_FUNCTIONS")
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
			allDependenciesAry[functionName] := onetasticGetDependenciesFromXML(functionXML)
		}
		SetWorkingDir, % origWorkingDir
		; DEBUG.popup("allDependenciesAry",allDependenciesAry, "functionsXMLAry",functionsXMLAry)
		
		; Starting XML -> array of initial dependencies
		startDependenciesAry := onetasticGetDependenciesFromXML(startXML)
		; DEBUG.popup("startXML",startXML, "startDependenciesAry",startDependenciesAry)
		
		; Generate an array of the total dependencies in depth-first order
		totalDependenciesAry := []
		For _,functionName in startDependenciesAry {
			functionDependenciesAry := onetasticCompileDependenciesForFunction(functionName, functionsXMLAry, allDependenciesAry)
			totalDependenciesAry := arrayAppend(totalDependenciesAry, functionDependenciesAry)
		}
		; DEBUG.popup("totalDependenciesAry",totalDependenciesAry, "arrayDropDuplicates(totalDependenciesAry)",arrayDropDuplicates(totalDependenciesAry))
		totalDependenciesAry := arrayDropDuplicates(totalDependenciesAry) ; Remove duplicates as we can't import functions more than once
		
		; Generate array of XMLs in same order
		totalDependencyXMLsAry := []
		For _,dependencyName in totalDependenciesAry
			totalDependencyXMLsAry.push(functionsXMLAry[dependencyName])
		
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
	onetasticCompileDependenciesForFunction(functionName, functionsXMLAry, allDependenciesAry) {
		outAry := [functionName]
		if(functionName = "")
			return outAry
		
		For _,dependencyName in allDependenciesAry[functionName] {
			subDependenciesAry := onetasticCompileDependenciesForFunction(dependencyName, functionsXMLAry, allDependenciesAry)
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
	onetasticImportFunction(functionXML) {
		if(!functionXML) {
			Toast.showMedium("Cannot import: no function XML found")
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
