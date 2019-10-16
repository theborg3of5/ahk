; General input hotkeys.

#If Config.machineIsHomeDesktop
	$Volume_Mute::DllCall("LockWorkStation")	; Lock computer.
#If Config.machineIsHomeLaptop || Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
#If Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	Browser_Back::LButton
	Browser_Forward::RButton
#If

; Scroll horizontally with Shift held down.
#If !(Config.isWindowActive("EpicStudio") || Config.isWindowActive("Chrome")) ; Chrome and EpicStudio handle their own horizontal scrolling, and doesn't support WheelLeft/Right all the time.
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

#If !Config.windowIsGame() && !Config.isWindowActive("Remote Desktop") && !Config.isWindowActive("VMware Horizon Client")
	XButton1::activateWindowUnderMouseAndSendKeys("^{Tab}")
	XButton2::activateWindowUnderMouseAndSendKeys("^+{Tab}")
	activateWindowUnderMouseAndSendKeys(keys) {
		MouseGetPos( , , winId)
		if(!winId)
			return
		
		idString := "ahk_id " winId
		windowName := Config.findWindowName(idString)
		if(windowName != "Windows Taskbar" && windowName != "Windows Taskbar Secondary") ; Don't try to focus Windows taskbar
			WinActivate, % idString
		
		startSendLevel := setSendLevel(1) ; Allow the keystrokes to be caught and handled by other hotkeys.
		Send, %keys%
		setSendLevel(startSendLevel)
	}
#If

^!v::
	waitForHotkeyRelease()
	Send, {Text}%clipboard%
return

; Turn the selected text into a link to the URL on the clipboard.
^+k::
	linkSelectedText() {
		waitForHotkeyRelease()
		if(!Hyperlinker.linkSelectedText(clipboard, errorMessage))
			new ErrorToast("Failed to link selected text", errorMessage).showMedium()
	}
	
; Send a (newline-separated) text/URL combo from the clipboard as a link.
^+#k::
	sendLinkedTextFromClipboard() {
		waitForHotkeyRelease()
		text := clipboard.beforeString("`n")
		url  := clipboard.afterString("`n")
		
		; Send and select the text
		sendTextWithClipboard(text)
		textLen := text.length()
		Send, {Shift Down}{Left %textLen%}{Shift Up}
		
		if(!Hyperlinker.linkSelectedText(url, errorMessage))
			new ErrorToast("Failed to link text", errorMessage).showMedium()
	}

; Turn clipboard into standard string and send it.
!+n::
	sendStandardEMC2ObjectString() {
		waitForHotkeyRelease()
		ao := new ActionObjectEMC2(clipboard)
		sendTextWithClipboard(ao.standardEMC2String) ; Can contain hotkey chars
		
		; Special case for OneNote: link the INI/ID as well.
		if(Config.isWindowActive("OneNote"))
			OneNote.linkEMC2ObjectInLine(ao.ini, ao.id)
	}

; Send the clipboard as a list.
^#v::new FormatList(clipboard).sendList()

; Grab the selected text and pop it into a new Notepad window
!v::
	putSelectedTextIntoNewNotepadWindow() {
		selectedText := getSelectedText()
		if(selectedText = "")
			return
		
		Config.runProgram("Notepad")
		newNotepadWindowTitleString := "Untitled - Notepad " Config.windowInfo["Notepad"].titleString
		WinWaitActive, % newNotepadWindowTitleString, , 5 ; 5s timeout
		if(!WinActive(newNotepadWindowTitleString))
			WinActivate, % newNotepadWindowTitleString ; Try to activate it if it ran but didn't activate for some reason
		if(!WinActive(newNotepadWindowTitleString))
			return
		
		ControlSetText, Edit1, % selectedText, A
	}