; Input change/fixing functions.

; Release all modifier keys, for cases when some might be "stuck" down.
*#Space::Send, {LWin Up}{RWin Up}{LCtrl Up}{RCtrl Up}{LAlt Up}{RAlt Up}{LShift Up}{RShift Up}

; Select all with exceptions.
$^a::selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::deleteWord()

; Launchy normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::
	SetCapsLockState, On
return

; Scroll horizontally with Shift held down.
+WheelUp::WheelLeft
+WheelDown::WheelRight

#If !MainConfig.windowIsGame() && !MainConfig.isRemoteDesktopActive()
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
^+k::linkSelectedText(clipboard)

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
	; For ergonomic keyboard.
	browser_back up::
		Click
	return
	browser_forward up::
		Click, Right
	return

	browser_back::
	browser_forward::
		return
#If
