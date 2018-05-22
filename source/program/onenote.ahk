; OneNote hotkeys.
#IfWinActive, ahk_class Framework::CFrame
	{ ; Quick access toolbar commands.
		; New Subpage
		$^+n::
			oneNoteNewSubpage()
		return
		; Promote Subpage
		^+[::
			oneNotePromoteSubpage()
		return
		; Demote Subpage (Make Subpage)
		^+]::
			oneNoteDemoteSubpage()
		return
		; Delete Page
		$^+d::
			; Confirmation to avoid accidental page deletion
			MsgBox, 4, Delete page?, Are you sure you want to delete this page?
			IfMsgBox, Yes
				oneNoteDeletePage()
		return
		; Format as code (using custom styles)
		^+c::
			oneNoteCustomStyles()
			Send, {Enter}
		return
		; Create linked Specific page (using OneTastic macro)
		^l::
			oneNoteLinkedSpecificsPage()
		return
	}
	
	{ ; Navigation.
		; Modded ctrl+tab, etc. hotkeys.
		XButton1::Send, ^{PgDn}
		^Tab::    Send, ^{PgDn}
		XButton2::Send, ^{PgUp}
		^+Tab::   Send, ^{PgUp}
		
		^PgDn::Send, ^{Tab}
		^PgUp::Send, ^+{Tab}
		
		; Expand and collapse outlines.
		!Left::!+-
		!Right::!+=
		^t::
			Send, ^{Home} ; Overall Do header so we affect the whole page
			Send, {Down}  ; Move down to Today header
			Send, !+4     ; Top level that today's todos are at (so they're all collapsed)
			Send, !+3     ; Collapse to headers under Today (which collapses headers under Today so only unfinished todos on level 4 are visible)
		return
		^+t::
			Send, ^{Home}
			Send, !+4     ; Items for all sections (level 4)
		return
		
		; Replacement history back/forward.
		!+Left:: Send, !{Left}
		!+Right::Send, !{Right}
	}
	
	{ ; Content/formatting modifiers.
		; Deletes a full line.
		^d::
			escapeOneNotePastePopup()
			Send, {Home}   ; Make sure the line isn't already selected, otherwise we select the whole parent.
			Send, ^a       ; Select all - gets entire line, including newline at end.
			Send, {Delete}
		return
		
		; Make line movement alt + up/down instead of alt + shift + up/down to match notepad++ and ES.
		!Up::  Send, !+{Up}
		!Down::Send, !+{Down}
		
		; 'Normal' text formatting, as ^+n is already being used for new subpage.
		^!n::
			Send, ^+n
		return
		
		; Bold an entire line.
		^+b::
			Send, ^a ; Select all (gets whole line/paragraph)
			Send, ^b
			Send, {Right} ; Put cursor at end of line
		return
		
		; Make ^7 do the same tag as ^6.
		^7::^6
	}
	
	; Disable ^t hotkey making a new section
	; ^t::return ; Used for collapsing/expanding above
	
	^s::
		escapeOneNotePastePopup()
		Send, +{F9} ; Sync This Notebook Now
	return
	^+s::
		escapeOneNotePastePopup()
		Send, {F9} ; Sync All Notebooks Now
	return
	
	; Copy link to page.
	!c::
		copyOneNoteLink() {
			; Get the link to the current paragraph.
			Send, +{F10}
			Sleep, 100
			Send, p
			Sleep, 500
			
			; If the special paste menu item was there (where the only option is "Paste (P)"), the menu is still open (because 2 "p" items) - get to the next one and actually submit it.
			if(WinActive("ahk_class Net UI Tool Window"))
				Send, p{Enter}
			
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
			
			clipboard := linkToUse
		}
	
	; Make a copy of the current page in the Do section.
	^+m::
		copyOneNoteDoPage() {
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
			Loop {
				userInput := Input("T1", "{Esc}{Enter}") ; Wait for 1 second (exit immediately if Escape or Enter is pressed)
				if(stringContains(userInput, A_Space))   ; If space was pressed, wait another 1 second
					Continue
				Break
			}
			
			Send, ^{PgDn}              ; Switch to (presumably) new page
			Send, !3                   ; Demote Subpage (Make Subpage)
			
			; Make the current page have no background color.
			Send, !w
			Send, pc
			Send, n
			
			Send, ^+t                  ; Select title (to replace with new day/date)
			
			Sleep, 750                 ; Wait for selection to take
			sendDateTime("M/d`, dddd") ; Send today's day/date
			Send, ^+t                  ; Select title again in case you want a different date.
		}
	
	; Insert a contact comment.
	^+8::
		insertOneNoteContactComment() {
			date := FormatTime(, "MM/yy")
			SendRaw, % "*" MainConfig.getPrivate("INITIALS") " " date
		}
	
	; Named functions for which commands are which in the quick access toolbar.
	oneNoteNewSubpage() {
		Send, !1
	}
	oneNotePromoteSubpage() {
		Send, !2
	}
	oneNoteDemoteSubpage() {
		Send, !3
	}
	oneNoteDeletePage() {
		Send, !4
	}
	oneNoteCustomStyles() {	; Custom styles from OneTastic
		Send, !7
	}
	oneNoteLinkedSpecificsPage() { ; Custom OneTastic macro
		Send, !8
	}
	
	;---------
	; DESCRIPTION:    If the paste popup has appeared, get rid of it. Typically this is used for AHK
	;                 hotkeys that use the Control key, which sometimes causes the paste popup to
	;                 appear afterwards (if we pasted recently).
	;---------
	escapeOneNotePastePopup() {
		ControlGet, pastePopupHandle, Hwnd, , OOCWindow1, A
		if(!pastePopupHandle)
			return
		
		Send, {Space}{Backspace}
	}
#IfWinActive
