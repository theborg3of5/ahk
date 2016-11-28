#IfWinActive, Cisco AnyConnect Secure Mobility Client 
	; Make enter click connect instead of pulling up the options at startup.
	NumPadEnter::
	$Enter::
		ControlFocus, Button1, A
		Sleep, 100
		Send, {Enter}
	return
#IfWinActive
