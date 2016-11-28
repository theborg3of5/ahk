#IfWinExist, ahk_class QWidget
	; Pause/play/etc. since vlc is rather odd about number keys...
	^!Numpad0::^!0
	^!Numpad1::^!1
	^!Numpad2::^!2
	^!Numpad3::^!3
#IfWinExist
