; Epic-specific functions.

{ ; Phone-related functions.
	; Dials a given number using the Cisco WebDialer API.
	callNumber(formattedNum, name := "") {
		; Get the raw number (with leading digits as needed) to plug into the URL.
		rawNum := parsePhone(formattedNum)
		if(!rawNum) {
			MsgBox, % "Invalid phone number."
			return
		}
		
		; Confirm the user wants to call.
		if(!userWantsToCall(formattedNum, rawNum, name))
			return
		
		; Build the URL.
		url := getDialerURL(rawNum)
		if(!url)
			return
		
		; Dial with a web request.
		HTTPRequest(url, In := "", Out := "")
		; Debug.popup("callNumber","Finish", "Input",formattedNum, "Raw number",rawNum, "Name",name, "URL",url)
	}
	
	userWantsToCall(formattedNum, rawNum, name := "") {
		if(!formattedNum || !rawNum)
			return false
		
		if(formattedNum = "HANGUP") {
			title          := "Hang up?"
			messageText    := "Hanging up current call. `n`nContinue?"
		} else {
			title          := "Dial number?"
			messageText    := "Calling: `n`n"
			if(name)
				messageText .= name "`n"
			messageText    .= formattedNum "`n"
			messageText    .= "[" rawNum "] `n`n"
			messageText    .= "Continue?"
		}
		
		return showConfirmationPopup(messageText, title)
	}
	
	; Generates a Cisco WebDialer URL to call a number.
	getDialerURL(rawNum) {
		if(!rawNum)
			return ""
		
		if(rawNum = "HANGUP")
			command := "HangUpCall?"
		else
			command := "CallNumber?extension=" rawNum
		
		return Config.private["CISCO_PHONE_BASE"].replaceTag("COMMAND", command)
	}
}

{ ; Run path/URL-building functions
	buildHyperspaceRunString(versionMajor, versionMinor, environment) {
		runString := Config.private["HYPERSPACE_BASE"]
		
		; Versioning and environment.
		runString := runString.replaceTags({"MAJOR":versionMajor, "MINOR":versionMinor, "ENVIRONMENT":environment})
		
		; Debug.popup("Start string", tempRun, "Finished string", runString, "Major", versionMajor, "Minor", versionMinor, "Environment", environment)
		return runString
	}

	buildTxDumpRunString(txId, environmentCommId := "", environmentName := "") {
		if(!txId)
			return ""
		
		; Build the full output filepath.
		if(!environmentName)
			if(environmentCommId)
				environmentName := environmentCommId
			else
				environmentName := "OTHER"
		outputPath := Config.path["TX_DIFF_OUTPUT"] "\" txId "-" environmentName ".txt"
		
		; Build the string to run
		runString := Config.private["TX_DIFF_DUMP_BASE"]
		runString := runString.replaceTag("TX_ID",       txId)
		runString := runString.replaceTag("OUTPUT_PATH", outputPath)
		
		; Add on the environment if it's given - if not, leave off the flag (which will automatically cause the script to show an environment selector instead).
		if(environmentCommId)
			runString .= " --env " environmentCommId
		
		; Debug.popup("buildTxDumpRunString","Finish", "txId",txId, "outputFolder",outputFolder, "environmentCommId",environmentCommId, "runString",runString)
		return runString
	}

	buildVDIRunString(vdiId) {
		return Config.private["VDI_BASE"].replaceTag("VDI_ID", vdiId)
	}
}

; Split serverLocation into routine and tag (assume it's just the routine if no ^ included).
; Note that any offset from a tag will be included in the tag return value (i.e. TAG+3^ROUTINE splits into routine=ROUTINE and tag=TAG+3).
splitServerLocation(serverLocation, ByRef routine := "", ByRef tag := "") {
	serverLocation := serverLocation.clean(["$", "(", ")"])
	locationAry := serverLocation.split("^")
	
	maxIndex := locationAry.MaxIndex()
	if(maxIndex > 1)
		tag := locationAry[1]
	routine := locationAry[maxIndex] ; Always the last piece (works whether there was a tag before it or not)
}

; Drop the offset ("+4" in "tag+4^routine") from the given server location (so we'd return "tag^routine").
dropOffsetFromServerLocation(serverLocation) {
	splitServerLocation(serverLocation, routine, tag)
	tag := tag.beforeString("+")
	return tag "^" routine
}
