; Outlook Hotkeys.

; Program in general.
#If MainConfig.isWindowActive("Outlook")
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
	
	; Format as code (using custom styles)
	^+c::
		Send, ^+!2 ; Hotkey used in Outlook (won't let me use ^+c directly)
	return
	
	; Bulleted list.
	^.::^+l
#If

; Calendar activity.
#If MainConfig.isWindowActive("Outlook Calendar Main") || MainConfig.isWindowActive("Outlook Calendar TLG")
	; Shortcut to go to today on the calendar. (In desired, 3-day view.)
	^t::
		; Go to today.
		Send, !h
		Send, od
		
		; Set view as desired.
		Send, !1 ; 1 day.
	return
	
	; Calendar view: week view.
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
		Run(MainConfig.getProgramPath("Outlook") " /c ipm.note")
	return
#If
