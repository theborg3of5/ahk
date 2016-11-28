; Epic-specific functions.

{ ; Epic Object-related things.
	; Returns 1 if the given number is an EMC2 ID (pure number, or starting with I, M, Y, T, Q, or CS), 2 if it's definitely a DLG (pretty much only SUs)
	isEMC2Id(num) {
		dlgLetters := ["i", "m", "y", "t", "q", "cs"]
		
		whichLetter := containsAnyOf(num, dlgLetters, CONTAINS_BEG)
		if(whichLetter) {
			rest := SubStr(num, StrLen(dlgLetters[whichLetter]) + 1)
			if(isNum(rest))
				return 2
		}
		
		if(isNum(num))
			return 1
		
		return 0
	}

	; Check if it's an epic object string.
	isEpicObject(text, ByRef ini = "", ByRef id = "") {
		if(isServerRoutine(text)) {
			ini := "SVR"
			id := text
			return true
		} else if(isEMC2Object(text, ini, id)) {
			return true
		}
		
		return false
	}

	; Returns true if the input looks like a server routine (has a ^ in it or is entirely all-caps letters).
	isServerRoutine(text, ByRef routine = "", ByRef tag = "") {
		; DEBUG.popup(text, "Text", isAlpha(text), "Is Alpha", isCase(text, STRING_CASE_UPPER), "Is Uppercase", STRING_CASE_UPPER, "Upper Constant")
		if(stringContains(text, "^")) {
			o := StrSplit(text, "^")
			tag := o[1]
			routine := o[2]
			return true
		} else if(!isNum(text) && isAlphaNum(text) && isCase(text, STRING_CASE_UPPER)) {
			routine := text
			return true
		}
		
		return false
	}

	; Check if it's a valid EMC2 string.
	isEMC2Object(text, ByRef ini = "", ByRef id = "") {
		objInfo := StrSplit(text, A_Space)
		data1 := objInfo[1]
		data2 := objInfo[2]
		; DEBUG.popup(text, "Text", data1, "Data1", data2, "Data2")
		
		; Look at the data gathered and determine which parts are which.
		if(data1 && data2) { ; Two parts, likely everything we need.
			if(isEMC2Id(data2)) {
				ini := data1
				id  := data2
			}
		} else if(data1) { ; Only one. Possible id on its own.
			id := data1
		}
		
		idLevel := isEMC2Id(id)
		; DEBUG.popup("Text", text, "Data1", data1, "Data2", data2, "INI", ini, "ID", id, "ID Level", idLevel)
		
		return idLevel
	}
}

{ ; Phone-related functions.
	; Generates a Cisco WebDialer URL to call a number.
	getDialerURL(num, name = "") {
		URL := "http://guru/services/Webdialer.asmx/"
		
		if(num = "-") {
			URL .= "HangUpCall?"
			MsgText = Hanging up current call. `n`nContinue?
		} else {
			phoneNum := parsePhone(num)
			
			if(phoneNum = -1) {
				MsgBox, Invalid phone number!
				return
			}
			
			URL .= "CallNumber?extension=" . phoneNum
			MsgText := "Calling: `n`n" 
			if(name)
				MsgText .= name "`n"
			MsgText .= num "`n[" phoneNum "] `n`nContinue?"
		}
		
		; Confirm they want to actually call.
		MsgBox, 4, Dial Number?, %MsgText%
		IfMsgBox No
			URL = ""
		
		return URL
	}

	; Dials a given number using the Cisco WebDialer API.
	callNumber(num, name = "") {
		URL := getDialerURL(num, name)
		; DEBUG.popup("callNumber", "start", "Input", num, "Name", name, "URL", URL)
		
		; Blank means an error or they said no to calling.
		if(URL != "") {
			callIfExists("HTTPRequest", URL, In := "", Out := "") ; HTTPRequest(URL, In := "", Out := "")
			return true
		}
		
		return false
	}
}

; Launches a routine of the form rag^routine (or ^routine, or routine) in EpicStudio.
openEpicStudioRoutine(text = "", routineName = "", tag = "") {
	if(!routineName) {
		objInfo := StrSplit(text, "^")
		tag := objInfo[1]
		routineName := objInfo[objInfo.MaxIndex()]
	}
	; DEBUG.popup("openEpicStudioRoutine", "Post-processing", "Open string", text, "Object info", objInfo, "Routine Name", routineName, "Tag", tag)
	
	; Launch ES if not running.
	activateProgram("EpicStudio")
	exeName := BorgConfig.getProgram("EpicStudio", "EXE")
	WinWaitActive, ahk_exe %exeName%
	waitUntilWindowState("active", " - EpicStudio", , 2)
	
	; Open correct routine.
	Send, ^o
	WinWaitActive, Open Object
	SendRaw, %routineName%
	Send, {Enter}
	
	; Focus correct tag if given.
	if(tag) {
		WinWaitActive, %routineName%
		Send, ^+o
		WinActivate, Go To
		WinWait, Go To
		SendRaw, %tag%
		Send, {Enter}
	}
}

openEpicStudioDLG(dlgNum) {
	activateProgram("EpicStudio")
	exeName := BorgConfig.getProgram("EpicStudio", "EXE")
	WinWaitActive, ahk_exe %exeName%
	
	Send, ^!e
	WinWaitActive, Open DLG
	
	Send, % dlgNum
	Send, {Enter 2}
}

buildHyperspaceRunString(versionMajor, versionMinor, environment) {
	global epicExeBase
	runString := epicExeBase
	
	; tempRun := runString ; DEBUG
	
	; Handling for 2010 special path.
	if(versionMajor = 7 && versionMinor = 8)
		runString := RegExReplace(runString, "<EPICNAME>", "EpicSys")
	else
		runString := RegExReplace(runString, "<EPICNAME>", "Epic")
	
	; Versioning and environment.
	runString := RegExReplace(runString, "<MAJOR>", versionMajor)
	runString := RegExReplace(runString, "<MINOR>", versionMinor)
	runString := RegExReplace(runString, "<ENVIRONMENT>", environment)
	
	; DEBUG.popup("Start string", tempRun, "Finished string", runString, "Major", versionMajor, "Minor", versionMinor, "Environment", environment)
	return runString
}

sendKHDFCommand(command = "", value = "", subscripts*) {
	leftsNeeded := 0
	
	SendRaw, % buildKHDFCommand(command, value, leftsNeeded, subscripts)
	
	if(value)
		leftsNeeded += StrLen(value)
	
	Send, {Left %leftsNeeded%}
}

; Subscripts will be added onto the end of "Switch", and should be in an array.
buildKHDFCommand(command = "", value = "", ByRef extraLeftsNeeded = 0, subs = "") {
	global epicKHDFStart
	outStr := ""
	quote := """"
	
	if(command)
		outStr .= command " "
	
	outStr .= epicKHDFStart
	For i,s in subs {
		outStr .= "," quote s quote
		if((i = subs.MaxIndex()) && (s = "")) {
			extraLeftsNeeded += 1
			if(command)
				extraLeftsNeeded += 1
		}
	}
	
	if(command)
		outStr .= ")"
	
	if(value || (command = "s")) {
		outStr .= "="
		if(extraLeftsNeeded)
			extraLeftsNeeded += 1
	}
	
	if(value)
		outStr .= value
	
	return outStr
}

buildCodeSearchURL(searchType, criteria = "", appID = 0, inline = false, exact = false, logic = "", case = false, nameFilter = 0, nameFilterText = "", perPage = 50) {
	versionID := 10
	showAll := 0 ; Whether to show every single matched line per result shown.
	
	; Gotta have some sort of criteria to open a search.
	if(!criteria || (searchType = ""))
		return ""
	
	; Basic URL, without parameters
	outURL := codeSearchBase searchType	codeSearchEnd versionID
	
	; Add the search criteria.
	i := 97 ; start at 'a'
	For j,c in criteria {
		Transform, letter, Chr, %i%
		outURL .= "&" letter "=" c
		i++
	}
	
	; Add on parameters.
	outURL .= "&applicationid="  appID
	outURL .= "&inline="         inline
	outURL .= "&exact="          exact
	outURL .= "&logic="          logic
	outURL .= "&case="           case
	outURL .= "&namefilter="     nameFilter
	outURL .= "&namefiltertext=" nameFilterText
	outURL .= "&perPage="        perpage
	outURL .= "&showall="        showall
	
	return outURL
}

buildGuruURL(criteria) {
	outURL := guruSearchBase
	
	return outURL criteria
}

; Within an Epic environment list window (title is usually "Connection Status"), pick the given environment by name (exact name match).
; For remote (Citrix) windows, it won't select the specific environment, but will pick the given environment group and focus the environment list.
pickEnvironment(envName, envGroup = "<All Environments>") {
	; Figure out if we're dealing with a local or remote (like Citrix) window.
	isLocal := !(exeActive("WFICA32.EXE") || exeActive("mstsc.exe")) ; Citrix, remote desktop
	
	; DEBUG.popup("epic", "pickEnvironment", "Environment name", envName, "Group", envGroup, "Current window is local", isLocal)

	; If you're local, make sure that the group listbox is focused.
	; Note that for Citrix, we have to assume the group listbox is focused (which it typically is by default).
	if(isLocal)
		ControlFocus, ThunderRT6ComboBox1, A
	
	SendRaw, %envGroup% ; Pick the given environment group (or <All Environments> by default)
	Send, {Tab}{Home}   ; Focus environment list and start at the top
	
	if(isLocal) {
		Loop, 5 { ; Try a few times in case it's a large environment list for the group.
			Sleep, 500
			
			; Get the list from the listbox.
			ControlGet, envList, List, , ThunderRT6ListBox1, A ; List doesn't support Selected option, so we'll have to figure it out ourselves.		
			if(envList)
				Break
		}
		; DEBUG.popup("Finished trying to get the environment list", envList)
		
		; Parse through list to find where our desired environment is.
		Loop, Parse, envList, `n ; Each line is an entry in the list.
		{
			if(A_LoopField = envName) {
				countFromTop := A_Index - 1
				Break
			}
		}
		; DEBUG.popup("Environment list raw", envList, "Looking for", envName, "Found at line-1", countFromTop)
		
		Send, {Down %countFromTop%} ; Down as many times as needed to hit the desired row.
	}
}



getEMC2Info(ByRef ini = "", ByRef id = "", windowTitle = "A") {
	text := gatherText(TEXT_SOURCE_TITLE, "", windowTitle)
	
	; If no info available, finish here.
	if((text = "") or (text = "EMC2"))
		return
	
	; Split the input.
	titleSplit := StrSplit(text, "-")
	text := SubStr(titleSplit[1], 1, -1) ; Trim off the trailing space.
	
	objInfo := StrSplit(text, A_Space)
	ini := objInfo[1]
	id := objInfo[2]
	
	; DEBUG.popup("getEMC2Info", "Finish", "Source", source, "INI", ini, "ID", id)
}
