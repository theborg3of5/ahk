; Main Quick Dial Window.
#IfWinActive, Quick Dial
	Tab::
		Send, {Tab 6}
	return
	
	; Opens the phone.tl file for editing.
	NumpadAdd::
		Run, %  MainConfig.getFolder("AHK_LOCAL_CONFIG") "\phone.tl"
	return
#IfWinActive

; OK/Hang up popup.
#IfWinActive, ahk_class WindowsForms10.Window.8.app.0.1517e87
	Enter::
		Send, {Space}
	return
#IfWinActive
