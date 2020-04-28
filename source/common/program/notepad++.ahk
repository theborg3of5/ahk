class NotepadPlusPlus {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Open the current file's parent folder in Explorer.
	; NOTES:          We have to do this instead of using the native option, because the native
	;                 option doesn't open it correctly (it opens a new window instead of adding a
	;                 tab to QTTabBar).
	;---------
	openCurrentParentFolder() {
		filePath := ClipboardLib.getWithHotkey("!c")
		if(!filePath) {
			new ErrorToast("Could not open parent folder", "Failed to retrieve current file path").showMedium()
			return
		}
		
		filePath := FileLib.cleanupPath(filePath)
		parentFolder := FileLib.getParentFolder(filePath)
		
		if(!FileLib.folderExists(parentFolder)) {
			new ErrorToast("Could not open parent folder", "Folder does not exist: " parentFolder).showMedium()
			return
		}
		
		Run(parentFolder)
	}
	
	;---------
	; DESCRIPTION:    Insert a newline at the cursor, indented to the same level as the current line.
	;                 Also takes AHK headers into account, indenting to the proper level if you're
	;                 within one.
	; PARAMETERS:
	;  numExtraIndents (I,OPT) - How many extra indents to do versus the start of the current line.
	;                            Defaults to 0 (same level as the current line).
	;---------
	insertIndentedNewline(numExtraIndents := 0) {
		; Read in both sides of the current line - the left will help us find where the indent is, the right is what we're moving.
		Send, {Shift Down}{Home}{Shift Up}
		lineBefore := SelectLib.getText()
		Send, {Shift Down}{End}{Shift Up}
		lineAfter := SelectLib.getText()
		
		; Put the cursor back where it was, where we want to insert the newline.
		if(lineAfter = "")
			Send, {End}
		else
			Send, {Left}
		
		; If we would have a widowed (on the end of the old line) or orphaned (at the start of the new line) space, remove it.
		if(lineBefore.endsWith(A_Space))
			Send, {Backspace}
		if(lineAfter.startsWith(A_Space))
			Send, {Delete}
		
		indent := AHKCodeLib.getNextDocLineIndent(lineBefore, numExtraIndents)
		
		Send, {Enter} ; Start the new line - assuming that Notepad++ will put us at the same indentation level (before the semicolon) as the previous row.
		Send, % indent
	}
	
	;---------
	; DESCRIPTION:    Send a debug code string using the given function name, prompting the user for
	;                 the list of parameters to use (in "varName",varName parameter pairs).
	; PARAMETERS:
	;  functionName (I,REQ) - Name of the function to send before the parameters.
	;---------
	sendDebugCodeString(functionName) {
		if(functionName = "")
			return
		
		varList := InputBox("Enter variables to send debug string for", , , 500, 100, , , , , clipboard)
		if(ErrorLevel) ; Popup was cancelled or timed out
			return
		
		if(varList = "") {
			SendRaw, % functionName "()"
			Send, {Left} ; Get inside parens for user to enter the variables/labels themselves
		} else {
			SendRaw, % functionName "(" AHKCodeLib.generateDebugParams(varList) ")"
		}
	}
	
	;---------
	; DESCRIPTION:    Generate and insert debug parameters, prompting the user for which variables
	;                 to include.
	;---------
	insertDebugParams() {
		varList := clipboard
		if(!varList)
			return
		
		Send, % AHKCodeLib.generateDebugParams(varList)
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
		
		SendRaw, % AHKCodeLib.getDocHeader(defLine)
	}
	
	;---------
	; DESCRIPTION:    Create a continuation block and put the cursor inside.
	; NOTES:          Assumes that you're already at the end of the line where you want to start
	;                 the block.
	;---------
	sendContinuationBlock() {
		parentIndent := this.getCurrentLineIndent()
		
		sectionBase := "
			(
				""
					`t(
						`t`t
					`t)""
			)"
		sectionString := sectionBase.replace("`n", "`n" parentIndent) ; Add parent's indent to each line (except the first one)
		
		ClipboardLib.send(sectionString)
		Send, {Up}{End} ; Get into the new block
	}
	
	;---------
	; DESCRIPTION:    Insert a template of an AHK class (read from a template file) at the cursor.
	;---------
	sendClassTemplate() {
		templateString := FileRead(Config.path["AHK_TEMPLATE"] "\class.ahk")
		if(!templateString) {
			new ErrorToast("Could not insert AHK class template", "Could not read template file").showMedium()
			return
		}
		
		ClipboardLib.send(templateString)
	}
	
	;---------
	; DESCRIPTION:    Send a code snippet.
	; PARAMETERS:
	;  snippetName (I,REQ) - The name of the snippet, see code for which are supported.
	; NOTES:          The snippet will be inserted at the end of the current line
	;---------
	sendSnippet(snippetName) {
		currentIndent := this.getCurrentLineIndent()
		
		Switch snippetName {
			Case "if":
				snippet := "
					(
						if() {
							`t
						}
					)"
				snipString := snippet.replace("`n", "`n" currentIndent) ; Add indent to each line (except the first one)
				ClipboardLib.send(snipString)
				Send, {Up 2}{End}{Left 3} ; Inside the if parens
				
			Case "for":
				snippet := "
					(
						For , in  {
							`t
						}
					)"
				snipString := snippet.replace("`n", "`n" currentIndent) ; Add indent to each line (except the first one)
				ClipboardLib.send(snipString)
				Send, {Up 2}{End}{Left 7} ; At the index spot
		}
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Get the indentation from the current line (as the whitespace it is, not a count).
	; RETURNS:        The whitespace that makes up the indentation.
	; SIDE EFFECTS:   Ends up at the end of the current line, not where we started.
	;---------
	getCurrentLineIndent() {
		Send, {Home}{Shift Down}{Home}{Shift Up} ; Start selecting at the start of the line to get the indentation
		indent := SelectLib.getText()
		Sleep, 100 ; Make sure Ctrl is up so we don't end up jumping to the end of the file.
		Send, {End} ; Get back to the end of the line
		
		return indent
	}
	; #END#
}
