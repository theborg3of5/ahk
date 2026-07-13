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
	
	; Get out of Chronicles
	^d::
		Send, +{F7 3}                                  ; Get out of (potentially-nested) open records
		Send, {PgDn 3}                                 ; Get out to main menu
		Send, quit{Enter}                              ; Exit
		SendRaw, % Config.private["EPIC_LOOKITT"] "`n" ; Get back into Lookitt (in case we left)
		Sleep, 100
		Putty.wipeScreen()                             ; Wipe the screen
	return
	
	; Scroll 1 line at a time
	^WheelUp::  Send, ^{PgUp}
	^WheelDown::Send, ^{PgDn}
	
	; Search within record edit screens
	^F9::Putty.recordEditSearch()
	^g:: Putty.recordEditSearch(true)
	
	; Open up settings window.
	!o::Putty.openSettingsWindow()
	
	; Open up the current log file.
	^+o::Putty.openCurrentLogFile()

	; Send the clipboard as an (appropriately escaped) string.
	:X:.clip::SendRaw, % EpicStudio.getClipboardAsMString()
	
	; Send specific commands (extra spaces between quotes are purely for readability)
	^z:: SendRaw, % Config.private["EPIC_LOOKITT"] "`n"
	^e:: SendRaw, % "e " ; Chronicles
	^s:: SendRaw, % ";set"   "`n"
	^o:: SendRaw, % ";top"   "`n"
	^r:: SendRaw, % ";kecr"  "`n"
	^h:: SendRaw, % ";hb"    "`n"
	^+r::SendRaw, % ";rstat" "`n"
	^+h::SendRaw, % ";hstat" "`n"
	^+e::SendRaw, % ";v"     "`n"
	::;je :: ; Include a space so default use of macro (to jump into list) doesn't trigger this
		examineJob() {
			; Prompt for process ID
			jobId := InputBox("Enter process ID to look up", "Enter job process ID")
			if(jobId = "")
				return

			Send, `;je{Enter} ; Launch the job list using the actual macro.
			Send, % "eP" jobId "`n" ; Jump into examining the provided job.
		}
	:X:;trace::
		lookupTrace() {
			pt := new ProgressToast("Finding trace ID from ExecID")
			pt.nextStep("Getting execId")

			execId := SelectLib.getText()
			if(execId = "") {
				pt.finish("No execId found")
				return
			}
			pt.endStep(execId)

			pt.nextStep("Querying Factory via WSL")
			; Actual query happens in WSL, as that's where the auth stuff we need lives.
			traceId := RunLib.runReturn("wsl.exe ~/dotfiles/bin/exec-to-trace.sh " execId, stderr)
			if (traceId = "") {
				pt.finish("Failed to get trace ID")

				tt := new TextTable("Failed to get trace ID from WSL")
				tt.addRow(stderr)
				new TextPopup(tt).show()
				
				return
			}
			clipboard := traceId
			pt.endStep(traceId " (now on clipboard)")
			
			pt.nextStep("Building and running URL")
			url := Config.private["EPIC_FACTORY_TRACE_URL_BASE"].replaceTags({ "DEPLOYMENT":"foundry", "TRACE_ID":traceId })
			Run(url)

			pt.finish()
		}

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
