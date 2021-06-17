﻿class Chrome {
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
		url := Chrome.getCurrentURL()
		ClipboardLib.setAndToast(title "`n" url, "title and URL")
	}
	
	;---------
	; DESCRIPTION:    Get the current tab's URL, using the Quick Copy URL extension:
	;                 https://chrome.google.com/webstore/detail/quick-copy-url/pejnfjhmapcmemanpjfalfkmeblolhnj
	; RETURNS:        The current tab's URL
	;---------
	getCurrentURL() {
		return ClipboardLib.getWithHotkey("!c") ; !c = "Copy the URL of your current tab" hotkey
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
	; DESCRIPTION:    Open the DLG from the current page in EpicStudio.
	;---------
	openCurrentDLGInEpicStudio() {
		ao := new ActionObjectEMC2(Chrome.getTitle())
		if(ao.ini != "DLG") {
			new ErrorToast("Failed to launch DLG in EpicStudio", "Object was not a DLG").showMedium()
			return
		}
		
		if(ao.id = "") {
			new ErrorToast("Failed to launch DLG in EpicStudio", "No DLG ID found").showMedium()
			return
		}
		
		t := new Toast("Opening DLG in EpicStudio: " ao.id).showShort()
		new ActionObjectEpicStudio(ao.id, ActionObjectEpicStudio.DescriptorType_DLG).open()
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
					title .= "::" function "()"
			} else { ; Server routines - <tag>^<routine>, or just <routine>
				title := function.appendPiece(file, "^")
			}
		}
		
		return title
	}

	;---------
	; DESCRIPTION:    Open the file-type link under the mouse.
	;---------
	openLinkTarget() {
		path := ClipboardLib.getWithFunction(ObjBindMethod(Chrome, "getLinkTargetOnClipboard"))
		if(path) {
			new Toast("Got link target, opening:`n" path).showShort()
			Run(path)
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
		Sleep, 500   ; Wait for right-click menu to appear
		Send, e      ; Copy link address
	}
	
	;---------
	; DESCRIPTION:    Get the text from an HTML element on the current page.
	; PARAMETERS:
	;  querySelector (I,REQ) - Selector query (i.e. tag.class#id), for use with document.querySelector()
	; RETURNS:        The text copied from that element
	; NOTES:          Works using some JS code that temporarily selects the element in question and copies to the clipboard.
	;---------
	getElementText(querySelector) {
		return ClipboardLib.getWithFunction(ObjBindMethod(Chrome, "copyElementText", querySelector))
	}
	
	;---------
	; DESCRIPTION:    Select the contents of a specific HTML element and copy it to the clipboard.
	; PARAMETERS:
	;  querySelector (I,REQ) - Selector query (i.e. tag.class#id), for use with document.querySelector()
	; NOTES:          Works using some JS code that temporarily selects the element in question and copies to the clipboard.
	;---------
	copyElementText(querySelector) {
		copyElementTextJS := "
			(
				/* Save off current selection so we can restore it below */
				var selection = window.getSelection();
				var oldRange = selection.getRangeAt(0); /* Assuming only 1 range currently selected */
				
				/* Select the text we want and copy it */
				var newRange = document.createRange();
				newRange.selectNodeContents(document.querySelector(""<QUERY_SELECTOR>""));
				selection.removeAllRanges();
				selection.addRange(newRange);
				document.execCommand(""copy"");
				
				/* Put original selection back */
				selection.removeAllRanges();
				selection.addRange(oldRange);
			)"
		
		jsCode := copyElementTextJS.replaceTag("QUERY_SELECTOR", querySelector)
		
		Send, ^l                  ; Focus address bar
		Sleep, 100                ; Wait for it to get focus
		Send, % "javascript:"     ; Can't paste this bit in, it gets stripped off (safety measure)
		ClipboardLib.send(jsCode) ; Paste in JS code
		Sleep, 400                ; JS code doesn't run without this - not sure if because content not all in yet, or another safety measure (I suspect the latter)
		Send, {Enter}             ; Submit
		
		; JS code will update the clipboard
	}
	; #END#
}
