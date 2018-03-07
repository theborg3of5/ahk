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
		$XButton1::
		^Tab::
			Send, ^{PgDn}
		return
		$XButton2::
		^+Tab::
			Send, ^{PgUp}
		return
		^PgDn::
			Send, ^{Tab}
		return
		^PgUp::
			Send, ^+{Tab}
		return
		
		; Expand and collapse outlines.
		$!Left::
			Send, !+-
		return
		$!Right::
			Send, !+=
		return
		
		; Replacement history back/forward.
		!+Left::
			Send, !{Left}
		return
		!+Right::
			Send, !{Right}
		return
	}
	
	{ ; Content/formatting modifiers.
		; Deletes a full line.
		^d::
			Send, ^a ; Select all - gets entire line, including newline at end.
			Send, {Delete}
		return
		
		; Make line movement alt + up/down instead of alt + shift + up/down to match notepad++ and ES.
		!Up::
			Send, !+{Up}
		return
		!Down::
			Send, !+{Down}
		return
		
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
	}
	
	; Disable ^t hotkey making a new section
	^t::return
	
	; Sync This Notebook Now
	^s::
		Send, +{F9}
	return
	; Sync All Notebooks Now
	^+s::
		Send, {F9}
	return
	
	; Copy link to page.
	!c::
		; Get the link to the current paragraph.
		Send, +{F10}
		Sleep, 100
		Send, p
		Sleep, 500
		
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
	return
	
	; Make a copy of the current page in the Do section.
	^+m::
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
		Sleep, 1000                ; Wait a second for the new page to appear
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
	return
	
	; Insert a contact comment.
	^+8::
		FormatTime, date, , MM/yy
		SendRaw, % "*" USER_INITIALS " " date
	return
	
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
#IfWinActive
