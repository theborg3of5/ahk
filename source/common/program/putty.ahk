class Putty {
	;region ------------------------------ INTERNAL ------------------------------
	; IDM_RECONF, found in Putty's source code in window.c: https://github.com/codexns/putty/blob/master/windows/window.c
	static ChangeSettingsOption := 0x50
	
	;---------
	; DESCRIPTION:    Wipe the screen, optionally also clearing scrollback.
	; PARAMETERS:
	;  clearScrollback (I,OPT) - Set to true to also clear scrollback.
	;---------
	wipeScreen(clearScrollback := false) {
		Send, !{Space} ; Open menu
		Send, t        ; Reset terminal
		
		if(clearScrollback) {
			Send, !{Space}
			Send, l ; Clear scrollback
		}
		
		Sleep, 100
		Send, {Enter} ; Show prompt
	}
	
	;---------
	; DESCRIPTION:    Prompt for some text, then insert it (without overwriting) by inserting spaces.
	;---------
	insertArbitraryText() {
		; Popup to get the text.
		textIn := InputBox("Insert text (without overwriting)", , , 500, 100)
		if(textIn = "")
			return
		
		; Get the length of the string we're going to add.
		inputLength := textIn.length()
		
		; Insert that many spaces.
		Send, {Insert %inputLength%}
		
		; Actually send our input text.
		SendRaw, % textIn
	}
	
	;---------
	; DESCRIPTION:    Search within record edit screens with Home+F9 functionality.
	; PARAMETERS:
	;  usePrevious (I,OPT) - Set to true to use the last search type/text instead of prompting the
	;                        user. This is ignored if there was no last search type/text.
	; SIDE EFFECTS:   Sets Putty.LastSearch_* to whatever is chosen here for re-use later.
	;---------
	recordEditSearch(usePrevious := false) {
		; Start with the last search type/text if requested.
		if(usePrevious) {
			searchType := Putty.LastSearch_Type
			searchText := Putty.LastSearch_Text
		}
	
		; If no previous values (or not using them), prompt the user for how/what to search.
		if(searchType = "" || searchText = "") {
			data := new Selector("puttyRecordEditSearch.tls").prompt()
			searchType := data["SEARCH_TYPE"]
			searchText := data["SEARCH_TEXT"]
		}
		
		; If still nothing, bail.
		if(searchType = "" || searchText = "")
			return
		
		; Run the search.
		Send, {Home}{F9}
		Send, %searchType%{Enter}
		SendRaw, % searchText
		Send, {Enter}
		
		; Store off the latest search for use with ^g later.
		Putty.LastSearch_Type := searchType
		Putty.LastSearch_Text := searchText
	}

	;---------
	; DESCRIPTION:    Open the Change Settings menu
	;---------
	openSettingsWindow() {
		PostMessage, MicrosoftLib.Message_WindowMenu, Putty.ChangeSettingsOption, 0
	}
	
	;---------
	; DESCRIPTION:    Open the current log file
	;---------
	openCurrentLogFile() {
		logFilePath := Putty.getLogFilePath()
		if(logFilePath)
			Run(logFilePath)
	}

	;---------
	; DESCRIPTION:    Get the current clipboard as a valid string in M.
	; RETURNS:        Escaped string
	;---------
	getClipboardAsMString() {
		clip := clipboard
		
		QUOTE := """" ; Double-quote character
		clip := StringLib.escapeCharUsingChar(clip, QUOTE, QUOTE)
		
		return QUOTE clip QUOTE
	}

	;---------
	; DESCRIPTION:    Convert the selected Sous execution ID to a trace ID and launch the trace 
	;                 portal for it.
	; PARAMETERS:
	;  deployment (I,OPT) - DEV, QA, or FINAL for which deployment to use. Defaults to DEV.
	;---------
	lookupTrace(deployment := "DEV") {
		; Map deployment to the portal environment name (for URLs) and CF deployment name (for login).
		if (deployment = "DEV") {
			portalEnv := "foundry"
			cfDeployment := "int-foundry"
		} else if (deployment = "QA") {
			portalEnv := "int-st-dev-ci"
			cfDeployment := "int-st-dev-ci"
		} else if (deployment = "FINAL") {
			portalEnv := "int-st-qa-ci"
			cfDeployment := "int-st-qa-ci"
		}

		pt := new ProgressToast("Finding trace ID from ExecID")
		pt.nextStep("Getting execId")

		execId := SelectLib.getText()
		if(execId = "") {
			pt.finish("No execId found")
			return
		}
		pt.endStep(execId)

		pt.nextStep("Querying " portalEnv " factory via WSL")
		; Actual query happens in WSL, as that's where the auth stuff we need lives.
		portalURL := Config.private["EPIC_FACTORY_PORTAL_URL_BASE"].replaceTag("DEPLOYMENT", portalEnv)
		traceId := RunLib.runReturn("wsl.exe ~/dotfiles/bin/exec-to-trace.sh " execId " " portalURL, stderr, exitCode)

		if (exitCode = 2) {
			pt.endStep("Token expired")

			pt.nextStep("Logging into " portalEnv " cluster")
			; Use RunWait [not runReturn()] because this does need to be an interactive terminal
			RunWait, wsl.exe ~/dotfiles/bin/cf-factory-login.sh %cfDeployment%
			pt.endStep("done")

			pt.nextStep("Retrying trace lookup")
			traceId := RunLib.runReturn("wsl.exe ~/dotfiles/bin/exec-to-trace.sh " execId " " portalUrl, stderr, exitCode)
		}

		if (traceId = "") {
			pt.endStep("Failed!")
			pt.finish("Failed to get trace ID")

			tt := new TextTable("Failed to get trace ID from WSL")
			tt.addRow(stderr)
			new TextPopup(tt).show()

			return
		}
		clipboard := traceId
		pt.endStep(traceId " (now on clipboard)")

		pt.nextStep("Building and running URL")
		url := Config.private["EPIC_FACTORY_TRACE_URL_BASE"].replaceTags({ "DEPLOYMENT":portalEnv, "TRACE_ID":traceId })
		Run(url)

		pt.finish()
	}
	;endregion ------------------------------ INTERNAL ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; For Home+F9 searching repeatedly.
	static LastSearch_Type := ""
	static LastSearch_Text := ""
	
	;---------
	; DESCRIPTION:    Get the log file for the current Putty session via the settings window.
	; RETURNS:        The path to the log file
	; SIDE EFFECTS:   Temporarily opens the settings window, then closes it.
	;---------
	getLogFilePath() {
		if(!WinActive("ahk_class PuTTY"))
			return ""
		
		Putty.openSettingsWindow()
		
		; Wait for the popup to show up
		WinWaitActive, ahk_class PuTTYConfigBox
		
		Send, !g ; Category pane
		Send, l  ; Logging tree node
		Sleep, 500
		Send, !f ; Log file name field
		
		logFile := SelectLib.getText()
		
		Send, !c ; Cancel
		return logFile
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
