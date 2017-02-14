
#IfWinActive, ahk_exe yEd.exe
	
	; Use numpad symbols as normal, don't zoom using those.
	NumpadAdd::Send, +=
	NumpadSub::Send, -
	NumpadMult::Send, +8
	NumpadDiv::Send, /
	
	; Use ctrl+click instead of shift+click to multi-select.
	^LButton::Send, +{LButton}
	
#IfWinActive
