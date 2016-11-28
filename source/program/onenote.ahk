; OneNote hotkeys.
#IfWinActive, ahk_class Framework::CFrame
	{ ; Quick access toolbar commands.
		; Sync This Notebook Now
		^s::
			Send, !1
		return
		; Sync All Notebooks Now
		^+s::
			Send, !2
		return
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
		; Adds a new sub-bullet that won't disappear.
		^+a::
			Send, {End}{Enter}{Tab}A{Backspace}
		return

		; Bolds the full row.
		^+b::
			Send, {Home}{Shift Down}{End}{Shift Up}^b{Down}{Home}
		return
		
		; Copy the full row.
		^+c::
			SendPlay, {Home}{Down}{Home}{Shift Down}{Up}{Shift Up}
			Send, ^c
		return
		
		; Cut the full row.
		^+x::
			SendPlay, {Home}{Down}{Home}{Shift Down}{Up}{Shift Up}
			Send, ^x
		return
		
		; Deletes a full line.
		^d::
			SendPlay, {Home}{Down}{Home}{Shift Down}{Up}{Shift Up}
			Send, {Delete}
		return
		
		; Turn link a more reasonable color (assuming selected) and pop up linkbox.
		$^+k::
			Send, !h
			Send, fc
			Send, {Down 7}{Right}
			Send, {Enter}
			Send, ^k
		return
		
		; Remap add Outlook task hotkey since linking is using it.
		^+t::
			Send, ^+k
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
