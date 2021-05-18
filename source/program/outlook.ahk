; Outlook Hotkeys.

; Program in general
#If Config.isWindowActive("Outlook")
	; Move selected message(s) to a particular folder, and mark them as read.
	$^e::Send, {Backspace} ; Archive
	^+w::Send, ^+1 ; Wait
	^+l::Send, ^+2 ; Later use
	
	; Format as code (using custom styles)
	^+c::Send, ^!+2 ; Hotkey used in Outlook (won't let me use ^+c directly)
	
	; Bulleted list
	^.::^+l
#If

; Mail folders
#If Config.isWindowActive("Outlook") && (Outlook.isCurrentScreenMail() || Outlook.isMailMessagePopupActive())
	; Copy current message title to clipboard
	!c::Outlook.copyCurrentMessageTitle()
	
	; Open the relevant record (if applicable) for the current message
	!w::Outlook.openEMC2ObjectFromCurrentMessageWeb()
	!e::Outlook.openEMC2ObjectFromCurrentMessageEdit()
#If

; Calendar folders
#If Config.isWindowActive("Outlook") && Outlook.isCurrentScreenCalendar()
	; Shortcut to go to today on the calendar. (In desired, 3-day view.)
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
#If Config.machineIsWorkLaptop
	^!m::Config.runProgram("Outlook", "/c ipm.note")
#If
