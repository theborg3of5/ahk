; Outlook Hotkeys.

; Program in general
#If Config.isWindowActive("Outlook")
	; Move selected message(s) to a particular folder, and mark them as read.
	$^e::Send, !ho ; Archive
	^+w::Send, ^+1 ; Wait
	^+l::Send, ^+2 ; Later use
	
	; Format as code (using custom styles)
	^+c::Send, ^!+2 ; Hotkey used in Outlook (won't let me use ^+c directly)
	
	; Bullets and numbering
	^.::^+l
	^/::
		if(Outlook.isMailMessagePopupActive())
			Send, !o   ; Format Text tab
		else
			Send, !e2  ; Message tab
		Send, n       ; Numbering
		Send, {Right} ; First numbering format
		Send, {Enter} ; Accept
	return

	; Switch ^f to be find, with forwarding moved to ^+f.
	^f::
		Send, ^g ; Launch Find and Replace window
		WinWaitActive, % "Find and Replace"
		Send, !d ; Switch to Find tab
	return
	^+f::Send, ^f
	
	; Toggle dark mode (not available as a command in non-editing message popup)
	!d::Outlook.toggleDarkMode()
#If

; Mail folders
#If Config.isWindowActive("Outlook") && (Outlook.isCurrentScreenMail() || Outlook.isMailMessagePopupActive())
	; Copy current message title to clipboard
	!c::ClipboardLib.setAndToast(Outlook.getMessageTitle(), "title")
	
	; Open the relevant record (if applicable) for the current message
	!w::new ActionObjectEMC2(Outlook.getMessageTitle()).openWeb()
	!e::new ActionObjectEMC2(Outlook.getMessageTitle()).openEdit()
#If

; Normal calendar
#If Outlook.isNormalCalendarActive()
	!c::Outlook.copyEMC2RecordIDFromEvent()
	!w::Outlook.getEMC2ObjectFromCalendarEvent().openWeb()
	!e::Outlook.getEMC2ObjectFromCalendarEvent().openEdit()
; TLG calendar
#If Outlook.isTLGCalendarActive()
	^+t::Outlook.selectOutlookTLG()	

	!c::Outlook.copyEMC2ObjectStringFromTLG()
	!w::Outlook.getEMC2ObjectFromTLG().openWeb()
	!e::Outlook.getEMC2ObjectFromTLG().openEdit()
#If

; Calendar folders
#If Config.isWindowActive("Outlook") && Outlook.isCurrentScreenCalendar()
	; Shortcut to go to today on the calendar (in desired, 3-day view)
	^t::
		; Go to today.
		Send, !h
		Send, od
		
		; Single-day view.
		Send, !1
	return
	
	; Calendar view: week view.
	^w::Send, ^!3
	
	; Show a popup for picking an arbitrary calendar to display.
	^a::
		Send, !h
		Send, oc
		Send, a
	return
	
	+WheelDown::Send, {Right}
	+WheelUp::  Send, {Left}
#If

; Universal new email.
#If Config.machineIsWorkDesktop
	^!m::Config.runProgram("Outlook", "/c ipm.note")
#If
