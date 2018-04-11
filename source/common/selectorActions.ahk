; Central place for functions called from Selector.
; All of them should take just one argument, a SelectorRow object (defined in selectorRow.ahk), generally named data.

; Example function:
; EXAMPLE(data) {
	; column := data["COLUMN"]
	; id     := data["ID"]
	
	; ; Processing as needed
	; finishedResult := column " " id
	
	; Run(finishedResult)
; }


; == Return functions (just return the actionRow object or a specific piece of it) ==
; Just return the requested subscript (defaults to "DOACTION").
RET(data, subToReturn = "DOACTION") {
	val := data[subToReturn]
	return val
}

; Return data array, for when we want more than just one value back.
RET_DATA(data) {
	return data
}


; == Run functions (simply run DOACTION subscript of the actionRow object) ==
; Run the action.
DO(data) {
	action := data["DOACTION"]
	
	Run(action)
}


; == File operations ==
; Write to the windows registry.
REG_WRITE(data) {
	keyName   := data["KEY_NAME"]
	keyValue  := data["KEY_VALUE"]
	keyType   := data["KEY_TYPE"]
	rootKey   := data["ROOT_KEY"]
	regFolder := data["REG_FOLDER"]
	
	RegWrite, %keyType%, %rootKey%, %regFolder%, %keyName%, %keyValue%
}


; == Open specific programs / send built strings ==
; Run Hyperspace.
DO_HYPERSPACE(data) {
	environment  := data["COMM_ID"]
	versionMajor := data["MAJOR"]
	versionMinor := data["MINOR"]
	
	; Build run path.
	runString := buildHyperspaceRunString(versionMajor, versionMinor, environment)
	
	Run(runString)
}

; Send internal ID of an environment.
SEND_ENVIRONMENT_ID(data) {
	environmentId := data["ENV_ID"]
	
	Send, % environmentId
	Send, {Enter} ; Submit it too.
}

; Run something through Thunder, generally a text session or Citrix.
DO_THUNDER(data) {
	runString := ""
	thunderId := data["THUNDER_ID"]
	
	runString := MainConfig.getProgram("Thunder", "PATH") " " thunderId
	
	if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
		activateProgram("Thunder")
	else
		Run(runString)
}

; Run a VDI.
DO_VDI(data) {
	vdiId := data["VDI_ID"]
	
	; Build run path.
	runString := buildVDIRunString(vdiId)
	
	if(data["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
		runProgram("VMWareView")
	} else {
		if(!vdiId) ; Safety check - don't try to launch with no VDI specified (that's what the "LAUNCH" COMM_ID is for).
			return
		
		Run(runString)
		
		; Also fake-maximize the window once it shows up.
		WinWaitActive, ahk_exe vmware-view.exe, , 10, VMware Horizon Client ; Ignore the loading-type popup that happens initially with excluded title.
		if(ErrorLevel) ; Set if we timed out or if somethign else went wrong.
			return
		fakeMaximizeWindow()
	}
}

; Open an environment in Snapper using a dummy record.
DO_SNAPPER(data) {
	environment := data["COMM_ID"]
	ini         := data["INI"]
	idList      := data["ID"]
	
	url := buildSnapperURL(environment, ini, idList)
	
	if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
		runProgram("Snapper")
	else
		Run(url)
}

; Open a homebrew timer (script located in the filepath below).
TIMER(data) {
	time := data["TIME"]
	runString := MainConfig.getPath("AHK_ROOT") "\source\standalone\timer\timer.ahk " time
	
	Run(runString)
}


; == Other assorted action functions ==
; Call a phone number.
CALL(data) {
	num := data["NUMBER"]
	name := data["NAME"]
	
	callNumber(num, name)
}

; Resizes the active window to the given dimensions.
RESIZE(data) {
	width  := data["WIDTH"]
	height := data["HEIGHT"]
	ratioW := data["WRATIO"]
	ratioH := data["HRATIO"]
	
	if(ratioW)
		width  *= ratioW
	if(ratioH)
		height *= ratioH
	
	WinMove, A, , , , width, height
}

; Builds a string to add to a calendar event (with the format the outlook/tlg calendar needs to import happily into Delorean), then sends it and an Enter keystroke to save it.
OUTLOOK_TLG(data) {
	tlp      := data["TLP"]
	message  := data["MSG"]
	prjId    := data["PRJ"]
	dlgId    := data["DLG"]
	customer := data["CUST"]
	
	; DLG ID overrides PRJ if given, but either way only one comes through into string.
	if(dlgId)
		recId := dlgId
	else if(prjId)
		recId := "P." prjId
	
	; Sanity check - if the message is an EMC2 ID (or P.emc2Id) and the DLG is not, swap them.
	if(!isEMC2Id(recId) && (SubStr(recId, 1, 2) != "P.") ) {
		if(isEMC2Id(message)) {
			newDLG  := message
			message := recId
			recId   := newDLG
		}
	}
	textToSend := tlp "/" customer "///" recId ", " message
	
	SendRaw, % textToSend
	Send, {Enter}
}

; Builds and sends a string to exclude the items specified, for Snapper.
SEND_SNAPPER_EXCLUDE_ITEMS(data) {
	itemsList := data["STATUS_ITEMS"]
	
	itemsAry  := StrSplit(itemsList, ",")
	For i,item in itemsAry {
		if(i > 1)
			excludeItemsString .= ","
		excludeItemsString .= "-" item
	}
	
	Send, % excludeItemsString
	Send, {Enter}
}
