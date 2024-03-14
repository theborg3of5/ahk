class Outlook {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Check whether the TLG calendar is currently active.
	; RETURNS:        true/false
	;---------
	isTLGCalendarActive() {
		return this.areAnyOfFoldersActive([this.TLGFolder])
	}
	
	;---------
	; DESCRIPTION:    Check whether the normal calendar is currently active.
	; RETURNS:        true/false
	;---------
	isNormalCalendarActive() {
		return this.areAnyOfFoldersActive([this.CalendarFolder])
	}
	
	;---------
	; DESCRIPTION:    Get message titles from all Outlook windows (main or popups).
	; RETURNS:        Array of found window titles.
	;---------
	getAllMessageTitles() {
		titles := []
		
		For _,windowId in WinGet("List", Config.windowInfo["Outlook"].titleString) {
			idString := "ahk_id " windowId
			if(!WindowLib.isVisible(idString)) ; Skip hidden windows
				Continue

			title := this.getMessageTitle(idString)
			if(title)
				titles.push(title)
		}
		
		return titles
	}
	
	
	; #INTERNAL#

	;---------
	; DESCRIPTION:    Flag for whether dark mode is currently on.
	;---------
	darkModeOn := true
	
	;---------
	; DESCRIPTION:    Determine whether the current screen is one of our mail folders.
	; RETURNS:        true/false
	;---------
	toggleDarkMode() {
		; Always on the "Home" ("Message" for email popup, but still same hotkey) tab.
		Send, !h

		; It's two separate buttons with the simplified/short ribbon, so we have to keep track ourselves.
		this.darkModeOn := !this.darkModeOn

		; Hotkeys differ based on the context as well.
		if(this.isMailMessagePopupActive()) {
			if(this.darkModeOn)
				Send, b1 ; Switch Background (to light mode)
			else
				Send, b2 ; Switch Background (to dark mode)
		} else {
			if(this.darkModeOn)
				Send, y1 ; Switch Background (to light mode)
			else
				Send, y2 ; Switch Background (to dark mode)
		}
	}
	
	;---------
	; DESCRIPTION:    Determine whether the current screen is one of our mail folders.
	; RETURNS:        true/false
	;---------
	isCurrentScreenMail() {
		return this.areAnyOfFoldersActive(this.MailFolders)
	}
	
	;---------
	; DESCRIPTION:    Determine whether the current screen is one of our calendar folders.
	; RETURNS:        true/false
	;---------
	isCurrentScreenCalendar() {
		return this.areAnyOfFoldersActive(this.CalendarFolders)
	}
	
	;---------
	; DESCRIPTION:    Determine whether the current window is a mail message popup
	; RETURNS:        The window ID/false
	;---------
	isMailMessagePopupActive() {
		settings := new TempSettings().titleMatchMode(TitleMatchMode.Contains)
		isMailMessage := WinActive("- Message (")
		settings.restore()
		
		return isMailMessage
	}
	
	;---------
	; DESCRIPTION:    Get the title for the email message in the specified window.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string identifying the window to use. Defaults to active window ("A").
	; RETURNS:        The title, cleaned up (RE:/FW: and any other odd characters removed)
	;---------
	getMessageTitle(titleString := "A") {
		title := ControlGetText(this.ClassNN_MailSubject_View, titleString) ; Most cases this control has the subject
		if(title = Config.private["WORK_EMAIL"]) ; The exception is editing in a popup: we need to use a different control, but the original still exists with just my email in it.
			title := ControlGetText(this.ClassNN_MailSubject_Edit, titleString) ; Yes, we could use the window title instead if we wanted, but this doesn't give us an extra suffix.
		if(title = "") ; If that didn't turn anything up, fall back to the window title.
			title := WinGetTitle(titleString)

		return this.cleanUpTitle(title)
	}
	
	;---------
	; DESCRIPTION:    Copy the EMC2 record ID from the currently-selected (non-TLG) calendar event to the clipboard.
	;---------
	copyEMC2RecordIDFromEvent() {
		record := this.getEMC2ObjectFromCalendarEvent()
		if(record)
			ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	
	;---------
	; DESCRIPTION:    Get an EMC2 object using the selected TLG event's title.
	; RETURNS:        A new ActionObjectEMC2 instance, or "" if we didn't find any valid EMC2 record.
	;---------
	getEMC2ObjectFromCalendarEvent() {
		eventTitle := SelectLib.getText()
		eventTitle := this.cleanUpTitle(eventTitle)
		return new ActionObjectEMC2(eventTitle)
	}
	
	;---------
	; DESCRIPTION:    Copy the EMC2 object string from the currently-selected TLG event to the clipboard.
	;---------
	copyEMC2ObjectStringFromTLG() {
		record := this.getEMC2RecordFromTLG()
		objectString := EpicLib.buildEMC2ObjectString(record)
		ClipboardLib.setAndToast(objectString, "TLG event EMC2 object string")
	}
	
	;---------
	; DESCRIPTION:    Get an EMC2 object using the selected TLG event's title.
	; RETURNS:        A new ActionObjectEMC2 instance, or "" if we didn't find any valid EMC2 record.
	;---------
	getEMC2ObjectFromTLG() {
		record := this.getEMC2RecordFromTLG()
		if(!record)
			return ""
		
		return new ActionObjectEMC2(record.id, record.ini)
	}

	;---------
	; DESCRIPTION:    Insert a TLG event into that calendar based on the user's selected TLP/record.
	;---------
	selectOutlookTLG() {
		s := new Selector("tlg.tls").setTitle("Select EMC2 Record ID")
		s.dataTableList.filterOutIfColumnNoMatch("IS_OLD", "") ; Filter out old records (have a value in the OLD column)
		data := s.selectGui()
		if(!data)
			return
		
		; We can do an additional Selector popup to grab ID (and potentially title) from various window titles.
		recId := data["RECORD"]
		if(recId = "GET") {
			record := EpicLib.selectEMC2RecordFromUsefulTitles(true) ; true - only want options with a title.
			if(!record)
				return
			
			recId := record.id
			if(["PRJ", "QAN", "SLG"].contains(record.ini))
				recId := record.ini.charAt(1) "." recId ; Add on the INI prefix so the ID goes in the right position.
			
			if(record.title)
				data["NAME"] := record.title
		}
		if(recId = "-") ; Placeholder I can manually enter to force a blank value.
			recId := ""
		
		; Message is a combination of a few things
		message := data["NAME_OUTPUT_PREFIX"] ; Start with any given prefix
		if(data["IS_GENERIC"]) 
			message .= data["MESSAGE"] ? data["MESSAGE"] : data["NAME"] ; Generic TLPs - use add the message, defaulting to the name.
		else ; Everything else: 
			message .= data["NAME"].appendPiece(" - ", data["MESSAGE"]) ; Everything else: add name + message.
		
		; Record field can contain DLG (no prefix), PRJ (P.), QAN (Q.), or SLG (S.) IDs.
		if(recId.startsWith("P."))
			prjId := recId.removeFromStart("P.")
		else if(recId.startsWith("Q."))
			qanId := recId.removeFromStart("Q.")
		else if(recId.startsWith("S."))
			slgId := recId.removeFromStart("S.")
		else
			dlgId := recId
		
		; Build the event title string
		eventTitle := Config.private["OUTLOOK_TLG_BASE"]
		eventTitle := eventTitle.replaceTag("MESSAGE",  message) ; Replace the message first in case it contains any of the following tags
		eventTitle := eventTitle.replaceTag("TLP",      data["TLP"])
		eventTitle := eventTitle.replaceTag("CUSTOMER", data["CUSTOMER"])
		eventTitle := eventTitle.replaceTag("SLG",      slgId)
		eventTitle := eventTitle.replaceTag("DLG",      dlgId)
		eventTitle := eventTitle.replaceTag("PRJ",      prjId)
		eventTitle := eventTitle.replaceTag("QAN",      qanId)
		
		this.replaceExtraEventTitleSlashes(eventTitle)
		
		if(this.isTLGCalendarActive()) {
			SendRaw, % eventTitle
			Send, {Enter}
		} else {
			ClipboardLib.setAndToastError(eventTitle, "event string", "Outlook TLG calendar not focused.")
		}
	}
	
	
	; #PRIVATE#
	
	; The ClassNN for the control that contains the subject of the message. Should be the same for inline and popped-out messages.
	static ClassNN_MailSubject_View := "RichEdit20WPT1" ; Most view and edit cases have the subject in this control
	static ClassNN_MailSubject_Edit := "RichEdit20WPT5" ; This is for editing in a popup - subject is in a different control
	
	; Folder names for different areas
	static TLGFolder := "TLG"
	static CalendarFolder := "Calendar"
	static CalendarFolders := [ Outlook.TLGFolder, Outlook.CalendarFolder ]
	static MailFolders := [ "Inbox", "Wait", "Later Use", "Archive", "Sent Items", "Drafts", "Deleted Items" ]
	
	;---------
	; DESCRIPTION:    Determine whether any of the folders in the given array are currently active.
	; PARAMETERS:
	;  folders (I,REQ) - An array of folder names.
	; RETURNS:        true if any of the folder names is the active one, false otherwise.
	;---------
	areAnyOfFoldersActive(folders) {
		For _,folderName in folders {
			windowTitle := folderName " - " Config.private["WORK_EMAIL"] " - Outlook"
			if(WinActive(windowTitle))
				return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Clean up the provided message title. Gets rid of garbage and massages certain EMC2 record titles to
	;                 make it easier for downstream logic to handle them.
	; PARAMETERS:
	;  value (I,REQ) - The message title to clean up.
	; RETURNS:        Cleaned-up title
	;---------
	cleanUpTitle(value) {
		; Remove reply/forward garbage, it's never helpful to include.
		value := value.removeFromStart("RE: ")
		value := value.removeFromStart("FW: ")
		
		; Do some special cleanup for EMC2 record titles, to make them easier for downstream logic to work with.
		
		; Project readiness is obviously about the PRJ in question
		value := value.replace("PRJ Readiness ", "PRJ ")
		value := value.replace("Project Readiness ", "PRJ ")
		value := value.replace("[Readiness Approval Request] ", "PRJ ")
		
		; Release note review is about the DRN
		value := value.replace("Release Note Review: ", "DRN ")
		value := value.replace("Revisions Made to Release Note: ", "DRN ")

		; Special QAN processes
		value := value.replace("RCA ", "QAN ")
		
		; EMC2 lock emails have stuff in a weird order: "EMC2 Lock: <title> [<ini>] <id> is locked"
		if(value.startsWith("EMC2 Lock: ")) {
			value := value.removeFromStart("EMC2 Lock: ").removeFromEnd(" is locked")
			title := value.beforeString(" [")
			id    := value.afterString("] ")
			ini   := value.firstBetweenStrings(" [", "] ")
			
			; This isn't a true INI - it's words describing the INI instead. Convert it to the true INI for easier handling downstream.
			if(ini = "Main") ; Yes, this is weird. Not sure why it uses "Main", but it's distinct from the others so it works.
				ini := "QAN"
			ini := EpicLib.convertToUsefulEMC2INI(ini)
			
			value := ini " " id " - " title
		}
		
		; Other strings that get mixed up in record titles
		; Status updates
		value := value.removeRegEx("\(.*(Reviewer|Developer|Changes Necessary).*\) ")
		; SLGs
		value := value.beforeString("--Assigned To: ")
		; DLGs
		value := value.remove("(Advanced with Open Issues) ")
		
		return value
	}
	
	;---------
	; DESCRIPTION:    Get the first EMC2 record encoded in the selected TLG event's title.
	; RETURNS:        EpicRecord instance from the event (or "" if no event found).
	;---------
	getEMC2RecordFromTLG() {
		tlgString := SelectLib.getText()
		if(!tlgString)
			return ""
		
		baseAry := Config.private["OUTLOOK_TLG_BASE"].split(["/", ","])
		tlgAry  := tlgString.split(["/", ","])

		; Grab title from the end (its actual index in the base string might vary)
		title := tlgString.afterString(",").withoutWhitespace()
		
		For _,ini in ["SLG", "DLG", "PRJ", "QAN"] {
			iniIndex := baseAry.contains("<" ini ">")
			id := tlgAry[iniIndex]

			if(id != "")
				return new EpicRecord(ini, id, title)
		}
	}

	;---------
	; DESCRIPTION:    Reduce the extra slashes in the TLG event title for easier reading and a
	;                 cleaner look. We only need slashes before the last non-blank element
	;                 before the comma (i.e. always 1 after the TLP, but after that we only need
	;                 enough to put the last element in the right spot). Remove the extras to
	;                 clean up the display.
	; PARAMETERS:
	;  title (IO,REQ) - The event title to clean up
	;---------
	replaceExtraEventTitleSlashes(ByRef title) {
		idString := title.beforeString(", ")
		message := title.afterString(", ")
		
		Loop {
			if(!idString.endsWith("/")) ; Should only remove trailing slashes, not anything at the start or in the middle.
				Break
			if(idString.countMatches("/") <= 1) ; Keep at least one slash (after the TLP) for conditional formatting to use.
				Break
			idString := idString.removeFromEnd("/")
		}
		
		; String it back together to return.
		title := idString ", " message
	}
	; #END#
}
