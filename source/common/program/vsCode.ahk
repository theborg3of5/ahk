#Include headerDocBlock.ahk
class VSCode {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    How many characters wide a tab is in VSCode.
	;---------
	static TabWidth := 4

	;---------
	; DESCRIPTION:    Edit an AHK-related file in the proper VSCode profile.
	; PARAMETERS:
	;  path (I,REQ) - Full path to the file to edit (can also include any other params you want to send).
	;---------
	editScript(path) {
		; --wait: so that if we're opening VSCode exclusively to edit this, it closes on its own once the file is closed.
		Config.runProgram("VSCode", "--wait --profile AHK " path)
	}

	;---------
	; DESCRIPTION:    Open the DLG found in the active window's title in EpicCode.
	;---------
	openCurrentDLG() {
		record := EpicLib.getBestEMC2RecordFromText(WinGetActiveTitle())
		if(record.ini != "DLG" || record.id = "") {
			Toast.ShowError("Could not open DLG in EpicCode", "Record ID was blank or was not a DLG ID")
			return
		}
		
		this.openDLG(record.id)
	}

	;---------
	; DESCRIPTION:    Open the given DLG in EpicCode.
	; PARAMETERS:
	;  dlgId (I,REQ) - DLG ID
	;---------
	openDLG(dlgId) {
		if(!dlgId) {
			Toast.ShowError("Could not open DLG in EpicCode", "DLG ID was blank")
			return
		}

		t := new Toast("Opening DLG in EpicCode: " dlgId).show()
		
		new ActionObjectEpicCode(dlgId, ActionObjectEpicCode.DescriptorType_DLG).openEdit()
		
		t.close()
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ INTERNAL ------------------------------
	static Hotkey_CopyCurrentFile := "!+c" ; Built-in hotkey for copyFilePath command
	
	;---------
	; DESCRIPTION:    For program scripts, swap between the program script and its matching class script.
	;---------
	toggleProgramAndClass() {
		currScriptPath := ClipboardLib.getWithHotkey(VSCode.Hotkey_CopyCurrentFile)
		if(!currScriptPath) {
			Toast.showError("Could not get code location", "Failed to get current path")
			return
		}
		
		SplitPath(currScriptPath, scriptName)
		if(currScriptPath.startsWith(Config.path["AHK_SOURCE"] "\program\"))
			matchingScriptPath := Config.path["AHK_SOURCE"] "\common\program\" scriptName
		else if(currScriptPath.startsWith(Config.path["AHK_SOURCE"] "\common\program\"))
			matchingScriptPath := Config.path["AHK_SOURCE"] "\program\" scriptName
		
		if(FileExist(matchingScriptPath))
			this.editScript(matchingScriptPath)
	}
	
	;---------
	; DESCRIPTION:    Send a debug code string using the given function name, prompting the user for
	;                 the list of parameters to use (in "varName",varName parameter pairs).
	; PARAMETERS:
	;  functionName   (I,REQ) - Name of the function to send before the parameters.
	;  defaultVarList (I,OPT) - Var list to default into the popup.
	;---------
	sendAHKDebugCodeString(functionName, defaultVarList := "") {
		if(functionName = "")
			return
		
		varList := InputBox("Enter variables to send debug string for", , , 500, 100, , , , , defaultVarList)
		if(ErrorLevel) ; Popup was cancelled or timed out
			return
		
		if(varList = "") {
			ClipboardLib.send(functionName "()")
			Send, {Left} ; Get inside parens for user to enter the variables/labels themselves
		} else {
			ClipboardLib.send(functionName "(" AHKCodeLib.generateDebugParams(varList) ")")
		}
	}
	
	;---------
	; DESCRIPTION:    Take an existing debug line and let the user edit and replace the parameters.
	;---------
	editDebugLine() {
		Send, {End 2} ; Get to end, even if it's a wrapped line
		Send, {Shift Down}
		Send, {Home 2} ; Get to the start, even if it's a wrapped line (may also select indent)
		Send, {Shift Up}
		debugLine := SelectLib.getText()
		
		; We don't want indentation, so if we got it, deselect it.
		if(debugLine.startsWith("`t")) {
			Send, {Shift Down}{Home}{Shift Up} ; Jumps to end of indentation
			debugLine := debugLine.withoutWhitespace()
		}
		
		functionName := debugLine.beforeString("(")
		if(!functionName.startsWith("Debug.")) { ; Don't edit non-debug lines
			Send, {Right} ; Deselect line
			return
		}
		
		paramsString := debugLine.allBetweenStrings("(", ")")
		reducedParams := AHKCodeLib.reduceDebugParams(paramsString)
		this.sendAHKDebugCodeString(functionName, reducedParams)
	}
	
	;---------
	; DESCRIPTION:    Insert an AHK function header based on the function defined on the line below
	;                 the cursor.
	; SIDE EFFECTS:   Selects the line below in order to process the parameters.
	;---------
	sendDocHeader() {
		; Select the following line after this one to get parameter information
		Send, {Down}
		SelectLib.selectCurrentLine()
		
		defLine := SelectLib.getText().clean()
		Send, {Up}
		
		SendRaw, % AHKCodeLib.generateDocHeader(defLine)
	}
	
	;---------
	; DESCRIPTION:    Put the current location in code (tag^routine) onto the clipboard, stripping
	;                 off any offset ("+4" in "tag+4^routine") and the RTF link that EpicStudio adds.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	copyCleanEpicCodeLocation() {
		codeLocation := ClipboardLib.getWithHotkey(VSCode.Hotkey_CopyCurrentFile)
		
		; Initial value copied potentially has the offset (tag+<offsetNum>) included, strip it off.
		codeLocation := EpicLib.dropOffsetFromServerLocation(codeLocation)
		
		; If we got "routine^routine", just return "^routine".
		tag     := codeLocation.beforeString("^")
		routine := codeLocation.afterString("^")
		if(tag = routine)
			codeLocation := codeLocation.removeFromStart(tag)
		
		; Set the clipboard value to our new (plain-text, no link) code location and notify the user.
		ClipboardLib.setAndToast(codeLocation, "cleaned code location")
	}
	
	;---------
	; DESCRIPTION:    Put the current routine onto the clipboard.
	; SIDE EFFECTS:   Shows a toast letting the user know what we put on the clipboard.
	;---------
	copyEpicRoutineName() {
		codeLocation := ClipboardLib.getWithHotkey(VSCode.Hotkey_CopyCurrentFile)
		
		; Split off the routine
		EpicLib.splitServerLocation(codeLocation, routine)
		
		; Set the clipboard value to the routine
		ClipboardLib.setAndToast("^" routine, "routine name")
	}
	;endregion ------------------------------ INTERNAL ------------------------------
}
