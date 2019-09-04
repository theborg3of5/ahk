; General input hotkeys.

#If MainConfig.machineIsHomeDesktop
	$Volume_Mute::DllCall("LockWorkStation")	; Lock computer.
#If MainConfig.machineIsHomeLaptop || MainConfig.machineIsEpicLaptop || MainConfig.machineIsEpicVDI
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
#If MainConfig.machineIsEpicLaptop || MainConfig.machineIsEpicVDI
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
		windowName := MainConfig.findWindowName(idString)
		if(windowName != "Windows Taskbar" && windowName != "Windows Taskbar Secondary") ; Don't try to focus Windows taskbar
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
		waitForHotkeyRelease()
		if(!Hyperlinker.linkSelectedText(clipboard, errorMessage))
			Toast.showError("Failed to link selected text", errorMessage)
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
			Toast.showError("Failed to link text", errorMessage)
	}

; Turn clipboard into standard string and send it.
!+n::
	sendStandardEMC2ObjectString() {
		waitForHotkeyRelease()
		ao := new ActionObjectEMC2(clipboard)
		sendTextWithClipboard(ao.standardEMC2String) ; Can contain hotkey chars
		
		; Special case for OneNote: link the INI/ID as well.
		if(MainConfig.isWindowActive("OneNote"))
			OneNote.linkEMC2ObjectInLine(ao.ini, ao.id)
	}

; Send the clipboard as a list.
^#v::
	sendClipboardAsFormatList() {
		fl := new FormatList(clipboard)
		fl.sendList()
	}

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