; Epic-specific functions.

{ ; Epic Object-related things.
	getRelatedQANsAry() {
		if(!MainConfig.isWindowActive("EMC2"))
			return ""
		
		; Assuming you're in the first row of the table already.
		
		outAry := []
		Loop {
			Send, {End}
			Send, {Left}
			Send, {Ctrl Down}{Shift Down}
			Send, {Left}
			Send, {Ctrl Up}
			Send, {Right}
			Send, {Shift Up}
			
			qan := getSelectedText()
			if(!qan)
				break
			
			Send, {Tab}
			version := getSelectedText()
			
			; Avoid duplicate entries (for multiple versions
			if(qan != oldQAN)
				outAry.push(qan)
			
			; Loop quit condition - same QAN again (table ends on last filled row), also same version
			if( (qan = oldQAN) && (version = oldVersion) )
				break
			oldQAN     := qan
			oldVersion := version
			
			Send, +{Tab}
			Send, {Down}
		}
		
		return outAry
	}

	buildQANURLsAry(relatedQANsAry) {
		if(!relatedQANsAry)
			return ""
		
		urlsAry := []
		For _,qan in relatedQANsAry {
			ao := new ActionObjectEMC2(qan, "QAN")
			link := ao.getLinkWeb()
			if(link)
				urlsAry.push(link)
		}
		
		return urlsAry
	}
}

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
		; DEBUG.popup("callNumber","Finish", "Input",formattedNum, "Raw number",rawNum, "Name",name, "URL",url)
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
		
		MsgBox, % MSGBOX_BUTTONS_YES_NO, % title, % messageText
		IfMsgBox Yes
			return true
		return false
	}
	
	; Generates a Cisco WebDialer URL to call a number.
	getDialerURL(rawNum) {
		if(!rawNum)
			return ""
		
		if(rawNum = "HANGUP")
			command := "HangUpCall?"
		else
			command := "CallNumber?extension=" rawNum
		
		return replaceTag(MainConfig.private["CISCO_PHONE_BASE"], "COMMAND", command)
	}
}

{ ; Run path/URL-building functions
	buildHyperspaceRunString(versionMajor, versionMinor, environment) {
		runString := MainConfig.private["HYPERSPACE_BASE"]
		
		; Handling for 2010 special path.
		if(versionMajor = 7 && versionMinor = 8)
			runString := replaceTag(runString, "EPICNAME", "EpicSys")
		else
			runString := replaceTag(runString, "EPICNAME", "Epic")
		
		; Versioning and environment.
		runString := replaceTags(runString, {"MAJOR":versionMajor, "MINOR":versionMinor, "ENVIRONMENT":environment})
		
		; DEBUG.popup("Start string", tempRun, "Finished string", runString, "Major", versionMajor, "Minor", versionMinor, "Environment", environment)
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
		outputPath := MainConfig.path["TX_DIFF_OUTPUT"] "\" txId "-" environmentName ".txt"
		
		; Build the string to run
		runString := MainConfig.private["TX_DIFF_DUMP_BASE"]
		runString := replaceTag(runString, "TX_ID",       txId)
		runString := replaceTag(runString, "OUTPUT_PATH", outputPath)
		
		; Add on the environment if it's given - if not, leave off the flag (which will automatically cause the script to show an environment selector instead).
		if(environmentCommId)
			runString .= " --env " environmentCommId
		
		; DEBUG.popup("buildTxDumpRunString","Finish", "txId",txId, "outputFolder",outputFolder, "environmentCommId",environmentCommId, "runString",runString)
		return runString
	}

	buildVDIRunString(vdiId) {
		return replaceTag(MainConfig.private["VDI_BASE"], "VDI_ID", vdiId)
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
