; Google Chrome hotkeys.
#If MainConfig.isWindowActive("Chrome")
	; Options hotkey.
	!o::
		waitForHotkeyRelease() ; Presumably needed because the triggering hotkey has alt in it.
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, s  ; Settings
	return
	
	; Extensions hotkey.
	^+e::
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, l  ; More tools
		Send, e  ; Extensions
	return
	
	; Copy title, stripping off the " - Google Chrome" at the end.
	!c::Chrome.copyTitle()
	
	; Send to Telegram (and pick the correct chat).
	~!t::
		WinWaitActive, % MainConfig.windowInfo["Telegram"].titleString
		Telegram.focusNormalChat()
	return
	
	; Handling for file links
	^RButton::Chrome.copyLinkTarget() ; Copy
	^MButton::Chrome.openLinkTarget() ; Open
#IfWinActive
	
#If MainConfig.isWindowActive("Chrome")
	^+o::Chrome.openCodeSearchServerCodeInEpicStudio()
#If

class Chrome {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Put the title of the current tab on the clipboard, with some special exceptions.
	; NOTES:          For CodeSearch, we copy the current routine (and the tag, from the selected
	;                 text) instead of the actual title.
	;---------
	copyTitle() {
		title := WinGetActiveTitle().removeFromEnd(" - Google Chrome")
		
		if(Chrome.isCurrentPageCodeSearch()) {
			; Special handling for CodeSearch - just get the routine name, plus the current selection as the tag.
			routine := title.beforeString("/")
			tag     := getFirstLineOfSelectedText().clean()
			
			if(tag != "")
				title := tag "^" routine
			else
				title := routine
		}
		
		setClipboardAndToastValue(title, "title")
	}
	
	;---------
	; DESCRIPTION:    Open the current routine (and tag if it's the selected text) in EpicStudio
	;                 for CodeSearch windows.
	;---------
	openCodeSearchServerCodeInEpicStudio() {
		if(!Chrome.isCurrentPageCodeSearch())
			return
		
		tag := getFirstLineOfSelectedText().clean()
		
		title := WinGetActiveTitle()
		title := title.removeFromEnd(" - Google Chrome")
		titleAry := title.split("/")
		routine := titleAry[1]
		if(!routine)
			return
		
		displayCode := appendPieceToString(tag, "^", routine)
		Toast.showMedium("Opening server code in EpicStudio: " displayCode)
		
		ao := new ActionObjectEpicStudio(tag "^" routine, ActionObjectEpicStudio.DescriptorType_Routine)
		ao.openEdit()
	}

	;---------
	; DESCRIPTION:    Open the file-type link under the mouse.
	;---------
	openLinkTarget() {
		copyWithFunction(ObjBindMethod(Chrome, "_getLinkTargetOnClipboard"))
		
		filePath := clipboard
		if(filePath) {
			Toast.showShort("Got link target, opening:`n" filePath)
			Run(filePath)
		} else {
			Toast.showError("Failed to get link target")
		}
	}
	
	;---------
	; DESCRIPTION:    Copy the file-type link under the mouse, also showing the user a toast about it.
	;---------
	copyLinkTarget() {
		copyWithFunction(ObjBindMethod(Chrome, "_getLinkTargetOnClipboard"))
		toastNewClipboardValue("link target")
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Determine whether the current page is CodeSearch, based on its title.
	;---------
	isCurrentPageCodeSearch() {
		; Only have CodeSearch on Epic machine
		if(!MainConfig.contextIsWork)
			return false
		
		title := WinGetActiveTitle().removeFromEnd(" - Google Chrome")
		return title.endsWith(" - CodeSearch")
	}
	
	;---------
	; DESCRIPTION:    Copy the target of the link under the mouse to the clipboard.
	;---------
	_getLinkTargetOnClipboard() {
		Click, Right
		Sleep, 100   ; Wait for right-click menu to appear
		Send, e      ; Copy link address
	}
}
