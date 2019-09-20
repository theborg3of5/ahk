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
		waitForHotkeyRelease()
		Send, {Alt}
		Send, {Left 4}{Down}
		Send, {Up 3}
		Send, {Enter}
	return
#If
