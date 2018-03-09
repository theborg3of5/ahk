; Input change/fixing functions.

; Pop up the keys pressed/debug window.
^!k::KeyHistory

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

#If !MainConfig.windowIsGame() && !WinActive("ahk_class TscShellContainerClass")
	XButton1::
		MouseGetPos, , , winId
		WinActivate, % "ahk_id " winId
		
		; Allow the Ctrl+Tab to be caught and handled by other hotkeys.
		startSendLevel := A_SendLevel
		SendLevel, 1
		Send, ^{Tab}
		SendLevel, % startSendLevel
	return
	XButton2::
		MouseGetPos, , , winId
		WinActivate, % "ahk_id " winId
		
		; Allow the Ctrl+Shift+Tab to be caught and handled by other hotkeys.
		startSendLevel := A_SendLevel
		SendLevel, 1
		Send, ^+{Tab}
		SendLevel, % startSendLevel
	return
#If

^!v::
	waitForHotkeyRelease()
	SendRaw, % clipboard
return

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText(clipboard)
return

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
