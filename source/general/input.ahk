; General input hotkeys.

; Menu key does different things on laptops without a mouse.
#If MainConfig.getSetting("MENU_KEY_ACTION") = MENUKEYACTION_MiddleClick
	AppsKey::MButton
#If MainConfig.getSetting("MENU_KEY_ACTION") = MENUKEYACTION_WindowsKey
	AppsKey::RWin
#If

#If MainConfig.isMachine(MACHINE_HomeDesktop)
	$Volume_Mute::DllCall("LockWorkStation")	; Lock workstation.
#If

#If MainConfig.isMachine(MACHINE_EpicLaptop)
	Browser_Back::LButton
	Browser_Forward::RButton
#If

; Scroll horizontally with Shift held down.
#If !(MainConfig.isWindowActive("EpicStudio") || MainConfig.isWindowActive("Chrome")) ; Chrome and EpicStudio handle their own horizontal scrolling, and doesn't support WheelLeft/Right all the time.
	+WheelUp::WheelLeft
	+WheelDown::WheelRight
#If

; Release all modifier keys, for cases when some might be "stuck" down.
*#Space::releaseAllModifierKeys()

; Select all with exceptions.
$^a::WindowActions.selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::WindowActions.deleteWord()

; Launchy normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::
	SetCapsLockState, On
return

#If !MainConfig.windowIsGame() && !MainConfig.isWindowActive("Remote Desktop")
	XButton1::
		activateWindowUnderMouse()
		
		; Allow the Ctrl+Tab to be caught and handled by other hotkeys.
		sendUsingLevel("^{Tab}", 1)
	return
	XButton2::
		activateWindowUnderMouse()
		
		; Allow the Ctrl+Shift+Tab to be caught and handled by other hotkeys.
		sendUsingLevel("^+{Tab}", 1)
	return
#If

^!v::
	waitForHotkeyRelease()
	Send, {Text}%clipboard%
return

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	if(!linkSelectedText(clipboard))
		Toast.showMedium("Failed to link selected text.")
return

; Turn selected text or clipboard into standard string and send it.
!+n::
	sendStandardEMC2ObjectString() {
		line := getFirstLineOfSelectedText()
		if(!line) ; Fall back to clipboard if nothing selected
			line := clipboard
		
		infoAry := extractEMC2ObjectInfo(line)
		if(!infoAry)
			return
		
		ini   := infoAry["INI"]
		id    := infoAry["ID"]
		title := infoAry["TITLE"]
		
		standardString := buildStandardEMC2ObjectString(ini, id, title)
		sendTextWithClipboard(standardString) ; Can contain hotkey chars
		
		; Special case for OneNote: link the INI/ID as well.
		if(MainConfig.isWindowActive("OneNote"))
			oneNoteLinkEMC2ObjectInLine(ini, id)
	}

; Send the clipboard as a list.
!v::
	SendRaw, % ListConverter.convertList(clipboard)
return
