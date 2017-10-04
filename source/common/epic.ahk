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
	
	getRelatedQANsAry() {
		if(!isWindowInState("active","DLG  ahk_class ThunderRT6MDIForm ahk_exe EpicD82.exe"))
			return ""
		if(!isWindowInState("active"," - EMC2","",2))
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
		For i,qan in relatedQANsAry {
			link := ActionObject.do(qan, TYPE_EMC2, ACTION_LINK, "QAN", SUBACTION_WEB)
			if(link)
				urlsAry.push(link)
		}
		
		return urlsAry
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
	exeName := MainConfig.getProgram("EpicStudio", "EXE")
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
	exeName := MainConfig.getProgram("EpicStudio", "EXE")
	WinWaitActive, ahk_exe %exeName%
	
	Send, ^!e
	WinWaitActive, Open DLG
	
	Send, ^a
	Send, {Delete} ; Make sure the DLG that defaults in it cleared before we add our own.
	Send, % dlgNum
	Send, {Enter 2}
}

doMForLoop() {
	prompt := "Enter the variables involved in this format: `n`t<LOOP_ARY_NAME>,<ITERATOR1>[,<ITERATOR2>,<ITERATOR3>...]"
	InputBox, loopInfo, Generate M for loop, %prompt%,  , 500, 145
	
	splitLoopInfo := StrSplit(loopInfo, ",")
	
	iteratorsAry := []
	for i,data in splitLoopInfo {
		if(i = 1)
			loopAryName := data
		else
			iteratorsAry.push(data)
	}
	
	loopString := buildMForLoopString(loopAryName, iteratorsAry)
	sendTextWithClipboard(loopString)
}

getEpicAppIdFromKey(appKey) {
	global epicAppKeyToIdAry
	if(!appKey)
		return 0
	return epicAppKeyToIdAry[appKey]
}

buildHyperspaceRunString(versionMajor, versionMinor, environment) {
	global epicExeBase
	runString := epicExeBase
	
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

buildCodeSearchURL(searchType, criteria = "", appKey = "", inline = false, exact = false, logic = "", case = false, nameFilter = 0, nameFilterText = "", perPage = 50) {
	versionID := 10
	showAll := 0 ; Whether to show every single matched line per result shown.
	
	appId := getEpicAppIdFromKey(appKey)
	
	; DEBUG.popup("buildCodeSearchURL", "Start", "Search type", searchType, "Criteria", criteria, "App key", appKey, "App ID", appId, "Inline", inline, "Exact", exact, "Logic", logic, "Case", case, "Name filter", nameFilter, "Name filter text", nameFilterText, "Per page", perPage)
	
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
	outURL .= "&applicationid="  appId
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

buildEpicWikiSearchURL(category, criteria) {
	outURL := epicWikiSearchBase
	outURL := RegExReplace(outURL, "<QUERY>", criteria)
	
	if(category) {
		outURL .= epicWikiSearchFilters
		outURL := RegExReplace(outURL, "<CATEGORIES>", "'" category "'")
	}
	
	return outURL
}

; ini/id defaults are "X" as a dummy - URL will still connect to desired environment (and show an error popup).
buildSnapperURL(environment, ini = "", idList = "") { ; idList is a comma-separated list of IDs
	if(!environment)
		return ""
	
	if(!ini && !id) { ; These aren't be parameter defaults in case of blank parameters (not simply not passed at all)
		ini    := "X"
		idList := "X"
	}
	
	if(stringContains(idList, ","))
		idAry := StrSplit(idList, ",")
	else
		idAry := [idList]
	
	outURL := snapperURLBase
	For i,id in idAry {
		; DEBUG.popup("Index", i, "ID", id)
		if(!id)
			Continue
		
		outURL .= ini "." id "." environment "/"
	}
	
	return outURL
}

buildVDIRunString(vdiId) {
	global epicVDIBase
	runString := epicVDIBase
	
	runString := RegExReplace(runString, "<VDI_ID>", vdiId)
	
	return runString
}

; iteratorsAry is array of variables to loop in nested for loops, in top-down order.
buildMForLoopString(loopAryName, iteratorsAry) {
	; DEBUG.popup("Loop array name", loopAryName, "Iterators array", iteratorsAry)
	
	retStr := ""
	prevIterators := ""
	numIndents := 0
	
	for i,iterator in iteratorsAry {
		retStr .= "f  s " iterator "=$o(" loopAryName "(" prevIterators iterator ")) q:" iterator "=""""  d `n"
		prevIterators .= iterator ","
		numIndents++
		
		retStr .= "`t"
		Loop, % numIndents {
			retStr .= ". "
		}
	}
	
	return retStr
}



getEMC2Info(ByRef ini = "", ByRef id = "", windowTitle = "A") {
	WinGetTitle, title, %windowTitle%
	
	; If no info available, finish here.
	if((title = "") or (title = "EMC2"))
		return
	
	; Split the input.
	titleSplit := StrSplit(title, "-")
	title := SubStr(titleSplit[1], 1, -1) ; Trim off the trailing space.
	
	objInfo := StrSplit(title, A_Space)
	ini := objInfo[1]
	id := objInfo[2]
	
	; DEBUG.popup("getEMC2Info", "Finish", "Source", source, "INI", ini, "ID", id)
}
