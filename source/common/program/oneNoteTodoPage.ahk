#Include oneNoteRecurringTodo.ahk

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
		Send, Do                   ; Search for "Do" notebook, should automatically select first result (which should be the one we want)
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
		; (Doesn't apply at work - no recurring todos)
		
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
			
			SendRaw, % item
		}
	}
	; #END#
}
