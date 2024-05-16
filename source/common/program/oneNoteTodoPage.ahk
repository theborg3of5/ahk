#Include oneNoteRecurringTodo.ahk

; A helper class for all of the logic that goes into my OneNote organizational system.
class OneNoteTodoPage {
	;region ------------------------------ INTERNAL ------------------------------
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
		OneNoteTodoPage.copy(EnvAdd(A_Now, 1, "Days"))
	}
	
	;---------
	; DESCRIPTION:    Show a popup with the recurring todo items from a date range in the past or future.
	; SIDE EFFECTS:   Prompts the user for the date range to view todos from.
	;---------
	peekOtherTodos() {
		startDate := ""
		endDate   := ""
		this.promptOtherDateRange("Peek at todo items for date range", startDate, endDate)
		todosByDate := this.getTodosForDateRange(startDate, endDate)
		
		tt := new TextTable("Recurring Todos Peek")
		tt.addRow("Date range:", FormatTime(startDate, "ddd M/d") " - " FormatTime(endDate, "ddd M/d"))
		For instant,todos in todosByDate {
			tasksTable := new TextTable().setBorderType(TextTable.BorderType_Line)
			For _,todo in todos
				tasksTable.addRow(todo)
			
			tt.addRow(FormatTime(instant, "ddd M/d") ":", tasksTable.getText())
		}
		
		new TextPopup(tt).show()
	}
	
	;---------
	; DESCRIPTION:    Insert todos from a date range in the past or future. Useful for missed days.
	; SIDE EFFECTS:   Prompts the user for the date range to add todos from.
	;---------
	insertOtherTodos() {
		startDate := ""
		endDate   := ""
		this.promptOtherDateRange("Insert todo items for date range", startDate, endDate)
		
		todosByDate := this.getTodosForDateRange(startDate, endDate)
		
		; Check whether we're already on a blank line or not.
		Send, {Home} ; Start of line
		Send, {Shift Down}{End}{Shift Up} ; Select to end of line
		if(SelectLib.getFirstLine() != "")
			OneNote.insertBlankLine()
		
		todoItems := DataLib.flattenObjectToArray(todosByDate)
		OneNoteTodoPage.sendItems(todoItems)
	}
	
	;---------
	; DESCRIPTION:    Send the various sub-todos I add under most dev items.
	;---------
	insertDevTodos() {
		todos := []
		todos.push({tag:1, text:"Submit design"})
		todos.push({tag:1, text:"Dev comp"})
		todos.push({tag:5, text:"Design review"})
		todos.push({tag:5, text:"PQA1"})
		todos.push({tag:1, text:"Move to Stage 1"})
		todos.push({tag:5, text:"QA1"})
		todos.push({tag:5, text:"PQA2"})
		todos.push({tag:1, text:"Move to Final"})
		todos.push({tag:5, text:"QA2"})
		
		OneNoteTodoPage.sendItemsWithTags(todos)
	}

	;---------
	; DESCRIPTION:    Send the various sub-todos I add under most dev project items.
	;---------
	insertDevPRJTodos() {
		todos := []
		todos.push({tag:1, text:"Submit design"})
		todos.push({tag:1, text:"Dev comp"})
		todos.push({tag:5, text:"Design review"})
		todos.push({tag:5, text:"PQA1"})
		todos.push({tag:1, text:"Move to Stage 1"})
		todos.push({tag:5, text:"QA1"})
		todos.push({tag:5, text:"PQA2"})
		todos.push({tag:5, text:"Readiness"})
		todos.push({tag:1, text:"Move to Final"})
		todos.push({tag:5, text:"QA2"})
		
		OneNoteTodoPage.sendItemsWithTags(todos)
	}
	
	;---------
	; DESCRIPTION:    Send the various sub-todos I add under most dev SU items.
	;---------
	insertDevSUTodos() {
		todos := []
		todos.push({tag:5, text:"Source logs to Stage 1"})
		todos.push({tag:1, text:"Dev comp"})
		todos.push({tag:5, text:"PQA1"})
		todos.push({tag:1, text:"Move to Stage 1"})
		todos.push({tag:5, text:"QA1"})
		todos.push({tag:5, text:"PQA2"})
		todos.push({tag:1, text:"Move to Final"})
		todos.push({tag:5, text:"QA2"})
		
		OneNoteTodoPage.sendItemsWithTags(todos)
	}
	
	;---------
	; DESCRIPTION:    Send the various sub-todos I add under most PQA items.
	;---------
	insertPQATodos() {
		this.sendItems(["Review", "Test"])
	}
	;endregion ------------------------------ INTERNAL ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
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
		
		this.cursorToFirstTodayItem()
	}
	
	;---------
	; DESCRIPTION:    Get to the first item under the second-level "Today" header.
	;---------
	cursorToFirstTodayItem() {
		Send, ^{Home} ; Top-level ("Do") header
		
		; For some reason OneNote won't take {Down} keystrokes reliably, but getting to the end of the line
		; and using {Right} seems to work instead.
		Send, {End}{Right} ; End of "Do" line, right to following "Today" line
		Send, {End}{Right} ; End of "Today" line, right to following item line
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
		
		; Collapse to line level before I leave so it's easier to find stuff when looking back.
		OneNoteTodoPage.collapseToAllItems()
		
		Send, ^!m                  ; Move or copy page
		WinWaitActive, Move or Copy Pages
		Sleep, 500                 ; Wait a half second for the popup to be input-ready
		Send, Do                   ; Search for "Do" notebook, should automatically select first result (which should be the one we want)
		Send, !c                   ; Copy button
		WinWaitClose, Move or Copy Pages
		
		; Wait for new page to appear.
		; Give the user a chance to wait a little longer before continuing
		; (for when OneNote takes a while to actually make the new page).
		t := new Toast().show()
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
		
		; Make the current page have no background color.
		Send, !w
		Send, pc
		Send, n
		
		; Update title
		Send, ^+t                                      ; Select title (to replace with new day/date)
		Sleep, 1000                                    ; Wait for selection to take
		Send, % OneNoteTodoPage.generateTitle(instant) ; Send title
		
		; Insert any applicable recurring todos
		this.cursorToFirstTodayItem()
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
			mondayDateTime := EnvAdd(instant, -(dayOfWeek - 2), "Days") ; If it's not Monday, get back to Monday's date.
			mondayTitle := FormatTime(mondayDateTime, "M/d`, dddd")
			
			fridayDateTime := EnvAdd(mondayDateTime, 4, "Days")
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
	;                 .getRelatedDateRange for details).
	;---------
	sendRecurringTodos(instant) {
		; Expand the range if needed
		this.getRelatedDateRange(instant, startDate, endDate)
		
		; Get the matching todos
		todosByDate := this.getTodosForDateRange(startDate, endDate)
		; Debug.popup("todosByDate",todosByDate)
		
		; Bail if there's nothing to insert.
		if(DataLib.isNullOrEmpty(todosByDate))
			return
			
		; Check whether we're already on a blank line or not.
		Send, {Home} ; Start of line
		Send, {Shift Down}{End}{Shift Up} ; Select to end of line
		if(SelectLib.getFirstLine() != "")
			OneNote.insertBlankLine()
		
		todoItems := DataLib.flattenObjectToArray(todosByDate)
		OneNoteTodoPage.sendItems(todoItems)
	}
	
	;---------
	; DESCRIPTION:    Expand the date range that we're considering to include related dates - for example, at home there's
	;                 only one todo page per 5 consecutive weekdays, all bundled together.
	; PARAMETERS:
	;  instant   (I,REQ) - The instant to evaluate
	;  startDate (O,REQ) - The start of the range that includes related dates
	;  endDate   (O,REQ) - The end of the range that includes related dates
	;---------
	getRelatedDateRange(instant, ByRef startDate, ByRef endDate) {
		; Start out with a 1-day range of our given instant.
		startDate := instant
		endDate   := instant
		
		; At work, nothing special.
		if(Config.contextIsWork)
			return
		
		; At home, it varies by day of the week
		if(Config.contextIsHome) {
			dayOfWeek := FormatTime(instant, "Wday") ; Day of the week, 1 (Sunday) to 7 (Saturday)
			
			; Weekend pages at home are daily - no change.
			if((dayOfWeek = 1) || (dayOfWeek = 7)) ; Sunday or Saturday
				return
			
			; Weekdays are one weekly page from Monday to Friday.
			startDate := EnvAdd(instant, -(dayOfWeek - 2), "Days") ; Back to Monday
			endDate   := EnvAdd(startDate, 4,              "Days") ; Out to Friday
			return
		}
	}
	
	;---------
	; DESCRIPTION:    Generate a 2D array of recurring todo items, divided up by date, for the given date range.
	; PARAMETERS:
	;  startDate (I,REQ) - Start date instant (inclusive)
	;  endDate   (I,REQ) - End date instant (inclusive)
	; RETURNS:        2D array of todo titles. Format:
	;                   todosByDate[dateInstant][ln] := todoTitle
	;---------
	getTodosForDateRange(startDate, endDate) {
		if(!Config.contextIsHome) ; These todos are only for at home, not work.
			return
		
		table := new TableList("oneNoteRecurringTodos.tl").getTable()
		todosByDate := {}
		For _,todoAry in table {
			todo := new OneNoteRecurringTodo(todoAry)
			
			; Loop through date range and check the todo against each
			instant := startDate
			while(instant <= endDate) {
				if(todo.matchesInstant(instant)) {
					if(!todosByDate[instant])
						todosByDate[instant] := []
					
					todosByDate[instant].push(todo.title)
				}
				
				instant += 1, Days
			}
		}
		
		return todosByDate
	}
	
	;---------
	; DESCRIPTION:    Ask the user for an edge date (where the new range will be between today and the edge date).
	; PARAMETERS:
	;  title     (I,REQ) - Title of the popup that will be shown asking the user for their edge date (the one besides today).
	;  startDate (O,REQ) - Start date of the chosen range
	;  endDate   (O,REQ) - End date of the chosen range
	; NOTES:          Today is never included in the range - so it will either end yesterday (if the edge date is in the
	;                 past) or start tomorrow (if the edge date is in the future).
	;---------
	promptOtherDateRange(title, ByRef startDate, ByRef endDate) {
		dateString := InputBox(title, "Enter a relative date string to use all todos between today (exclusive) and that date (inclusive).", , 350, 150)
		
		; Figure out start/end of range
		edgeDate := new RelativeDate(dateString).instant
		if(edgeDate > A_Now) { ; Future dates, start with tomorrow
			startDate := EnvAdd(A_Now, 1, "Days")
			endDate   := edgeDate
		} else if(edgeDate < A_Now) { ; Past dates, end with yesterday
			startDate := edgeDate
			endDate   := EnvAdd(A_Now, -1, "Days")
		}
	}
	
	;---------
	; DESCRIPTION:    Send the given items with a to-do tag (bound to Ctrl+1).
	; PARAMETERS:
	;  items      (I,REQ) - Simple array of todo items to send.
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
	
	;---------
	; DESCRIPTION:    Send the given items with the given tags (defined and applied via ctrl + # hotkeys).
	; PARAMETERS:
	;  items (I,REQ) - Array of item objects, format:
	;                    items[ln] := {tag:tagNumber, text:itemText}
	;---------
	sendItemsWithTags(items) {
		For index,item in items {
			if(index > 1)
				Send, {Enter}
			
			Send, ^0 ; Clear tag
			Send, % "^" item.tag ; Apply new tag
			
			SendRaw, % item.text
		}
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
