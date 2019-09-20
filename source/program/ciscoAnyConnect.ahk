#If Config.isWindowActive("Cisco AnyConnect VPN")
	; Make enter click connect instead of pulling up the options at startup.
	NumPadEnter::
	$Enter::
		ControlFocus, Button1, A
		Sleep, 100
		Send, {Enter}
	return
#If
