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
#IfWinActive

; Mail activity.
#If WinActive("Inbox - " epicEmailAddress " - Outlook") || WinActive("Do - " epicEmailAddress " - Outlook") || WinActive("Wait - " epicEmailAddress " - Outlook")
	; Archive the current message.
	$^e::
		Send, ^q
		Send, !1
	return
#If

; Calendar activity.
#If WinActive("Calendar - " epicEmailAddress " - Outlook") || WinActive("TLG - " epicEmailAddress " - Outlook")
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
	^4::
	^+1::
		Send, !v
		Send, sc
		Send, 1
	return
	^3::
	^+3::
		Send, !v
		Send, sc
		Send, 3
	return
	
	; Category application: Make ^F1 usable.
	^F1::^F12
	
	; Show a popup for picking an arbitrary calendar to display.
	^a::
		Send, !h
		Send, oc
		Send, a
	return
#If

; Universal new email.
#If BorgConfig.isMachine(EPIC_DESKTOP)
	^!m::
		Run, % BorgConfig.getProgram("Outlook", "PATH") " /c ipm.note"
	return
#If
