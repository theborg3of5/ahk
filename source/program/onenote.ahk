; OneNote hotkeys.
#If MainConfig.isWindowActive("OneNote")
	; Make ctrl+tab (and XButtons) switch pages, not sections
	^Tab:: Send, ^{PgDn}
	^+Tab::Send, ^{PgUp}
	XButton1::Send, ^{PgDn}
	XButton2::Send, ^{PgUp}
	; Make ctrl+page down/up switch sections
	^PgDn::Send, ^{Tab}
	^PgUp::Send, ^+{Tab}
	
	; Expand and collapse outlines
	!Left:: !+-
	!Right::!+=
	; Alternate history back/forward
	!+Left:: Send, !{Left}
	!+Right::Send, !{Right}
	
	; Make line movement alt + up/down instead of alt + shift + up/down to match notepad++ and EpicStudio.
	!Up::  !+Up
	!Down::!+Down
	
	; Horizontal scrolling.
	+WheelUp::  OneNote.scrollLeft()
	+WheelDown::OneNote.scrollRight()
	
	^!n::Send, ^+n ; 'Normal' text formatting, as ^+n is already being used for new subpage.
	^7::^6 ; Make ^7 do the same tag (Done green check) as ^6.
	^+8::SendRaw, % "*" MainConfig.private["INITIALS"] " " FormatTime(, "MM/yy") ; Insert contact comment
	
	; Delete the entire current line
	^d::
		OneNote.escapePastePopup()
		OneNote.selectLine()
		Send, {Delete}
	return
	
	; Notebook syncing
	^s::
		OneNote.escapePastePopup()
		Send, +{F9} ; Sync This Notebook Now
	return
	^+s::
		OneNote.escapePastePopup()
		Send, {F9} ; Sync All Notebooks Now
	return
	
	; Various specific commands based on the quick access toolbar.
	$^+n::OneNote.newSubpage()
	^+[:: OneNote.promoteSubpage()
	^+]:: OneNote.makeSubpage()
	$^+d::OneNote.deletePageWithConfirm()
	!m::  OneNote.addMeetingNotes()
	^0::  OneNote.zoomTo100Percent()
	^+c:: OneNote.applyCodeStyle()
	^l::  OneNote.createLinkPageSpecSection()
	^+l:: OneNote.createLinkDevPageSpecSection()
	^+i:: OneNote.addSubLinesToSelectedLines()
	
	; Link handling
	!c::OneNote.copyLinkToCurrentPage()
	^RButton::OneNote.copyLinkUnderMouse()
	^MButton::OneNote.removeLinkUnderMouse()
	
	; Todo page handling
	^t::         OneNote.todoPageCollapseToItems(true)  ; Today only, item-level
	^+t::        OneNote.todoPageCollapseToItems(false) ; All sections, item-level
	^!t::        OneNote.todoPageCollapse(true)         ; Today only, fully expanded
	^+m::        OneNote.todoPageCopy()                 ; New page for today
	^+#m::       OneNote.todoPageCopy(1)                ; New page for tomorrow
	:*:.todosat::OneNote.todoAddUsualSat()              ; Add usual todos for Saturday
	:*:.todosun::OneNote.todoAddUsualSun()              ; Add usual todos for Sunday

	; Clean up a table from an emc2summary page
	^+f::OneNote.cleanUpEMC2SummaryTableFormatting()
	
	; Update links for a dev structure section header
	!+#n::OneNote.linkDevStructureSectionTitle()
#If
	
class OneNote {

; ==============================
; == Public ====================
; ==============================
	;---------
	; DESCRIPTION:    Scroll left/right in the OneNote window (assuming it's under the mouse)
	;---------
	scrollLeft() {
		MouseGetPos, , , winId, controlId, 1
		SendMessage, WM_HSCROLL, SB_LINELEFT, , % controlId, % "ahk_id " winId
	}
	scrollRight() {
		MouseGetPos, , , winId, controlId, 1
		SendMessage, WM_HSCROLL, SB_LINERIGHT, , % controlId, % "ahk_id " winId
	}
	
	;---------
	; DESCRIPTION:    If the paste popup has appeared, get rid of it. Typically this is used for AHK
	;                 hotkeys that use the Control key, which sometimes causes the paste popup to
	;                 appear afterwards (if we pasted recently).
	;---------
	escapePastePopup() {
		if(!ControlGet("Hwnd", , "OOCWindow1", A))
			return
		
		Send, {Space}{Backspace}
	}
	
	;---------
	; DESCRIPTION:    Select the whole line in OneNote, taking into account that it might already be selected.
	;---------
	selectLine() {
		Send, {Home} ; Make sure the line isn't already selected, otherwise we select the whole parent.
		Send, ^a     ; Select all - gets entire line, including newline at end.
	}
	
	;---------
	; DESCRIPTION:    Named commands for hard-coded references to quick access toolbar items in OneNote.
	;---------
	newSubpage() {
		Send, !1
	}
	promoteSubpage() {
		Send, !2
	}
	makeSubpage() {
		Send, !3
	}
	deletePage() {
		Send, !4
	}
	addMeetingNotes() {
		Send, !5
	}
	zoomTo100Percent() {
		Send, !6
	}
	customStyles() {	; Custom styles from OneTastic
		Send, !7
	}
	createLinkPageSpecSection() { ; Custom OneTastic macro - create linked page in specific(s) section
		Send, !8
	}
	createLinkDevPageSpecSection() { ; Custom OneTastic macro - create linked dev page in specifics section
		Send, !9
	}
	addSubLinesToSelectedLines() { ; Custom OneTastic macro - add sub-lines to selected lines
		Send, !0
	}
	
	;---------
	; DESCRIPTION:    Confirm with the user that they want to delete the current page, then do so.
	;---------
	deletePageWithConfirm() {
		; Confirmation to avoid accidental page deletion
		if(showConfirmationPopup("Are you sure you want to delete this page?", "Delete page?"))
			OneNote.deletePage()
	}
	
	;---------
	; DESCRIPTION:    Format the selected text as code using OneTastic custom styles.
	;---------
	applyCodeStyle() {
		OneNote.customStyles()
		Send, {Enter}
	}
	
	;---------
	; DESCRIPTION:    Put a link to the current page on the clipboard.
	;---------
	copyLinkToCurrentPage() {
		clipboard := "" ; Clear the clipboard so we can tell when we get the new link.
		
		; Get the link to the current paragraph.
		Send, +{F10}
		Sleep, 100
		Send, p
		Sleep, 500
		
		; If the special paste menu item was there (where the only option is "Paste (P)"), the menu is still open (because 2 "p" items) - get to the next one and actually submit it.
		if(WinActive("ahk_class Net UI Tool Window"))
			Send, p{Enter}
		
		ClipWait, 2 ; Wait up to 2s for the link to appear on the clipboard
		if(ErrorLevel = 1) { ; Timed out, didn't get a link.
			Toast.showError("Page link not added to clipboard")
			return
		}
		
		; Trim off the paragraph-specific part.
		copiedLink := RegExReplace(clipboard, "&object-id.*")
		
		; If there are two links involved (seems to happen with free version of OneNote), keep only the "onenote:" one (second line).
		if(stringContains(copiedLink, "`n")) {
			linkAry := StrSplit(copiedLink, "`n")
			For i,link in linkAry {
				if(stringContains(link, "onenote:"))
					linkToUse := link
			}
		} else {
			linkToUse := copiedLink
		}
		
		setClipboardAndToastValue(linkToUse, "link")
	}
	
	;---------
	; DESCRIPTION:    Copy the link for the text that's under the mouse (if any) to the clipboard.
	;---------
	copyLinkUnderMouse() {
		clipboard := "" ; Clear the clipboard so we can tell when we have the new link on it
		
		Click, Right
		Sleep, 100 ; Wait for menu to appear
		Send, i    ; Copy Link
		
		ClipWait, 0.5 ; Wait for half a second for the clipboard to contain the link
		if(ErrorLevel) { ; Timed out
			; If we clicked on something other than a link, the i option is "Link..." which will open the Link popup. Close it if it appeared.
			if(WinActive("Link ahk_class NUIDialog ahk_exe ONENOTE.EXE"))
				Send, {Esc}
		}
		
		toastNewClipboardValue("link target")
	}
	
	;---------
	; DESCRIPTION:    Remove the link from the text that's under the mouse (if any).
	;---------
	removeLinkUnderMouse() {
		Click, Right
		Sleep, 100 ; Wait for menu to appear
		Send, r    ; Remove link
		
		; Go ahead and finish if the right-click menu is gone, we're done.
		if(!WinActive("ahk_class Net UI Tool Window"))
			return
		
		; If the right click menu is still open (probably because it wasn't a link and therefore
		; there was no "r" option), give it a tick to close on its own, then close it.
		Sleep, 100
		if(WinActive("ahk_class Net UI Tool Window"))
			Send, {Esc}
	}
	
	;---------
	; DESCRIPTION:    For a "Do" todo page in OneNote, collapse it based on the given specifications.
	; PARAMETERS:
	;  todayOnly       (I,REQ) -  true: collapse everything that's not under the level-2 "Today" header.
	;                            false: show items under all sections.
	;  collapseToItems (I,OPT) - Set to true to collapse everything to the "item" level (under the 3
	;                            levels of headers). If false, everything will be fully expanded.
	; SIDE EFFECTS:   Puts the cursor at the beginning of the first line under the "Today" header.
	;---------
	todoPageCollapse(todayOnly, collapseToItems := false) {
		Send, ^{Home} ; Get to top-level ("Do") header so we affect the whole page
		
		if(collapseToItems)
			Send, !+4 ; Item level in all sections (level 4)
		else
			Send, !+0 ; Show all items on all levels
		
		if(todayOnly)
			Send, !+3 ; Collapse to headers under Today (which collapses headers under Today so only unfinished todos on level 4 are visible)
		
		; Get down to first item under Today header
		Sleep, 100 ; Required or else the down keystroke seems to happen before the !+3 keystrokes
		Send, {End}{Right}{End}{Right} ; End of "Do" line, right to "Today" line, end of "Today" line, right to first item line. For some reason OneNote won't take {Down} keystrokes reliably, but this seems to work instead.
	}
	
	;---------
	; DESCRIPTION:    For a "Do" todo page in OneNote, collapse it to the "Item" level (under the 3
	;                 levels of headers)
	; PARAMETERS:
	;  todayOnly (I,REQ) - true: collapse everything that's not under the level-2 "Today" header.
	;                      false: show items under all sections.
	; SIDE EFFECTS:   Puts the cursor at the beginning of the first line under the "Today" header.
	;---------
	todoPageCollapseToItems(todayOnly) {
		OneNote.doPageCollapse(todayOnly, true)
	}
	
	;---------
	; DESCRIPTION:    Make a copy of the current "Do" todo page and update it for today or a day in
	;                 the future.
	; PARAMETERS:
	;  daysInFuture (I,OPT) - The number of days in the future for the date in the title of the new
	;                         page. If not set, we will use today's date (0 days in the future).
	; SIDE EFFECTS:   Sets a background color on the old page to help distinguish.
	;---------
	todoPageCopy(daysInFuture := 0) { ; Defaults to 0 days in the future (today)
		; Change the page color before we leave, so it's noticeable if I end up there.
		Send, !w
		Send, pc
		Send, {Enter}
		
		Send, ^!m                  ; Move or copy page
		WinWaitActive, Move or Copy Pages
		Sleep, 500                 ; Wait a half second for the popup to be input-ready
		Send, {Down 5}             ; Select first section from first notebook (bypassing "Recent picks" section)
		Send, !c                   ; Copy button
		WinWaitClose, Move or Copy Pages
		
		; Wait for new page to appear.
		; Give the user a chance to wait a little longer before continuing
		; (for when OneNote takes a while to actually make the new page).
		t := new Toast()
		t.showPersistent()
		Loop {
			t.setText("Waiting for 2s, press space to keep waiting..." getDots(A_Index - 1))
			Input("T1", "{Esc}{Enter}{Space}") ; Wait for 1 second (exit immediately if Escape/Enter/Space is pressed)
			endKey := removeStringFromStart(ErrorLevel, "EndKey:")
			if(endKey = "Space")
				Continue
			
			; Break out immediately if enter/escape were pressed.
			if(endKey = "Enter" || endKey = "Escape")
				Break
			
			t.setText("Waiting for 1s, press space to keep waiting..." getDots(A_Index - 1))
			Input("T1", "{Esc}{Enter}{Space}") ; Wait for 1 second (exit immediately if Escape/Enter/Space is pressed)
			endKey := removeStringFromStart(ErrorLevel, "EndKey:")
			if(endKey = "Space")
				Continue
			
			Break
		}
		t.close()
		
		; Quit without doing anything else if they hit escape
		if(endKey = "Escape")
			return
		
		Send, ^{PgDn} ; Switch to (presumably) new page
		OneNote.makeSubpage()
		
		; Make the current page have no background color.
		Send, !w
		Send, pc
		Send, n
		
		; Update title
		Send, ^+t                                           ; Select title (to replace with new day/date)
		Sleep, 1000                                         ; Wait for selection to take
		Send, % OneNote.todoPageGenerateTitle(daysInFuture) ; Send title
		Send, ^+t                                           ; Select title again in case you want a different date.
	}
	
	;---------
	; DESCRIPTION:    Add the "usual" todos that are needed for every Saturday.
	;---------
	todoAddUsualSat() {
		items := []
		items.push("Dishes from week")
		items.push("Wash laundry")
		items.push("Dry laundry")
		items.push("Clean off desk")
		items.push("Pull to-dos from specific sections below")
		OneNote.todoAddItems(items)
	}
	
	;---------
	; DESCRIPTION:    Add the "usual" todos that are needed for every Saturday.
	;---------
	todoAddUsualSun() {
		items := []
		items.push("Review/type Ninpo notes")
		items.push("Fold laundry")
		items.push("Roomba")
		items.push("Dishes from weekend")
		items.push("Dishes from dinner")
		items.push("Trash, recycling out")
		items.push("Meal planning")
		items.push("Order/obtain groceries")
		items.push("Pull to-dos from specific sections below")
		OneNote.todoAddItems(items)
	}
	
	;---------
	; DESCRIPTION:    When an objects table is copied over from an emc2summary page, it has a lot of formatting quirks we don't want - this removes them.
	;---------
	cleanUpEMC2SummaryTableFormatting() {
		; Unhide table borders
		Send, {AppsKey} ; Open right-click menu
		Send, a         ; Table menu
		Send, h         ; (Un)hide borders
		Send, {Enter}   ; Multiple with h, so enter to submit it
		
		; Normalize text, indent table (table stays selected through all of these)
		Send, ^{a 4}    ; Select the whole table
		Send, ^+n       ; Normal text (get rid of underlines, text colors, etc.)
		Send, {Tab}     ; Indent the table once
		
		; Remove shading
		Send, {AppsKey} ; Open right-click menu
		Send, a         ; Table menu
		Send, {Up 5}    ; Shading option
		Send, {Right}   ; Open
		Send, n         ; No color
	}
	
	;---------
	; DESCRIPTION:    The dev structure in question has section headers with an INI/ID, and a space
	;                 for an edit link. Add links to both the INI/ID (web) and the edit spot.
	;---------
	linkDevStructureSectionTitle() {
		waitForHotkeyRelease()
		
		OneNote.selectLine()
		lineText := getSelectedText()
		if(lineText = "" || lineText = "`r`n") ; Selecting the whole line in OneNote gets us the newline, so treat just a newline as an empty case as well.
			return
		
		linkText   := getStringAfterStr(lineText, " - ")
		recordText := getStringBeforeStr(linkText, " (")
		editText   := getFirstStringBetweenStr(linkText, "(", ")")
		
		ao := new ActionObjectEMC2(recordText)
		; DEBUG.popup("Line",lineText, "Record text",recordText, "Edit text",editText, "ao.ini",ao.ini, "ao.id",ao.id)
		
		selectTextWithinSelection(recordText)
		ao.linkSelectedTextWeb("Failed to add EMC2 object web link")
		
		OneNote.selectLine() ; Re-select whole line so we can use selectTextWithinSelection() again
		selectTextWithinSelection(editText)
		ao.linkSelectedTextEdit("Failed to add EMC2 object edit link")
	}
	
	;---------
	; DESCRIPTION:    Select the current line and link the given EMC2 object (described by INI/ID).
	; PARAMETERS:
	;  ini (I,REQ) - INI of the object to link
	;  id  (I,REQ) - ID of the object to link
	;---------
	linkEMC2ObjectInLine(ini, id) {
		selectCurrentLine() ; Select whole line, but avoid the extra indentation and newline that comes with ^a.
		selectTextWithinSelection(ini " " id) ; Select the INI and ID for linking
		
		ao := new ActionObjectEMC2(id, ini)
		ao.linkSelectedTextWeb("Failed to link EMC2 object text")
		
		Send, {End}
	}
	
	
; ==============================
; == Private ===================
; ==============================
	;---------
	; DESCRIPTION:    Figure out and return what title to use for a OneNote Do page.
	; PARAMETERS:
	;  daysInFuture (I,OPT) - How many days into the future this title should be (1 for tomorrow, etc.).
	;                         Defaults to 0 (today).
	; RETURNS:        The title to use for the new OneNote Do page.
	;---------
	todoPageGenerateTitle(daysInFuture := 0) {
		startDateTime := A_Now
		startDateTime += daysInFuture, Days
		
		; Do pages at work are always daily
		if(MainConfig.machineIsEpicLaptop)
			return FormatTime(startDateTime, "M/d`, dddd")
		
		; Otherwise, it varies by day of the week
		if(MainConfig.machineIsHomeDesktop || MainConfig.machineIsHomeLaptop) {
			dayOfWeek := FormatTime(startDateTime, "Wday") ; Day of the week, 1 (Sunday) to 7 (Saturday)
			
			; Weekend pages at home are daily
			if((dayOfWeek = 1) || (dayOfWeek = 7)) ; Sunday or Saturday
				return FormatTime(startDateTime, "M/d`, dddd")
			
			; Weekdays are weekly
			; Calculate datetimes for Monday and Friday to use, even if it's not currently Monday.
			mondayDateTime := startDateTime
			mondayDateTime += -(dayOfWeek - 2), days ; If it's not Monday, get back to Monday's date.
			mondayTitle := FormatTime(mondayDateTime, "M/d`, dddd")
			
			fridayDateTime := mondayDateTime
			fridayDateTime += 4, days
			fridayTitle := FormatTime(fridayDateTime, "M/d`, dddd")
			
			; DEBUG.popup("A_Now",A_Now, "startDateTime",startDateTime, "mondayDateTime",mondayDateTime, "mondayTitle",mondayTitle, "fridayDateTime",fridayDateTime, "fridayTitle",fridayTitle)
			return mondayTitle " - " fridayTitle
		}
	}
	
	;---------
	; DESCRIPTION:    Send the given items with a to-do tag (bound to Ctrl+1).
	; PARAMETERS:
	;  items (I,REQ) - Simple array of todo items to send.
	;---------
	todoAddItems(items) {
		Send, ^0 ; Clear current tag (so we're definitely adding the to-do tag, not checking it off)
		Send, ^1 ; To-do tag
		
		For i,item in items {
			if(i > 1)
				Send, {Enter}
			
			Send, % item
		}
	}
}
