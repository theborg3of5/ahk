; Hyperdrive hotkeys.
#If Config.isWindowActive("Hyperdrive")
	$F5::+F5 ; Make F5 work everywhere by mapping it to shift + F5.
	
	; Login
	^+t::
		Send, !c!o ; Get out of Smart Card prompt (and back to login if there wasn't one).
		Send, % Config.private["WORK_ID"]
		Send, {Enter}
		Send, % Config.private["WORK_PASSWORD"]
		Send, {Enter}
		
		Sleep, 500
		Send, ={Enter} ; Same department at prompt, if it shows up (also hits info prompt if that shows up)
	return
#If

; HSWeb Debug Console
#If WinActive(Config.private["EPIC_HSWEB_CONSOLE_TITLESTRING"])
	^r::
		selectHSWebConsoleCommand() {
			data := new Selector("hswebConsoleCommands.tls").selectGui()
			if(!data)
				return
			
			WinActivate, % Config.private["EPIC_HSWEB_CONSOLE_TITLESTRING"] ; Make sure focus gets back to the proper window
			
			code       := data["CODE"]
			selectText := data["SELECT_TEXT"]
			
			SendRaw, % code
			if(selectText != "") {
				Send, ^a ; Select all so we can use selectTextWithinSelection
				SelectLib.selectTextWithinSelection(selectText)
			}
		}
#If
