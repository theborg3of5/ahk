; OneNote hotkeys.
#If Config.isWindowActive("OneNote")
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
	
	^`::Send, ^0 ; Since we're using ^0 to set zoom to 100% below, add a replacement hotkey for clearing all tags.
	^!n::Send, ^+n ; 'Normal' text formatting, as ^+n is already being used for new subpage.
	^7::Send, ^6 ; Make ^7 do the same tag (Done green check) as ^6.
	^+8::SendRaw, % "*" Config.private["INITIALS"] " " FormatTime(, "MM/yy") ; Insert contact comment
	^!4::Send, ^!5 ; Use Header 5 instead of Header 4 - Header 4 is just an italicized Header 3, which isn't distinct enough for me.
	
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
	!c::      OneNote.copyLinkToCurrentPage()
	!#c::     OneNote.copyTitleLinkToCurrentPage()
	^RButton::OneNote.copyLinkUnderMouse()
	^MButton::OneNote.removeLinkUnderMouse()
	
	; Todo page handling
	^t::       OneNoteTodoPage.collapseToTodayItems()     ; Today only, item-level
	^+t::      OneNoteTodoPage.collapseToAllItems()       ; All sections, item-level
	^!t::      OneNoteTodoPage.collapseToTodayAll()       ; Today only, fully expanded
	^+m::      OneNoteTodoPage.copyForToday()             ; New page for today
	^+#m::     OneNoteTodoPage.copyForTomorrow()          ; New page for tomorrow
	:*X:.todo::OneNoteTodoPage.addRecurringForToday()     ; Add recurring todos for today
	:*X:.ttodo::OneNoteTodoPage.addRecurringForTomorrow() ; Add recurring todos for tomorrow

	; Clean up a table from an emc2summary page
	^+f::OneNote.cleanUpEMC2SummaryTableFormatting()
	
	; Update links for a dev structure section header
	!+#n::OneNote.linkDevStructureSectionTitle()
#If
	
class OneNote {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Select the current line and link the given EMC2 object (described by INI/ID).
	; PARAMETERS:
	;  ini (I,REQ) - INI of the object to link
	;  id  (I,REQ) - ID of the object to link
	;---------
	linkEMC2ObjectInLine(ini, id) {
		SelectLib.selectCurrentLine() ; Select whole line, but avoid the extra indentation and newline that comes with ^a.
		SelectLib.selectTextWithinSelection(ini " " id) ; Select the INI and ID for linking
		
		new ActionObjectEMC2(id, ini).linkSelectedTextWeb("Failed to link EMC2 object text")
		
		Send, {End}
	}
	
	
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Scroll left/right in the OneNote window (assuming it's under the mouse)
	;---------
	scrollLeft() {
		MouseGetPos, , , winId, controlId, 1
		SendMessage, MicrosoftLib.Message_HorizScroll, MicrosoftLib.ScrollBar_Left, , % controlId, % "ahk_id " winId
	}
	scrollRight() {
		MouseGetPos, , , winId, controlId, 1
		SendMessage, MicrosoftLib.Message_HorizScroll, MicrosoftLib.ScrollBar_Right, , % controlId, % "ahk_id " winId
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
		if(GuiLib.showConfirmationPopup("Are you sure you want to delete this page?", "Delete page?"))
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
		ClipboardLib.setAndToast(OneNote.getLinkToCurrentPage(), "link")
	}
	
	;---------
	; DESCRIPTION:    Copy the current page's title and link to the clipboard.
	;---------
	copyTitleLinkToCurrentPage() {
		link := OneNote.getLinkToCurrentPage()
		title := OneNote.getPageTitle()
		
		ClipboardLib.setAndToast(title "`n" link, "page title + link")
	}
	
	;---------
	; DESCRIPTION:    Copy the link for the text that's under the mouse (if any) to the clipboard.
	;---------
	copyLinkUnderMouse() {
		copyLinkFunction := ObjBindMethod(OneNote, "doCopyLinkUnderMouse")
		if(!ClipboardLib.copyWithFunction(copyLinkFunction)) {
			; If we clicked on something other than a link, the i option is "Link..." which will open the Link popup. Close it if it appeared.
			if(WinActive("Link ahk_class NUIDialog ahk_exe ONENOTE.EXE"))
				Send, {Esc}
		}
		
		ClipboardLib.toastNewValue("link target")
	}
	
	;---------
	; DESCRIPTION:    Remove the link from the text that's under the mouse (if any).
	;---------
	removeLinkUnderMouse() {
		Click, Right
		Sleep, 100 ; Wait for menu to appear
		Send, r    ; Remove link
		
		; Go ahead and finish if the right-click menu is gone, we're done.
		if(!WinActive(OneNote.TitleString_RightClickMenu))
			return
		
		; If the right click menu is still open (probably because it wasn't a link and therefore
		; there was no "r" option), give it a tick to close on its own, then close it.
		Sleep, 100
		if(WinActive(OneNote.TitleString_RightClickMenu))
			Send, {Esc}
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
		HotkeyLib.waitForRelease()
		
		OneNote.selectLine()
		lineText := SelectLib.getText()
		if(lineText = "" || lineText = "`r`n") ; Selecting the whole line in OneNote gets us the newline, so treat just a newline as an empty case as well.
			return
		
		linkText   := lineText.afterString(" - ")
		recordText := linkText.beforeString(" (")
		editText   := linkText.firstBetweenStrings("(", ")")
		
		ao := new ActionObjectEMC2(recordText)
		; Debug.popup("Line",lineText, "Record text",recordText, "Edit text",editText, "ao.ini",ao.ini, "ao.id",ao.id)
		
		SelectLib.selectTextWithinSelection(recordText)
		ao.linkSelectedTextWeb("Failed to add EMC2 object web link")
		
		OneNote.selectLine() ; Re-select whole line so we can use SelectLib.selectTextWithinSelection() again
		SelectLib.selectTextWithinSelection(editText)
		ao.linkSelectedTextEdit("Failed to add EMC2 object edit link")
	}
	
	
	; #PRIVATE#
	
	static TitleString_RightClickMenu := "ahk_class Net UI Tool Window"
	
	;---------
	; DESCRIPTION:    Get a link to the current page
	; RETURNS:        The simple link to the current page, via OneNote (not online link).
	;---------
	getLinkToCurrentPage() {
		copiedLink := OneNote.getLinkToCurrentParagraph()
		if(copiedLink = "") {
			new ErrorToast("Could not get paragraph link on clipboard").showMedium()
			return
		}
		
		; Trim off the paragraph-specific part.
		copiedLink := copiedLink.removeRegEx("&object-id.*")
		
		; If there are two links involved (seems to happen with free version of OneNote), keep only the "onenote:" one (second line).
		if(copiedLink.contains("`n")) {
			linkAry := copiedLink.split("`n")
			For i,link in linkAry {
				if(link.contains("onenote:"))
					linkToUse := link
			}
		} else {
			linkToUse := copiedLink
		}
		
		return linkToUse
	}
	
	;---------
	; DESCRIPTION:    Get the title of the current page.
	; RETURNS:        The title of the current page.
	;---------
	getPageTitle() {
		Send, ^+a                             ; Select page tab
		pageContent := SelectLib.getText() ; Copy entire page contents
		Send, {Escape}                        ; Get back to the editing area
		return pageContent.firstLine()        ; Title is the first line of the content
	}
	
	;---------
	; DESCRIPTION:    Get the link to the current paragraph to the clipboard.
	; RETURNS:        The link to the current paragraph.
	;---------
	getLinkToCurrentParagraph() {
		copyFunction := ObjBindMethod(OneNote, "copyLinkToCurrentParagraph")
		return ClipboardLib.getWithFunction(copyFunction)
	}
	
	;---------
	; DESCRIPTION:    Copy a link to the current paragraph to the clipboard.
	;---------
	copyLinkToCurrentParagraph() {
		Send, +{F10}
		WinWaitActive, % OneNote.TitleString_RightClickMenu
		Send, p
		WinWaitNotActive, % OneNote.TitleString_RightClickMenu, , 0.5
		
		; Special handling: if we didn't get anything, it might be because the special paste menu item was there (where the only option is "Paste (P)").
		; If that's the case, try getting to the second "p" option and submit it.
		if(WinActive(OneNote.TitleString_RightClickMenu))
			Send, p{Enter}
	}
	
	;---------
	; DESCRIPTION:    Copy the link target under the mouse to the clipboard.
	;---------
	doCopyLinkUnderMouse() {
		Click, Right
		WinWaitActive, % OneNote.TitleString_RightClickMenu
		Send, i ; Copy Link
	}
	
	;---------
	; DESCRIPTION:    Insert a blank line on the current line and put the cursor on it.
	;---------
	insertBlankLine() {
		Send, {Home}  ; Get to start of line
		Send, {Enter} ; New line
		Send, {Left}  ; Get back up to new blank line
	}
	; #END#
}


; A helper class for all of the logic that goes into my OneNote organizational system.
class OneNoteTodoPage {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Collapse the todo page to different levels.
	; SIDE EFFECTS:   Puts the cursor at the beginning of the first line under the "Today" header.
	;---------
	collapseToTodayItems() {
		OneNoteTodoPage.collapse(true)
	}
	collapseToAllItems() {
		OneNoteTodoPage.collapse(false)
	}
	collapseToTodayAll() {
		OneNoteTodoPage.collapse(true, true)
	}
	
	;---------
	; DESCRIPTION:    Make a copy of the current todo page and update it to be for today.
	;---------
	copyForToday() {
		OneNoteTodoPage.copy(A_Now)
	}
	
	;---------
	; DESCRIPTION:    Make a copy of the current todo page and update it to be for tomorrow.
	;---------
	copyForTomorrow() {
		instant := A_Now
		instant += 1, Days
		OneNoteTodoPage.copy(instant)
	}
	
	;---------
	; DESCRIPTION:    Add the recurring todo items (from oneNoteRecurringTodos.tl) that match
	;                 today's date.
	;---------
	addRecurringForToday() {
		OneNoteTodoPage.sendRecurringTodos(A_Now)
	}
	
	;---------
	; DESCRIPTION:    Add the recurring todo items (from oneNoteRecurringTodos.tl) that match
	;                 tomorrow's date.
	;---------
	addRecurringForTomorrow() {
		instant := A_Now
		instant += 1, Days
		OneNoteTodoPage.sendRecurringTodos(instant)
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    For a "Do" todo page in OneNote, collapse it based on the given specifications.
	; PARAMETERS:
	;  todayOnly (I,REQ) - true: collapse everything that's not under the level-2 "Today" header.
	;                      false: show items under all sections.
	;  expandAll (I,OPT) - Set to true to expand everything (while still respecting todayOnly setting).
	;                      Default is to collapse everything to the "item" level (under the 3 levels
	;                      of headers).
	; SIDE EFFECTS:   Puts the cursor at the beginning of the first line under the "Today" header.
	;---------
	collapse(todayOnly, expandAll := false) {
		Send, ^{Home} ; Get to top-level ("Do") header so we affect the whole page
		
		if(expandAll)
			Send, !+0 ; Show all items on all levels
		else
			Send, !+4 ; Item level in all sections (level 4)
		
		if(todayOnly)
			Send, !+3 ; Collapse to headers under Today (which collapses headers under Today so only todos on level 4 are visible)
		
		; Get down to first item under Today header
		Send, {End}{Right}{End}{Right} ; End of "Do" line, right to "Today" line, end of "Today" line, right to first item line. For some reason OneNote won't take {Down} keystrokes reliably, but this seems to work instead.
	}
	
	;---------
	; DESCRIPTION:    Make a copy of the current "Do" todo page and update it for the given instant.
	; PARAMETERS:
	;  instant (I,REQ) - The instant to update the new page to match.
	; SIDE EFFECTS:   Sets a background color on the old page to help distinguish.
	;---------
	copy(instant) {
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
		t.show()
		Loop {
			t.setText("Waiting for 2s, press space to keep waiting..." StringLib.getDots(A_Index - 1))
			Input("T1", "{Esc}{Enter}{Space}") ; Wait for 1 second (exit immediately if Escape/Enter/Space is pressed)
			endKey := ErrorLevel.removeFromStart("EndKey:")
			if(endKey = "Space")
				Continue
			
			; Break out immediately if enter/escape were pressed.
			if(endKey = "Enter" || endKey = "Escape")
				Break
			
			t.setText("Waiting for 1s, press space to keep waiting..." StringLib.getDots(A_Index - 1))
			Input("T1", "{Esc}{Enter}{Space}") ; Wait for 1 second (exit immediately if Escape/Enter/Space is pressed)
			endKey := ErrorLevel.removeFromStart("EndKey:")
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
		Send, ^+t                                      ; Select title (to replace with new day/date)
		Sleep, 1000                                    ; Wait for selection to take
		Send, % OneNoteTodoPage.generateTitle(instant) ; Send title
		
		OneNoteTodoPage.collapseToTodayItems() ; Also puts us on the first line of today's todos
		
		; Insert any applicable recurring todos
		OneNoteTodoPage.sendRecurringTodos(instant)
	}
	
	;---------
	; DESCRIPTION:    Figure out and return what title to use for a OneNote Do page.
	; PARAMETERS:
	;  instant (I,REQ) - Instant to update title to match.
	; RETURNS:        The title to use for the new OneNote Do page. If it's a weekend or we're not
	;                 in a home context, it will simply be the formatted date. If we're in a home
	;                 context and it's a weekday, it will be a date range from Monday to Friday.
	;---------
	generateTitle(instant) {
		; Do pages at work are always daily
		if(Config.contextIsWork)
			return FormatTime(instant, "M/d`, dddd")
		
		; Otherwise, it varies by day of the week
		if(Config.contextIsHome) {
			dayOfWeek := FormatTime(instant, "Wday") ; Day of the week, 1 (Sunday) to 7 (Saturday)
			
			; Weekend pages at home are daily
			if((dayOfWeek = 1) || (dayOfWeek = 7)) ; Sunday or Saturday
				return FormatTime(instant, "M/d`, dddd")
			
			; Weekdays are weekly
			; Calculate datetimes for Monday and Friday to use, even if it's not currently Monday.
			mondayDateTime := instant
			mondayDateTime += -(dayOfWeek - 2), days ; If it's not Monday, get back to Monday's date.
			mondayTitle := FormatTime(mondayDateTime, "M/d`, dddd")
			
			fridayDateTime := mondayDateTime
			fridayDateTime += 4, days
			fridayTitle := FormatTime(fridayDateTime, "M/d`, dddd")
			
			; Debug.popup("A_Now",A_Now, "instant",instant, "mondayDateTime",mondayDateTime, "mondayTitle",mondayTitle, "fridayDateTime",fridayDateTime, "fridayTitle",fridayTitle)
			return mondayTitle " - " fridayTitle
		}
	}
	
	;---------
	; DESCRIPTION:    Insert the todos for the date of the provided timestamp.
	; PARAMETERS:
	;  instant (I,REQ) - The instant to insert recurring todos for.
	; SIDE EFFECTS:   Inserts a new line for the todos if you're on a non-blank line to start.
	; NOTES:          The inserted todos may not only be for the day of the provided instant - in
	;                 certain contexts, we will also check the surrounding weekdays (see
	;                 .getInstantsToCheck for details).
	;---------
	sendRecurringTodos(instant) {
		; Get array of instants to check.
		instantsAry := OneNoteTodoPage.getInstantsToCheck(instant)
		
		; Read in table of todos to find which apply
		table := new TableList("oneNoteRecurringTodos.tl").getTable()
		matchingTodos := []
		For _,todoAry in table {
			todo := new OneNoteRecurringTodo(todoAry)
			For _,instant in instantsAry {
				if(!todo.matchesInstant(instant))
					Continue
				
				; Debug.popup("Matched todo","", "todo",todo)
				matchingTodos.push(todo.title)
			}
		}
		
		; Bail if there's nothing to insert.
		if(DataLib.isNullOrEmpty(matchingTodos))
			return
			
		; Check whether we're already on a blank line or not.
		Send, {Home} ; Start of line
		Send, {Shift Down}{End}{Shift Up} ; Select to end of line
		if(SelectLib.getFirstLine() != "")
			OneNote.insertBlankLine()
		
		; Debug.popup("matchingTodos",matchingTodos)
		OneNoteTodoPage.sendItems(matchingTodos)
	}
	
	;---------
	; DESCRIPTION:    Determine which days we should find recurring todo items for, based on the
	;                 context (work or home) and whether it's a weekday or weekend.
	; PARAMETERS:
	;  instant (I,REQ) - The instant to evaluate
	; RETURNS:        If (and only if) it's a weekday and we're in a home context, we'll return an
	;                 array for all weekdays in the current week (from Monday to Friday). Otherwise,
	;                 we'll return an array with just the provided instant in it.
	;---------
	getInstantsToCheck(instant) {
		; Doesn't apply at work - no recurring todos
		
		; At home, it varies by day of the week
		if(Config.contextIsHome) {
			dayOfWeek := FormatTime(instant, "Wday") ; Day of the week, 1 (Sunday) to 7 (Saturday)
			
			; Weekend pages at home are daily
			if((dayOfWeek = 1) || (dayOfWeek = 7)) ; Sunday or Saturday
				return [instant]
			
			; Weekdays are weekly from Monday to Friday
			instant += -(dayOfWeek - 2), Days
			instantsAry := [instant] ; Instant for Monday
			Loop, 4 {
				instant += 1, Days
				instantsAry.push(instant)
			}
			
			return instantsAry
		}
	}
	
	;---------
	; DESCRIPTION:    Send the given items with a to-do tag (bound to Ctrl+1).
	; PARAMETERS:
	;  items (I,REQ) - Simple array of todo items to send.
	;---------
	sendItems(items) {
		Send, ^0 ; Clear current tag (so we're definitely adding the to-do tag, not checking it off)
		Send, ^1 ; To-do tag
		
		For i,item in items {
			if(i > 1)
				Send, {Enter}
			
			Send, % item
		}
	}
	; #END#
}


/* 
	This class represents a single recurring todo item, along with the timeframe filtering info that goes with it.
*/
class OneNoteRecurringTodo {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    Create a new recurring todo object.
	; PARAMETERS:
	;  todoAry (I,REQ) - An array with info about the object. Format:
	;                       Required subscripts:
	;                          ["TITLE"] - Title of the todo item. This is the only required subscript.
	;                       Filters: these are optional, and if left blank, that part of the date
	;                       will not be considered when evaluating this todo for matches.
	;                          ["DATE"]             - The numeric date (or "LAST" for the last day
	;                                                 of the month) that the todo should be included on.
	;                          ["DAY_ABBREV"]       - The all-caps abbreviation for the day of the
	;                                                 week that this todo should match.
	;                          ["MONTH_ABBREV"]     - The all-caps abbreviation for the month that
	;                                                 this todo should match.
	;                          ["NUM_DAY_OF_MONTH"] - The number day of the month (i.e. DAY_ABBREV=WED
	;                                                 and NUM_DAY_OF_MONTH=2 for 2nd Wednesday of the month).
	;---------
	__New(todoAry) {
		this.title         := todoAry["TITLE"]
		this.date          := todoAry["DATE"]
		this.dayAbbrev     := todoAry["DAY_ABBREV"]
		this.monthAbbrev   := todoAry["MONTH_ABBREV"]
		this.numDayOfMonth := todoAry["NUM_DAY_OF_MONTH"]
	}
	
	;---------
	; DESCRIPTION:    Check whether this todo matches the provided instant, based on its filters.
	; PARAMETERS:
	;  instant (I,REQ) - Instant to check for a match against this todo's filters.
	; RETURNS:        true if it matches, false otherwise.
	;---------
	matchesInstant(instant) {
		if(instant = "")
			return false
		
		if(!this.instantMatchesDate(instant))
			return false
		if(!this.instantMatchesDayAbbrev(instant))
			return false
		if(!this.instantMatchesMonthAbbrev(instant))
			return false
		if(!this.instantMatchesNumDayOfMonth(instant))
			return false
		
		return true
	}
	
	
	; #PRIVATE#
	
	title         := "" ; Title for the todo item
	date          := "" ; Numeric date or "LAST"
	dayAbbrev     := "" ; All-caps abbreviation for the day of the week
	monthAbbrev   := "" ; All-caps abbreviation for the month
	numDayOfMonth := "" ; For the day of the week, which number that is within the month (i.e. 2 for 2nd Wednesday in the month).
	
	
	;---------
	; DESCRIPTION:    Check whether the provided instant matches the date/day/month/numDayOfMonth
	;                 filters for this todo item.
	; PARAMETERS:
	;  instant (I,REQ) - Instant to check.
	; RETURNS:        true if it matches the respective filter (or that filter isn't set), false
	;                 otherwise.
	;---------
	instantMatchesDate(instant) {
		if(this.date = "")
			return true
		
		instDate := FormatTime(instant, "d") ; Date, no leading 0
		if(this.date = instDate)
			return true
		
		; Special case for last day of the month
		if(this.date = "LAST") {
			monthNum := FormatTime(instant, "M") ; Month number, no leading 0
			year     := FormatTime(instant, "yyyy")
			if(instDate = DateTimeLib.getLastDateOfMonth(monthNum, year))
				return true
		}
		
		return false
	}
	instantMatchesDayAbbrev(instant) {
		if(this.dayAbbrev = "")
			return true
			
		instDayAbbrev := StringUpper(FormatTime(instant, "ddd")) ; Day of week abbreviation, all caps
		if(this.dayAbbrev = instDayAbbrev)
			return true
		
		return false
	}
	instantMatchesMonthAbbrev(instant) {
		if(this.monthAbbrev = "")
			return true
		
		instMonthAbbrev := StringUpper(FormatTime(instant, "MMM")) ; Month abbreviation
		if(this.monthAbbrev = instMonthAbbrev)
			return true
		
		return false
	}
	instantMatchesNumDayOfMonth(instant) {
		if(this.numDayOfMonth = "")
			return true
		
		instDate := FormatTime(instant, "d") ; Date, no leading 0
		instNumDayOfMonth := ((instDate - 1) // 7) + 1 ; -1 to get to 0-base (otherwise day 6 and 7 are in different week numbers), +1 to get back after
		if(this.numDayOfMonth = instNumDayOfMonth)
			return true
		
		return false
	}
	; #END#
}
