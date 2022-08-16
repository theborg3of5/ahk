class VisualStudio {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Copy the current full code location (filepath::function()) to the clipboard.
	;---------
	copyCodeLocationWithPath() {
		path := ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFile)
		if(path = "") {
			Toast.ShowError("Failed to copy full code location", "Failed to get current file path")
			return ""
		}
		path := FileLib.cleanupPath(path)
		
		; Function name will come from selected text
		functionName := SelectLib.getText()
		if(functionName != "" && !functionName.contains("`n")) ; If there's a newline then nothing was selected, we just copied the whole line.
			path .= "::" functionName "()"
		
		ClipboardLib.setAndToast(path, "full code location")
	}
	
	;---------
	; DESCRIPTION:    Opens the parent folder for the current file.
	; NOTES:          This is preferable to the built-in open-containing-folder hotkey because the latter locks up Visual
	;                 Studio and then claims that it fails (at least with QTTabBar in place).
	;---------
	openParentFolder() {
		path := ClipboardLib.getWithHotkey(this.Hotkey_CopyCurrentFile)
		if(path = "") {
			Toast.ShowError("Failed to open parent folder", "Failed to get current file path")
			return ""
		}
		path := FileLib.cleanupPath(path)
		
		parentFolder := FileLib.getParentFolder(path) ; Actually get the folder instead of the file
		Run(parentFolder)
	}
	
	;---------
	; DESCRIPTION:    Send code to show a popup (in a ViewBehavior in TypeScript).
	; PARAMETERS:
	;  defaultVarList (I,OPT) - The default list of variables to use, shows in the popup.
	; RETURNS:        
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	sendDebugCodeStringTS(defaultVarList := "") {
		varList := InputBox("Enter variables to send debug string for", , , 500, 100, , , , , defaultVarList)
		if(ErrorLevel) ; Popup was cancelled or timed out
			return
		
		mainTemplate := "
			( LTrim
				$$(this).alert(""""
					<LINES>
				`);
			)"
		lineTemplate := "+ ""\n"" + ""<VAR>: "" + <VAR>"
		
		if(varList = "") {
			line := lineTemplate.replaceTag("VAR", "todo")
			code := mainTemplate.replaceTag("LINES", line)
			ClipboardLib.send(code)
			
			; Select the "todo" label on the only line for the user to replace
			Send, {Left 2}{Up}{Right 11}{Shift Down}{Right 4}{Shift Up}
		
		} else {
			lines := ""
			For _,varName in varList.split(",", " ") {
				lines := lines.appendLine(lineTemplate.replaceTag("VAR", varName))
			}
			
			code := mainTemplate.replaceTag("LINES", lines)
			ClipboardLib.send(code)
		}
	}
	
	; #PRIVATE#
	
	; Hotkeys
	static Hotkey_CopyCurrentFile := "^+c"
	; #END#
}
