#Include ahkDocBlock.ahk
class VSCode {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    How many characters wide a tab is in VS Code.
	;---------
	static TabWidth := 4 ; GDB TODO probably switch many things over to use this

	
	; #INTERNAL#
	
	; ;--------- ; GDB TODO
	; ; DESCRIPTION:    Open the current file's parent folder in Explorer.
	; ; NOTES:          We have to do this instead of using the native option, because the native
	; ;                 option doesn't open it correctly (it opens a new window instead of adding a
	; ;                 tab to QTTabBar).
	; ;---------
	; openCurrentParentFolder() {
	; 	filePath := ClipboardLib.getWithHotkey("!c")
	; 	if(!filePath) {
	; 		Toast.ShowError("Could not open parent folder", "Failed to retrieve current file path")
	; 		return
	; 	}
		
	; 	filePath := FileLib.cleanupPath(filePath)
	; 	parentFolder := FileLib.getParentFolder(filePath)
		
	; 	if(!FileLib.folderExists(parentFolder)) {
	; 		Toast.ShowError("Could not open parent folder", "Folder does not exist: " parentFolder)
	; 		return
	; 	}
		
	; 	Run(parentFolder)
	; }
	
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
	
	; ;--------- ; GDB TODO
	; ; DESCRIPTION:    Send a code string for defaulting a variable to a different value if it's false/blank.
	; ; PARAMETERS:
	; ;  varName (I,OPT) - The name of the variable to work with. If not given, we'll prompt the user for it.
	; ; SIDE EFFECTS:   Prompts the user for the default value.
	; ;---------
	; sendDefaultingCodeString(varName := "") {
	; 	varAndDefault := InputBox("Enter variable and default value (comma-separated)", , , 500, 100, , , , , varName ", ")
	; 	if(varAndDefault = "")
	; 		return
		
	; 	varName      := varAndDefault.beforeString(",")
	; 	defaultValue := varAndDefault.afterString(",").withoutWhitespace() ; Drop any leading space
		
	; 	SendRaw, % varName " := " varName " ? " varName " : " defaultValue
	; }
	
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
	
	; ;--------- ; GDB TODO
	; ; DESCRIPTION:    Get the indentation from the current line (as the whitespace it is, not a count).
	; ; RETURNS:        The whitespace that makes up the indentation.
	; ; SIDE EFFECTS:   Ends up at the end of the current line, not where we started.
	; ;---------
	; getCurrentLineIndent() {
	; 	Send, {Home}{Shift Down}{Home}{Shift Up} ; Start selecting at the start of the line to get the indentation
	; 	indent := SelectLib.getText()
	; 	Sleep, 100 ; Make sure Ctrl is up so we don't end up jumping to the end of the file.
	; 	Send, {End} ; Get back to the end of the line
		
	; 	return indent
	; }
	; #END#
}
