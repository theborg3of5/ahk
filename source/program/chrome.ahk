; Google Chrome hotkeys.
#If Config.isWindowActive("Chrome")
	; Options hotkey.
	!o::
		HotkeyLib.waitForRelease() ; Presumably needed because the triggering hotkey has alt in it.
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
	!#c::Chrome.copyTitleLink()
	
	; Send to Telegram (and pick the correct chat).
	~!t::
		WinWaitActive, % Config.windowInfo["Telegram"].titleString
		Telegram.focusNormalChat()
	return
	
	; Handling for file links
	^RButton::Chrome.copyLinkTarget() ; Copy
	^MButton::Chrome.openLinkTarget() ; Open
#IfWinActive
	
#If Config.isWindowActive("Chrome")
	^+o::Chrome.openCodeSearchServerCodeInEpicStudio()
#If

class Chrome {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Put the title of the current tab on the clipboard, with some special exceptions.
	;---------
	copyTitle() {
		ClipboardLib.setAndToast(Chrome.getTitle(), "title")
	}
	
	;---------
	; DESCRIPTION:    Copy the title and URL of the current tab on the clipboard, with some special
	;                 exceptions (see .getTitle() for details).
	;---------
	copyTitleLink() {
		title := Chrome.getTitle()
		
		Send, ^l     ; Focus address bar
		Sleep, 100   ; Wait for address bar to get focused
		url := SelectLib.getText()
		Send, {F6 4} ; Focus the web page again
		
		ClipboardLib.setAndToast(title "`n" url, "title and URL")
	}
	
	;---------
	; DESCRIPTION:    Copy the title and strip " - Google Chrome" off the end.
	; RETURNS:        Title of the window, cleaned and processed.
	; NOTES:          For CodeSearch, we copy the current routine (and the tag, from the selected
	;                 text) instead of the actual title.
	;---------
	getTitle() {
		title := WinGetActiveTitle().removeFromEnd(" - Google Chrome")
		title := title.removeFromEnd(" - Wiki")
		
		if(Chrome.isCurrentPageCodeSearch()) {
			; Special handling for CodeSearch - just get the file name, plus the current selection as the function.
			file := title.beforeString("/")
			function := SelectLib.getCleanFirstLine()
			
			; Client files should always have an extension
			if(file.contains(".")) {
				title := file
				if(function != "")
					title .= " > " function "()"
			} else { ; Server routines
				title := function.appendPiece(file, "^")
			}
		}
		
		return title
	}
	
	;---------
	; DESCRIPTION:    Open the current routine (and tag if it's the selected text) in EpicStudio
	;                 for CodeSearch windows.
	;---------
	openCodeSearchServerCodeInEpicStudio() {
		if(!Chrome.isCurrentPageCodeSearch())
			return
		
		tag := SelectLib.getCleanFirstLine()
		
		title := WinGetActiveTitle()
		title := title.removeFromEnd(" - Google Chrome")
		titleAry := title.split("/")
		routine := titleAry[1]
		if(!routine)
			return
		
		displayCode := tag.appendPiece(routine, "^")
		new Toast("Opening server code in EpicStudio: " displayCode).showMedium()
		
		new ActionObjectEpicStudio(tag "^" routine, ActionObjectEpicStudio.DescriptorType_Routine).openEdit()
	}

	;---------
	; DESCRIPTION:    Open the file-type link under the mouse.
	;---------
	openLinkTarget() {
		filePath := ClipboardLib.getWithFunction(ObjBindMethod(Chrome, "_getLinkTargetOnClipboard"))
		if(filePath) {
			new Toast("Got link target, opening:`n" filePath).showShort()
			Run(filePath)
		} else {
			new ErrorToast("Failed to get link target").showMedium()
		}
	}
	
	;---------
	; DESCRIPTION:    Copy the file-type link under the mouse, also showing the user a toast about it.
	;---------
	copyLinkTarget() {
		ClipboardLib.copyWithFunction(ObjBindMethod(Chrome, "_getLinkTargetOnClipboard"))
		ClipboardLib.toastNewValue("link target")
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Determine whether the current page is CodeSearch, based on its title.
	;---------
	isCurrentPageCodeSearch() {
		; Only have CodeSearch at work
		if(!Config.contextIsWork)
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
