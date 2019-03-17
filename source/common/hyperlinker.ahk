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
		if(!Hyperlinker.sendPath(windowName, path))
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
		/*
			(	NAME								SET_PATH_METHOD			LINK_POPUP							PATH_FIELD_CONTROL_ID		TAGGED_STRING_BASE
			
			; EMC2 link popup and path field are the same across most EMC2 workflows.
			[LINK_POPUP.replaceWith(HyperLink Parameters ahk_class ThunderRT6FormDC)|PATH_FIELD_CONTROL_ID.replaceWith(ThunderRT6TextBox1)]
				EMC2 QAN							POPUP_FIELD
				EMC2 QAN change status		POPUP_FIELD
				EMC2 XDS							POPUP_FIELD
			[]
				OneNote							POPUP_FIELD					Link ahk_class NUIDialog		RICHEDIT60W2
				Outlook							POPUP_FIELD					ahk_class bosa_sdm_Mso96		RichEdit20W6
				Word								POPUP_FIELD					ahk_class bosa_sdm_msword		RichEdit20W6
				
				EMC2 DLG							WEB_FIELD					-
				Mattermost						TAGGED_STRING				-										-									[<TEXT>](<PATH>)
		*/
		
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
	
	sendPath(windowName, path) {
		if(windowName = "OneNote") {
			ControlSetText, % "RICHEDIT60W2", % path, A
			return true
		} else if(windowName = "EMC2 DLG") {
			return setWebFieldValue(path)
		}
		
		sendTextWithClipboard(path) ; Need to send it raw, but would prefer not to wait for the longer keywaiting.
		if(Hyperlinker.isPastedPathCorrect(windowName, path))
			return true
		
		; If we somehow didn't put the link in place correctly, wait a half-second and try again.
		Sleep, 500
		sendTextWithClipboard(path) ; Need to send it raw, but would prefer not to wait for the longer keywaiting.
		return Hyperlinker.isPastedPathCorrect(windowName, path)
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
	
	isPastedPathCorrect(windowName, pathToMatch) {
		if(!windowName)
			return false
		
		; It's all within the one text box (Markup format), so we should be fine.
		if(windowName = "Mattermost")
			return true
		
		selectCurrentLine()
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