#If Config.isWindowActive("KDiff")
	; Show/hide whitespace differences.
	^i::
		Send, !i
		Send, {Down}
		Send, {Enter}
	return
	
	; Hotkey to toggle line wrapping.
	^+w::
		Send, !i
		Send, {Up 3}
		Send, {Enter}
	return
	
	; Split diff
	^q::
		HotkeyLib.waitForRelease()
		Send, {Alt}
		Send, {Left 4}{Down}
		Send, {Up 3}
		Send, {Enter}
	return
	
	; Swap files
	^s::
		Send, ^o            ; Open window
		Send, +{Tab 2}      ; Focus starts on OK button, jump to Swap/Copy Names button
		Send, {Space}       ; Open Swap/Copy Names dropdown
		Send, {Down}{Enter} ; Select first option: Swap A<->B
		Send, !o            ; OK button
	return
#If
