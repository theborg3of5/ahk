/* Class for adding a hyperlink to the currently-selected text.
	
	***
*/

class Hyperlinker {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	; Link the selected text with the given URL/path.
	; Returns whether we were successful.
	linkSelectedText(path) {
		if(!path)
			return false
		
		path := cleanupPath(path)
		path := mapPath(path)
		
		if(!isObject(Hyperlinker.windowsAry))
			Hyperlinker.windowsAry := Hyperlinker.getWindowsAry()
		
		windowName := MainConfig.findWindowName()
		; DEBUG.toast("Hyperlinker.linkSelectedText","Finished gathering info", "windowName",windowName)
		if(!Hyperlinker.doesWindowSupportLinking(windowName))
			return false
		
		Hyperlinker.startLink(windowName)
		if(!Hyperlinker.sendPath(path, windowName))
			return false
		Hyperlinker.finishLink(windowName)
		
		return true
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static windowsAry := ""
	
	; Format: windowsAry[windowName] := Identifying title text for linking popup (where we'll enter the path)
	; windowName is from NAME column of windows.tl config file
	getWindowsAry() {
		windowsAry := []
		
		windowsAry["OneNote"]                := "Link ahk_class NUIDialog"
		windowsAry["Outlook"]                := "ahk_class bosa_sdm_Mso96"
		windowsAry["Word"]                   := "ahk_class bosa_sdm_msword"
		windowsAry["EMC2 DLG"]               := "" ; Fake popup, so we can't wait for it (or sense it at all, really)
		windowsAry["EMC2 QAN"]               := "HyperLink Parameters ahk_class ThunderRT6FormDC"
		windowsAry["EMC2 QAN change status"] := "HyperLink Parameters ahk_class ThunderRT6FormDC"
		windowsAry["EMC2 XDS"]               := "HyperLink Parameters ahk_class ThunderRT6FormDC"
		windowsAry["EMC2 Issue popup"]       := "HyperLink Parameters ahk_class ThunderRT6FormDC"
		windowsAry["Mattermost"]             := "" ; No popup, done inline with specific text (markup-style)
		
		return windowsAry
	}
	
	sendPath(path, windowName) { ; GDB TODO see if we can get rid of the need for windowName here (it's just for MatterMost cop-out of pathIsCorrect check)
		sendTextWithClipboard(path) ; Need to send it raw, but would prefer not to wait for the longer keywaiting.
		if(Hyperlinker.pathIsCorrect(windowName, path))
			return true
		
		; If we somehow didn't put the link in place correctly, wait a half-second and try again.
		Sleep, 500
		sendTextWithClipboard(path) ; Need to send it raw, but would prefer not to wait for the longer keywaiting.
		return Hyperlinker.pathIsCorrect(windowName, path)
	}
	
	doesWindowSupportLinking(name) {
		return Hyperlinker.windowsAry.HasKey(name)
	}
	
	startLink(windowName) {
		if(!windowName)
			return
		
		if(windowName = "Mattermost") { ; Goal: [text](url)
			selectedText := getSelectedText()
			selectionLen := strLen(selectedText)
			Send, {Left} ; Get to start of selection
			Send, [
			Send, {Right %selectionLen%} ; Get to end of selection
			Send, ](
		} else {
			Send, ^k
		}
		
		; Wait for it to open.
		popupTitleString := Hyperlinker.getLinkPopupTitleString(windowName)
		if(popupTitleString) {
			WinWaitActive, % popupTitleString
			if(!WinActive(popupTitleString))
				return
		} else {
			Sleep, 100
		}
	}
	
	getLinkPopupTitleString(windowName) {
		if(!windowName)
			return ""
		
		return Hyperlinker.windowsAry[windowName]
	}
	
	pathIsCorrect(windowName, pathToMatch) {
		if(!windowName)
			return false
		
		; It's all within the one text box (Markup format), so we should be fine.
		if(windowName = "Mattermost")
			return true
		
		Send, {Home}{Shift Down}{End}{Shift Up} ; Select all (even in places that don't support ^a)
		currentPath := getSelectedText()
		; DEBUG.toast("Current path",currentPath)
		
		return (currentPath = pathToMatch)
	}
	
	finishLink(windowName) {
		if(!windowName)
			return
		
		if(windowName = "Mattermost")
			Send, )
		else if(windowName = "EMC2 DLG")
			Send, !a
		else
			Send, {Enter}
	}
}