class VisualStudio {
	;region ------------------------------ INTERNAL ------------------------------
	;---------
	; DESCRIPTION:    Send code to show a popup (in a ViewBehavior in TypeScript).
	; PARAMETERS:
	;  defaultVarList (I,OPT) - The default list of variables to use, shows in the popup.
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
	;endregion ------------------------------ INTERNAL ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; Hotkeys
	static Hotkey_CopyCurrentFile := "^+c"
	;endregion ------------------------------ PRIVATE ------------------------------
}
