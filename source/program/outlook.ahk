; Outlook Hotkeys.

isEmailFolderActive(userEmail) {
	titles := []
	titles.push(buildOutlookWindowTitle(userEmail, "Inbox"))
	titles.push(buildOutlookWindowTitle(userEmail, "Wait"))
	titles.push(buildOutlookWindowTitle(userEmail, "Later Use"))
	titles.push(buildOutlookWindowTitle(userEmail, "Archive"))
	titles.push(buildOutlookWindowTitle(userEmail, "Sent Items"))
	titles.push(buildOutlookWindowTitle(userEmail, "Deleted Items"))
	
	return isWindowInState("active", titles)
}

isCalendarFolderActive(userEmail = "") {
	titles := []
	titles.push(buildOutlookWindowTitle(userEmail, "Calendar"))
	titles.push(buildOutlookWindowTitle(userEmail, "TLG"))
	
	return isWindowInState("active", titles)
}

buildOutlookWindowTitle(userEmail, folderName) {
	return folderName " - " userEmail " - Outlook"
}

; Program in general.
#IfWinActive, ahk_class rctrl_renwnd32
	; Shortcut to go to today on the calendar. (In desired, 3-day view.)
	^t::
		; Get to calendar if needed.
		Send, ^2
		Send, {Up}{Down}
		
		; Go to today if needed.
		Send, !h
		Send, od
		
		; Set view as desired.
		Send, !1 ; 1 day.
	return
	
	; Bulleted list.
	^.::^+l
#IfWinActive

; Mail activity.
#If isEmailFolderActive(USER_WORK_EMAIL)
	; Move selected message(s) to a particular folder, and mark them as read.
	$^e::
		Send, ^+1 ; Archive
	return
	^w::
		Send, ^+2 ; Wait
	return
	^l::
		Send, ^+3 ; Later use
	return
#If

; Calendar activity.
#If isCalendarFolderActive(USER_WORK_EMAIL)
	; Calendar view: 3-day view, week view, and month view.
	$^e::Send, !3
	^w::Send, ^!3
	^q::Send, ^!4
	
	; Toggle the preview pane in calendar view.
	!r::
		Send, !v
		Send, pn
		if(previewOpen) {
			Send, b
			previewOpen := 0
		} else {
			Send, o
			previewOpen := 1
		}
	return
	
	; Time Scale on calendar: 15m and 30m.
	; ^4::
	; ^+1::
		; Send, !v
		; Send, sc
		; Send, 1
	; return
	; ^3::
	; ^+3::
		; Send, !v
		; Send, sc
		; Send, 3
	; return
	
	; Category application: Make ^F1 usable.
	; ^F1::^F12
	
	; Show a popup for picking an arbitrary calendar to display.
	^a::
		Send, !h
		Send, oc
		Send, a
	return
#If

; Universal new email.
#If MainConfig.isMachine(MACHINE_EPIC_LAPTOP)
	^!m::
		Run, % MainConfig.getProgram("Outlook", "PATH") " /c ipm.note"
	return
#If
