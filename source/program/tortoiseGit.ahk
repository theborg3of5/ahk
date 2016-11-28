; TortoiseGit hotkeys and helpers.

; Only applies to the commit finished window.
#If isCommitFinishedWindow()
	$Enter::
		Send, !h
	return
#If

isCommitFinishedWindow() {
	if(!WinActive("ahk_class #32770"))
		return false
	
	if(!titleContains(["Git Command Progress - TortoiseGit"]))
		return false
	
	ControlGetText, text, Button3, A
	if(text = "Pus&h...")
		return true
	
	return false
}