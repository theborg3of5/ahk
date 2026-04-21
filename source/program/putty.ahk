#HotIf Config.isWindowActive("Putty")
	^c::return ; Disable breaking behavior for easy-to-hit-accidentally ^c, PuTTY already has a ^+c hotkey that works too.
	*^s::return ; Disable fall-thru XOFF hotkeys (^s and others cause terminal to freeze, unfreeze with ^q)
	^v::Send("+{Insert}") ; Normal paste, without all the inserting of spaces.
	+Tab::Send("{Left}") ; Allow reverse field navigation.

	; Insert arbitrary text, inserting needed spaces to overwrite.
	^i::Putty.insertArbitraryText()

	; Screen wipes
	^l::Putty.wipeScreen()
	^+l::Putty.wipeScreen(true)

	; Get out of Chronicles
	^d:: {
		Send("+{F7 3}")                                  ; Get out of (potentially-nested) open records
		Send("{PgDn 3}")                                 ; Get out to main menu
		Send("quit{Enter}")                              ; Exit
		SendText(Config.private["EPIC_LOOKITT"] "`n")    ; Get back into Lookitt (in case we left)
		Sleep(100)
		Putty.wipeScreen()                               ; Wipe the screen
	}

	; Scroll 1 line at a time
	^WheelUp::  Send("^{PgUp}")
	^WheelDown::Send("^{PgDn}")

	; Search within record edit screens
	^F9::Putty.recordEditSearch()
	^g:: Putty.recordEditSearch(true)

	; Open up settings window.
	!o::Putty.openSettingsWindow()

	; Open up the current log file.
	^+o::Putty.openCurrentLogFile()

	; Send the clipboard as an (appropriately escaped) string.
	:X:.clip::SendText(EpicStudio.getClipboardAsMString())

	; Send specific commands (extra spaces between quotes are purely for readability)
	^z:: SendText(Config.private["EPIC_LOOKITT"] "`n")
	^e:: SendText("e ") ; Chronicles
	^s:: SendText(";set"   "`n")
	^o:: SendText(";top"   "`n")
	^r:: SendText(";kecr"  "`n")
	^h:: SendText(";hb"    "`n")
	^+r::SendText(";rstat" "`n")
	^+h::SendText(";hstat" "`n")
	^+e::SendText(";v"     "`n")
	::;je :: ; Include a space so default use of macro (to jump into list) doesn't trigger this
		examineJob(*) {
			; Prompt for process ID
			jobId := InputBox("Enter process ID to look up", "Enter job process ID")
			if(jobId = "")
				return

			Send("`;je{Enter}") ; Launch the job list using the actual macro.
			Send("eP" jobId "`n") ; Jump into examining the provided job.
		}

; MTPutty pass-throughs
#HotIf Config.isWindowActive("Putty") && Config.doesWindowExist("MTPutty")
	; Attach all "orphaned" putty windows to MTPutty
	$^+a::MTPutty.attachOrphanedPuttyWindows()

	; Detach current tab
	^+d::MTPutty.detachCurrentTab()

	; Rename tab to match window title
	F2::MTPutty.fixPuttyTabTitle()

	; Close tab
	^w::Send("!{F4}")
#HotIf
