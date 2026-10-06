#If Config.isWindowActive("Putty")
	^c::return ; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	*^s::return ; Disable fall-thru XOFF hotkeys (^s and others cause terminal to freeze, unfreeze with ^q)
	^v::Send, +{Insert} ; Normal paste, without all the inserting of spaces.
	+Tab::Send, {Left} ; Allow reverse field navigation.
	
	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::Putty.insertArbitraryText()
	
	; Screen wipes
	^l::Putty.wipeScreen()
	^+l::Putty.wipeScreen(true)
	
	; Search within record edit screens
	^F9::Putty.recordEditSearch()
	^g:: Putty.recordEditSearch(true)
	
	; Open up settings window.
	!o::Putty.openSettingsWindow()
	
	; Open up the current log file.
	^+o::Putty.openCurrentLogFile()

	; Send the clipboard as an (appropriately escaped) string.
	:X:.clip::SendRaw, % Putty.getClipboardAsMString()
	
	; Send specific commands (extra spaces between quotes are purely for readability)
	^d:: SendRaw, % ";dbcutil" "`n"
	^e:: SendRaw, % "e " ; Chronicles
	^h:: SendRaw, % ";hb"      "`n"
	^o:: SendRaw, % ";top"     "`n"
	^r:: SendRaw, % ";kecr"    "`n"
	^s:: SendRaw, % ";set"     "`n"
	^u:: SendRaw, % ";hbutil"  "`n"
	^z:: SendRaw, % Config.private["EPIC_LOOKITT"] "`n"
	^+e::SendRaw, % ";v"       "`n"
	^+h::SendRaw, % ";hstat"   "`n"
	^+r::SendRaw, % ";rstat"   "`n"

	::;je :: ; Include a space so default use of macro (to jump into list) doesn't trigger this
		examineJob() {
			; Prompt for process ID
			jobId := InputBox("Enter process ID to look up", "Enter job process ID")
			if(jobId = "")
				return

			Send, `;je{Enter} ; Launch the job list using the actual macro.
			Send, % "eP" jobId "`n" ; Jump into examining the provided job.
		}
	:X:;trace:: Putty.lookupTrace("DEV")
	:X:;qtrace::Putty.lookupTrace("QA")
	:X:;ftrace::Putty.lookupTrace("FINAL")

; Limit this to when the mouse is over putty so we don't block scrolling other programs while Putty is active.
#If Config.isWindowActive("Putty") && Config.isMouseOverWindow("Putty")
	; Scroll 1 line at a time by default, hold Ctrl to scroll half a page at a time (Putty's default)
	$WheelUp::  Send, ^{PgUp}
	$WheelDown::Send, ^{PgDn}
	^WheelUp::  Send, {WheelUp}
	^WheelDown::Send, {WheelDown}

; MTPutty pass-throughs
#If Config.isWindowActive("Putty") && Config.doesWindowExist("MTPutty")
	; Attach all "orphaned" putty windows to MTPutty
	$^+a::MTPutty.attachOrphanedPuttyWindows()
	
	; Detach current tab
	^+d::MTPutty.detachCurrentTab()

	; Rename tab to match window title
	F2::MTPutty.fixPuttyTabTitle()

	; Close tab
	^w::Send, !{F4}
#If
