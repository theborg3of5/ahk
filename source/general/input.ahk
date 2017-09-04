; Input change/fixing functions.

; Select all with exceptions.
$^a::selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::deleteWord()

; Executor normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::
	SetCapsLockState, On
return

#If !MainConfig.windowIsGame()
	XButton1::^Tab
	XButton2::^+Tab
#If

; Special paste for when paste not allowed - just send the contents of the clipboard.
^!v::
	Send, ^+v
	WinWaitActive, ahk_class QPasteClass
	Send, +{Enter}
return

; Clipboard typing - gives an easy place to type things that will then stick them on the clipboard if submitted.
$!v::
	InputBox, outVar, Set Clipboard, Enter text to set the clipboard to:, , , , , , , , %clipboard%
	if(outVar && !ErrorLevel)
		clipboard := outVar
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
