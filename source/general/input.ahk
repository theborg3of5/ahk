; General input hotkeys.

; Menu key does different things on laptops without a mouse.
#If MainConfig.menuKeyAction = MENUKEYACTION_MiddleClick
	AppsKey::MButton
#If MainConfig.menuKeyAction = MENUKEYACTION_WindowsKey
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

; Select all with special per-window handling.
$^a::WindowActions.selectAll()

; Backspace shortcut for those that don't handle it well.
$^Backspace::WindowActions.deleteWord()

; Launchy normally uses CapsLock, but (very) occasionally, we need to use it for its intended purpose.
^!CapsLock::
	SetCapsLockState, On
return

#If !MainConfig.windowIsGame() && !MainConfig.isWindowActive("Remote Desktop")
	XButton1::activateWindowUnderMouseAndSendKeys("^{Tab}")
	XButton2::activateWindowUnderMouseAndSendKeys("^+{Tab}")
	activateWindowUnderMouseAndSendKeys(keys) {
		MouseGetPos( , , winId)
		if(!winId)
			return
		
		if(MainConfig.findWindowName("ahk_id " winId) != "Windows Taskbar") ; Don't try to focus Windows taskbar
			activateWindowUnderMouse()
		
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
			return
		
		sendTextWithClipboard(selectedText)
	}