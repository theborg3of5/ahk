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
	
	; Open different objects based on the title.
	!w::Chrome.openCurrentEMC2ObjectWeb()
	!e::Chrome.openCurrentEMC2ObjectEdit()
	^+o::Chrome.openCodeSearchServerCodeInEpicStudio()
	
	; Handling for file links
	^RButton::Chrome.copyLinkTarget() ; Copy
	^MButton::Chrome.openLinkTarget() ; Open
	
	; Extension-specific handling
	~!t:: ; Send to Telegram (and pick the correct chat). Relies on !t also triggering the Send to Telegram extension.
		WinWaitActive, % Config.windowInfo["Telegram"].titleString
		Telegram.focusNormalChat()
	return
	^!d::Send, !+d ; Dark Reader - site-level hotkey (Chrome won't let me bind this directly)
#If

class Chrome {
	; #INTERNAL#
	
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
	; DESCRIPTION:    Open the EMC2 object on the current page up in the "proper" web version -
	;                 Sherlock for SLGs, etc.
	;---------
	openCurrentEMC2ObjectWeb() {
		new ActionObjectEMC2(Chrome.getTitle()).openWeb()
	}
	
	;---------
	; DESCRIPTION:    Open the EMC2 object on the current page up in EMC2.
	;---------
	openCurrentEMC2ObjectEdit() {
		new ActionObjectEMC2(Chrome.getTitle()).openEdit()
	}
	
	;---------
	; DESCRIPTION:    Copy the title and rearrange/clean it up a bit.
	; RETURNS:        Title of the window, cleaned and processed.
	; NOTES:          Some cases (most notably CodeSearch) will end up with something completely
	;                 different from the title.
	;---------
	getTitle() {
		title := WinGetActiveTitle().removeFromEnd(" - Google Chrome")
		
		; Wiki pages don't need the ending
		title := title.removeFromEnd(" - Wiki")
		
		; Rearrange NullEx post titles slightly
		if(title.endsWith(" - NullException"))
			title := "NullEx - " title.removeFromEnd(" - NullException")
		
		; SLGs in "basic" web mode just show the URL as the title - transform that into an EMC2 record string instead.
		if(title.startsWith(Config.private["EMC2_SLG_TITLE_URL_START"]))
			title := "SLG " title.removeFromStart(Config.private["EMC2_SLG_TITLE_URL_START"])
		
		if(Chrome.isCurrentPageCodeSearch()) {
			; Special handling for CodeSearch - just get the file name, plus the current selection as the function.
			file := title.beforeString("/")
			function := SelectLib.getCleanFirstLine()
			
			; Client files should always have an extension
			if(file.contains(".")) { ; Client files - <file> > <function>()
				title := file
				if(function != "")
					title .= " > " function "()"
			} else { ; Server routines - <tag>^<routine>, or just <routine>
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
		filePath := ClipboardLib.getWithFunction(ObjBindMethod(Chrome, "getLinkTargetOnClipboard"))
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
		ClipboardLib.copyWithFunction(ObjBindMethod(Chrome, "getLinkTargetOnClipboard"))
		ClipboardLib.toastNewValue("link target")
	}
	
	
	; #PRIVATE#
	
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
	getLinkTargetOnClipboard() {
		Click, Right
		Sleep, 100   ; Wait for right-click menu to appear
		Send, e      ; Copy link address
	}
	; #END#
}
