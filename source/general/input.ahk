; Input change/fixing functions.

; Select all with exceptions.
$^a::selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::deleteWord()

; Executor normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::
	SetCapsLockState, On
return

#If !(WinActive("ahk_exe Overwatch.exe") 
	|| WinActive("ahk_exe insurgency.exe") 
	|| WinActive("ahk_exe RainbowSixGame.exe") 
	|| WinActive("ahk_exe kfgame.exe")
	|| WinActive("ahk_exe HeroesOfTheStorm_x64.exe"))
	
	XButton1::^Tab
	XButton2::^+Tab
#If

; Special paste for when paste not allowed - just send the contents of the clipboard.
^!v::
	KeyWait, Ctrl
	KeyWait, Alt
	SendRaw, %clipboard%
return

; Clean paste - remove leading/trailing whitespace, odd chars, and newlines from clipboard and send it.
^#!v::
	outStr := cleanupText(clipboard)
	SendRaw, %outStr%
return

; Menu key does different things on laptops without a mouse.
#If MainConfig.getSetting("MENU_KEY_ACTION") = menuKeyActionMiddleClick
	AppsKey::MButton
#If MainConfig.getSetting("MENU_KEY_ACTION") = menuKeyActionWindowsKey
	AppsKey::RWin
#If

#If MainConfig.isMachine(HOME_DESKTOP)
	$Volume_Mute::DllCall("LockWorkStation")	; Lock workstation.
#If

#If MainConfig.isMachine(EPIC_DESKTOP)
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
