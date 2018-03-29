; Outlook Hotkeys.

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
	
	; Format as code (using custom styles)
	^+c::
		Send, ^+s
		WinWaitActive, Apply Styles
		Send, Code
		Send, {Enter}
	return
#IfWinActive

; Mail activity.
#If isEmailFolderActive(MainConfig.getPrivate("WORK_EMAIL"))
	; Move selected message(s) to a particular folder, and mark them as read.
	$^e::
		Send, ^+1 ; Archive
	return
	^+w::
		Send, ^+2 ; Wait
	return
	^+l::
		Send, ^+3 ; Later use
	return
#If

; Calendar activity.
#If isCalendarFolderActive(MainConfig.getPrivate("WORK_EMAIL"))
	; Calendar view: 3-day view, week view, and month view.
	^w::Send, ^!3
	
	; Show a popup for picking an arbitrary calendar to display.
	^a::
		Send, !h
		Send, oc
		Send, a
	return
#If

; Universal new email.
#If MainConfig.isMachine(MACHINE_EpicLaptop)
	^!m::
		Run(MainConfig.getProgram("Outlook", "PATH") " /c ipm.note")
	return
#If



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
