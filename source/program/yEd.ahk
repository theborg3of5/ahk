
#IfWinActive, ahk_exe yEd.exe
	
	; Use numpad symbols as normal, don't zoom using those.
	NumpadAdd::Send, +=
	NumpadSub::Send, -
	NumpadMult::Send, +8
	NumpadDiv::Send, /
	
	; Use Ctrl+click instead of shift+click to multi-select.
	^LButton::Send, +{LButton}
	
	; Make Shift+click always drag element
	+LButton::
		Send, {LButton} ; Click once to select
		Send, {LButton Down}
		KeyWait, LButton ; Wait until user releases the button, then release our artificial click accordingly.
		Send, {LButton Up}
	return
	
#IfWinActive
