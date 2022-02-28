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
			title := this.getMessageTitle("ahk_id " windowId)
			if(title)
				titles.push(title)
		}
		
		return titles
	}
	
	
	; #INTERNAL#
	
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
		
		return this.cleanUpTitle(title)
	}
	
	;---------
	; DESCRIPTION:    Copy the EMC2 record ID from the currently-selected TLG event to the clipboard.
	;---------
	copyEMC2ObjectIDFromTLG() {
		tlgString := SelectLib.getText()
		if(tlgString = "")
			return
		
		record := this.getCurrentTLGRecord()
		if(record)
			ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	;---------
	; DESCRIPTION:    Open the EMC2 record described in the currently selected TLG event in web.
	;---------
	openEMC2ObjectFromTLGWeb() {
		tlgString := SelectLib.getText()
		if(tlgString = "")
			return
		
		record := this.getCurrentTLGRecord()
		if(record)
			new ActionObjectEMC2(record.id, record.ini).openWeb()
	}
	;---------
	; DESCRIPTION:    Open the EMC2 record described in the currently selected TLG event in edit mode.
	;---------
	openEMC2ObjectFromTLGEdit() {
		record := this.getCurrentTLGRecord()
		if(record)
			new ActionObjectEMC2(record.id, record.ini).openEdit()
	}
	
	
	; #PRIVATE#
	
	; The ClassNN for the control that contains the subject of the message. Should be the same for inline and popped-out messages.
	static ClassNN_MailSubject_View := "RichEdit20WPT1" ; Most view and edit cases have the subject in this control
	static ClassNN_MailSubject_Edit := "RichEdit20WPT5" ; This is for editing in a popup - subject is in a different control
	
	; Folder names for different areas
	static TLGFolder := "TLG"
	static CalendarFolder := "Calendar"
	static CalendarFolders := [this.TLGFolder, this.CalendarFolder]
	static MailFolders := ["Inbox", "Wait", "Later Use", "Archive", "Sent Items", "Drafts", "Deleted Items"]
	
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
		value := value.replace("PRJ Readiness ", "PRJ ") ; Needs to be slightly more specific - just removing "readiness" across the board is too broad.
		
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
		value := value.beforeString("--Assigned To: ") ; SLGs
		
		return value
	}
	
	;---------
	; DESCRIPTION:    Get the current EMC2 record encoded in the selected TLG event's title.
	; RETURNS:        EpicRecord instance from the event (or "" if no event found).
	;---------
	getCurrentTLGRecord() {
		tlgString := SelectLib.getText()
		if(!tlgString)
			return ""
		
		baseAry := Config.private["OUTLOOK_TLG_BASE"].split(["/", ","])
		tlgAry  := tlgString.split(["/", ","])
		
		recIDs := {}
		For _,ini in ["SLG", "DLG", "PRJ", "QAN"] {
			iniIndex := baseAry.contains("<" ini ">")
			id := tlgAry[iniIndex]
			
			if(id != "")
				return new EpicRecord(ini, id)
		}
	}
	; #END#
}
