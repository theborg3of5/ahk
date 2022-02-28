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
		url   := Chrome.getURL()
		ClipboardLib.setAndToast(title "`n" url, "title and URL")
	}
	
	;---------
	; DESCRIPTION:    Copy the relative path to the current file for client CodeSearch.
	; RETURNS:        Source-relative filepath with leading backslash
	;---------
	copyCodeSearchClientPath() {
		if(!Chrome.isCurrentPageCodeSearchClient())
			return
		
		path := "\" Chrome.getRawURL().firstBetweenStrings("&name=", "&")
		path := StringLib.decodeFromURL(path)
		ClipboardLib.setAndToast(path, "source-relative file path")
	}
	
	;---------
	; DESCRIPTION:    Open the DLG from the current page in EpicStudio.
	;---------
	openCurrentDLGInEpicStudio() {
		ao := new ActionObjectEMC2(Chrome.getTitle())
		if(ao.ini != "DLG") {
			Toast.ShowError("Failed to launch DLG in EpicStudio", "Object was not a DLG")
			return
		}
		
		if(ao.id = "") {
			Toast.ShowError("Failed to launch DLG in EpicStudio", "No DLG ID found")
			return
		}
		
		Toast.ShowShort("Opening DLG in EpicStudio: " ao.id)
		new ActionObjectEpicStudio(ao.id, ActionObjectEpicStudio.DescriptorType_DLG).open()
	}
	
	;---------
	; DESCRIPTION:    Copy the title and rearrange/clean it up a bit.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string representing the window to get the title of.
	; RETURNS:        Title of the window, cleaned and processed.
	; NOTES:          Some cases (most notably CodeSearch) will end up with something completely
	;                 different from the title.
	;---------
	getTitle(titleString := "A") {
		title := WinGetTitle(titleString)
		
		; This suffix is never helpful.
		title := title.removeFromEnd(" - Google Chrome")
		
		; Wiki pages don't need the ending
		title := title.removeFromEnd(" - Wiki")
		
		; Rearrange NullEx post titles slightly
		if(title.endsWith(" - NullException"))
			title := "NullEx - " title.removeFromEnd(" - NullException")
		
		; Guru pages don't need the ending
		if(title.endsWith(" - Guru")) {
			title := title.removeFromEnd(" - Guru")
			title := title.removeFromEnd("'s Profile") ; Profiles are pretty self-explanatory with just the person's name, too.
		}
		
		; SLGs in "basic" web mode just show the URL as the title - transform that into an EMC2 record string instead.
		if(title.startsWith(Config.private["EMC2_SLG_TITLE_URL_START"]))
			title := "SLG " title.removeFromStart(Config.private["EMC2_SLG_TITLE_URL_START"])
		
		if(this.isCurrentPageCodeSearch()) {
			; Special handling for CodeSearch - just get the file name, plus the current selection as the function.
			file := title.beforeString("/")
			function := SelectLib.getCleanFirstLine()
			
			if(this.isCurrentPageCodeSearchClient()) { ; Client files - <file>::<function>()
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
	; DESCRIPTION:    Get the (cleaned) titles of all Chrome windows.
	; RETURNS:        Array of titles.
	;---------
	getAllWindowTitles() {
		titles := []
		
		For _,windowId in WinGet("List", Config.windowInfo["Chrome"].titleString) {
			title := this.getTitle("ahk_id " windowId)
			if(title)
				titles.push(title)
		}
		
		return titles
	}
	
	;---------
	; DESCRIPTION:    Get the current tab's URL for copying and linking purposes.
	; RETURNS:        URL string
	; NOTES:          Tweaks the URL somewhat for CodeSearch pages.
	;---------
	getURL() {
		url := this.getRawURL()
		
		if(Chrome.isCurrentPageCodeSearch()) {
			title := WinGetActiveTitle().removeFromEnd(" - Google Chrome")
			file := title.beforeString("/")
			
			; Client files should always have an extension
			if(file.contains(".")) { ; Client files - use current URL but update the line # based on our selected line.
				lineNum := this.getCodeSearchSelectionLineNum()
				if(lineNum != "")
					url := url.replaceRegEx("&line=(\d+)", "&line=" lineNum)
			} else { ; Server routines - link to exact tag + routine
				function := SelectLib.getCleanFirstLine()
				location := function.appendPiece(file, "^")
				url := new ActionObjectCodeSearch(location).getLink()
				; Debug.popup("function",function, "file",file, "location",location, "url",url)
			}
		}
		
		return url
	}

	;---------
	; DESCRIPTION:    Open the file-type link under the mouse.
	;---------
	openLinkTarget() {
		path := this.getLinkTarget()
		if(path) {
			Toast.ShowShort("Got link target, opening:`n" path)
			Run(path)
		} else {
			Toast.ShowError("Failed to get link target")
		}
	}
	
	;---------
	; DESCRIPTION:    Copy the file-type link under the mouse, also showing the user a toast about it.
	;---------
	copyLinkTarget() {
		ClipboardLib.setAndToast(this.getLinkTarget(), "link target")
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Get the current tab's URL, using the Quick Copy URL extension:
	;                 https://chrome.google.com/webstore/detail/quick-copy-url/pejnfjhmapcmemanpjfalfkmeblolhnj
	; RETURNS:        The current tab's URL
	;---------
	getRawURL() {
		return ClipboardLib.getWithHotkey("!c") ; !c = "Copy the URL of your current tab" hotkey
	}
	
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
	; DESCRIPTION:    Determine whether the current page is CodeSearch in client files, based on its title.
	;---------
	isCurrentPageCodeSearchClient() {
		if(!Chrome.isCurrentPageCodeSearch())
			return false
		
		filename := WinGetActiveTitle().beforeString("/")
		return filename.contains(".") ; Client files should always have an extension
	}
	
	;---------
	; DESCRIPTION:    Get the (cleaned-up) path in the link currently under the mouse.
	; RETURNS:        The cleaned-up path.
	;---------
	getLinkTarget() {
		path := ClipboardLib.getWithFunction(ObjBindMethod(Chrome, "getLinkTargetOnClipboard"))
		return FileLib.cleanupPath(path)
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
	;  jsElementCode (I,REQ) - JS code that will return the element you're interested in.
	; NOTES:          Works using some JS code that temporarily selects the element in question and copies to the clipboard.
	;---------
	getElementText(jsElementCode) {
		return ClipboardLib.getWithFunction(ObjBindMethod(Chrome, "copyElementText", jsElementCode), 2) ; Wait for longer than the default 0.5 seconds, for bigger pages where the JS takes longer to run.
	}
	
	;---------
	; DESCRIPTION:    Select the contents of a specific HTML element and copy it to the clipboard.
	; PARAMETERS:
	;  querySelector (I,REQ) - JS code that will return the element you're interested in.
	; NOTES:          Works using some JS code that temporarily selects the element in question and copies to the clipboard.
	;---------
	copyElementText(jsElementCode) {
		copyElementTextJS := "
			(
				/* Get the element we want to copy from */
				var elementToCopy = <JS_ELEMENT_CODE>;
				/* Make sure the element is selectable */
				elementToCopy.style.userSelect = ""text"";
				
				/* Save off current selection so we can restore it below */
				var selection = window.getSelection();
				var oldRange = selection.getRangeAt(0); /* Assuming only 1 range currently selected */
				
				/* Select the text we want and copy it */
				var newRange = document.createRange();
				newRange.selectNodeContents(elementToCopy);
				selection.removeAllRanges();
				selection.addRange(newRange);
				document.execCommand(""copy"");
				
				/* Put original selection back */
				selection.removeAllRanges();
				selection.addRange(oldRange);
			)"
		
		jsCode := copyElementTextJS.replaceTag("JS_ELEMENT_CODE", jsElementCode)
		
		this.runJavascriptCode(jsCode) ; JS code will update the clipboard
	}
	
	;---------
	; DESCRIPTION:    Run the given Javascript code on the current tab by plugging it into the address bar.
	; PARAMETERS:
	;  jsCode (I,REQ) - Javascript code to run. If it contains newlines, make sure any comments use /**/ instead of // (otherwise everything after will be treated as commented out)
	;---------
	runJavascriptCode(jsCode) {
		; Safety check to prevent us from just entering "javascript:" in the title bar, which navigates to a Google search.
		if(jsCode = "") {
			Toast.ShowError("Failed to run JS code", "Given code was blank")
			return
		}
		
		Send, ^l                  ; Focus address bar
		Sleep, 100                ; Wait for it to get focus
		
		; Paste in JS code
		ClipboardLib.send("javascript") ; Need to split up the "javascript:" prefix because otherwise it gets stripped out on paste by Chrome.
		ClipboardLib.send(":" jsCode)
		
		Sleep, 400                ; JS code doesn't run without this - not sure if because content not all in yet, or another safety measure (I suspect the latter)
		Send, {Enter}             ; Submit
	}
	
	;---------
	; DESCRIPTION:    Get the line number for your currently selected text in CodeSearch.
	; RETURNS:        Line number
	;---------
	getCodeSearchSelectionLineNum() {
		return Chrome.getElementText("window.getSelection().anchorNode.parentElement.closest(""tr"").firstElementChild")
	}
	
	; #END#
}
