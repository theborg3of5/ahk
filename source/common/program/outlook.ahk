class Outlook {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Check whether the TLG calendar is currently active.
	; RETURNS:        true/false
	;---------
	isTLGCalendarActive() {
		return this.areAnyOfFoldersActive([this.TLGFolder])
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
	isCurrentScreenMailMessage() {
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
	
	
	; #PRIVATE#
	
	; The ClassNN for the control that contains the subject of the message. Should be the same for inline and popped-out messages.
	static ClassNN_MailSubject := "RichEdit20WPT7"
	
	; Folder names for different areas
	static TLGFolder := "TLG"
	static CalendarFolders := ["Calendar", "TLG"]
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
		title := ControlGetText(this.ClassNN_MailSubject, "A")
		if(title = "") {
			new ErrorToast("Copy title failed", "Could not get title from message control").showMedium()
			return
		}
		
		; Remove the extra email stuff
		return title.clean(["RE:", "FW:"])
	}
	; #END#
}
