#IfWinActive, ahk_class SunAwtFrame
	; Debug hotkeys
	F5::Send, !{F5}
	F10::Send, {F8}
	F11::Send, !{F7}
	+F11::Send, !+{F7}
	
	; Disable quit hotkey
	^q::return
#IfWinActive

#IfWinActive, ahk_class SunAwtDialog
	Tab::F6
#IfWinActive

#IfWinActive, Diff Files
	; Next/previous diff block.
	^Down::^.
	^Up::^,
#IfWinActive
