#Include ahkDocBlock.ahk
class VSCode {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    How many characters wide a tab is in VS Code.
	;---------
	static TabWidth := 4 ; GDB TODO probably switch many things over to use this
	
	
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    For program scripts, swap between the program script and its matching class script.
	;---------
	toggleProgramAndClass() {
		currScriptPath := WinGetActiveTitle().beforeString(this.windowTitleSeparator)
		SplitPath(currScriptPath, scriptName)
		
		if(currScriptPath.startsWith(Config.path["AHK_SOURCE"] "\program\"))
			matchingScriptPath := Config.path["AHK_SOURCE"] "\common\program\" scriptName
		else if(currScriptPath.startsWith(Config.path["AHK_SOURCE"] "\common\program\"))
			matchingScriptPath := Config.path["AHK_SOURCE"] "\program\" scriptName
		
		if(FileExist(matchingScriptPath))
			Config.runProgram("VSCode", matchingScriptPath)
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

	
	; #PRIVATE#
	static windowTitleSeparator := " - " ; Separator (window.titleSeparator) between elements of the window title (window.title)
	; #END#
}
