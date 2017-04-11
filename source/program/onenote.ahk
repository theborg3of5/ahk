; OneNote hotkeys.
#IfWinActive, ahk_class Framework::CFrame
	{ ; Quick access toolbar commands.
		; New Subpage
		$^+n::
			Send, !3
		return
		; Promote Subpage
		^+[::
			Send, !4
		return
		; Demote Subpage (Make Subpage)
		^+]::
			Send, !5
		return
		; Delete Page
		$^+d::
			Send, !6
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
		!Left::
			Send, !+-
		return
		!Right::
			Send, !+=
		return
	}
	
	{ ; Content/formatting modifiers.
		; Deletes a full line.
		^d::
			Send, {Home}
			Send, ^{Down}
			Send, {Home}
			Send, {Shift Down}
			Send, ^{Up}
			Send, {Shift Up}
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
	}
	
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
		link := RegExReplace(clipboard, "&object-id.*")
		
		link .= "&end"
		
		clipboard := link
	return

	; More intelligent escape key - don't close when quitting out of searchbox.
	$Escape::
		ControlGetFocus, currControl, A
		if(currControl = "RICHEDIT60W1") {
			Send, {Escape}
		} else {
			WinClose
		}
	return
#IfWinActive
