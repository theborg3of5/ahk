; General input hotkeys.

; Menu key does different things on laptops without a mouse.
#If MainConfig.menuKeyIsMiddleClick
	AppsKey::MButton
#If MainConfig.menuKeyIsWindowsKey
	AppsKey::RWin
#If

#If MainConfig.machineIsHomeDesktop
	$Volume_Mute::DllCall("LockWorkStation")	; Lock workstation.
#If

#If MainConfig.machineIsEpicLaptop
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

; Select all with special per-window handling.
$^a::WindowActions.selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::WindowActions.deleteWord()

; Launchy normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::
	SetCapsLockState, On
return

#If !MainConfig.windowIsGame() && !MainConfig.isWindowActive("Remote Desktop") && !MainConfig.isWindowActive("VMware Horizon Client")
	XButton1::activateWindowUnderMouseAndSendKeys("^{Tab}")
	XButton2::activateWindowUnderMouseAndSendKeys("^+{Tab}")
	activateWindowUnderMouseAndSendKeys(keys) {
		MouseGetPos( , , winId)
		if(!winId)
			return
		
		idString := "ahk_id " winId
		if(MainConfig.findWindowName(idString) != "Windows Taskbar") ; Don't try to focus Windows taskbar
			WinActivate, % idString
		
		; Allow the keystrokes to be caught and handled by other hotkeys.
		sendUsingLevel(keys, 1)
	}
#If

^!v::
	waitForHotkeyRelease()
	Send, {Text}%clipboard%
return

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText() {
		if(!Hyperlinker.linkSelectedText(clipboard, errorMessage))
			Toast.showError("Failed to link selected text", errorMessage)
	}

; Turn clipboard into standard string and send it.
!+n::
	sendStandardEMC2ObjectString() {
		infoAry := extractEMC2ObjectInfo(clipboard)
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
^#v::
	SendRaw, % ListConverter.convertList(clipboard)
return

; Grab the selected text and pop it into a new Notepad window
!v::
	putSelectedTextIntoNewNotepadWindow() {
		selectedText := getSelectedText()
		if(selectedText = "")
			return
		
		MainConfig.runProgram("Notepad")
		newNotepadWindowTitleString := "Untitled - Notepad " MainConfig.windowInfo["Notepad"].titleString
		WinWaitActive, % newNotepadWindowTitleString, , 5 ; 5s timeout
		if(!WinActive(newNotepadWindowTitleString))
			WinActivate, % newNotepadWindowTitleString ; Try to activate it if it ran but didn't activate for some reason
		if(!WinActive(newNotepadWindowTitleString))
			return
		
		ControlSetText, Edit1, % selectedText, A
	}