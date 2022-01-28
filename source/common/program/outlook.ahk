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
	; DESCRIPTION:    Get the title for the email message in the specified window.
	; RETURNS:        The title, cleaned up (RE:/FW: and any other odd characters removed)
	;---------
	getMessageTitle(titleString := "A") {
		title := ControlGetText(this.ClassNN_MailSubject_View, titleString) ; Most cases this control has the subject
		if(title = Config.private["WORK_EMAIL"]) ; The exception is editing in a popup: we need to use a different control, but the original still exists with my email in it.
			title := ControlGetText(this.ClassNN_MailSubject_Edit, titleString)
		
		if(title = "") {
			Toast.ShowError("Copy title failed", "Could not get title from message control")
			return
		}
		
		; Remove the extra email stuff.
		; Note: any Epic-record-specific stuff should live in either ActionObjectEMC2 or EpicRecord instead of here.
		return title.clean(["RE:", "FW:"])
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
	; DESCRIPTION:    Put the current email message's title on the clipboard, cleaning it up as needed.
	;---------
	copyCurrentMessageTitle() {
		title := this.getCurrentMessageTitle()
		ClipboardLib.setAndToast(title, "title")
	}
	;---------
	; DESCRIPTION:    If the current email message's title describes an EMC2 object, open that object in web mode.
	;---------
	openEMC2ObjectFromCurrentMessageWeb() {
		title := this.getCurrentMessageTitle()
		new ActionObjectEMC2(title).openWeb()
	}
	;---------
	; DESCRIPTION:    If the current email message's title describes an EMC2 object, open that object in edit mode.
	;---------
	openEMC2ObjectFromCurrentMessageEdit() {
		title := this.getCurrentMessageTitle()
		new ActionObjectEMC2(title).openEdit()
	}
	
	;---------
	; DESCRIPTION:    Copy the EMC2 record ID from the currently-selected calendar event to the clipboard.
	;---------
	copyEMC2ObjectFromEvent() {
		eventTitle := SelectLib.getText()
		if(eventTitle = "")
			return
		
		record := new EpicRecord(eventTitle)
		if(record.id)
			ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	
	;---------
	; DESCRIPTION:    Copy the EMC2 record ID from the currently-selected TLG event to the clipboard.
	;---------
	copyEMC2ObjectFromTLG() {
		tlgString := SelectLib.getText()
		if(tlgString = "")
			return
		
		record := new EpicRecord().initFromTLGString(tlgString)
		if(record.id)
			ClipboardLib.setAndToast(record.id, "EMC2 " record.ini " ID")
	}
	;---------
	; DESCRIPTION:    Open the EMC2 record described in the currently selected TLG event in web.
	;---------
	openEMC2ObjectFromTLGWeb() {
		tlgString := SelectLib.getText()
		if(tlgString = "")
			return
		
		record := new EpicRecord().initFromTLGString(tlgString)
		new ActionObjectEMC2(record.id, record.ini).openWeb()
	}
	;---------
	; DESCRIPTION:    Open the EMC2 record described in the currently selected TLG event in edit mode.
	;---------
	openEMC2ObjectFromTLGEdit() {
		tlgString := SelectLib.getText()
		if(tlgString = "")
			return
		
		record := new EpicRecord().initFromTLGString(tlgString)
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
	; DESCRIPTION:    Get the title for the current email message.
	; RETURNS:        The title, cleaned up (RE:/FW: and any other odd characters removed)
	;---------
	getCurrentMessageTitle() {
		return this.getMessageTitle("A")
	}
	; #END#
}
