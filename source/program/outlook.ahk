; Outlook Hotkeys.

; Program in general
#If Config.isWindowActive("Outlook")
	; Move selected message(s) to a particular folder, and mark them as read.
	$^e::Send, ^+1 ; Archive
	^+w::Send, ^+2 ; Wait
	^+l::Send, ^+3 ; Later use
	
	; Format as code (using custom styles)
	^+c::Send, ^!+2 ; Hotkey used in Outlook (won't let me use ^+c directly)
	
	; Bulleted list
	^.::^+l
#If

; Mail folders
#If Config.isWindowActive("Outlook") && (Outlook.IsCurrentScreenMail() || Outlook.IsCurrentScreenMailMessage())
	; Copy current message title to clipboard
	!c::Outlook.CopyCurrentMessageTitle()
	
	; Open the relevant record (if applicable) for the current message
	!w::Outlook.OpenEMC2ObjectFromCurrentMessageWeb()
	!e::Outlook.OpenEMC2ObjectFromCurrentMessageEdit()
#If

; Calendar folders
#If Config.isWindowActive("Outlook") && Outlook.IsCurrentScreenCalendar()
	; Shortcut to go to today on the calendar. (In desired, 3-day view.)
	^t::
		; Go to today.
		Send, !h
		Send, od
		
		; Single-day view.
		Send, !1
	return
	
	; Calendar view: week view.
	^w::Send, ^!3
	
	; Show a popup for picking an arbitrary calendar to display.
	^a::
		Send, !h
		Send, oc
		Send, a
	return
#If

; Universal new email.
#If Config.machineIsWorkLaptop
	^!m::Config.runProgram("Outlook", "/c ipm.note")
#If


class Outlook {
	; #PUBLIC#
	
	; The ClassNN for the control that contains the subject of the message. Should be the same for inline and popped-out messages.
	static MailSubjectControlClassNN := "RichEdit20WPT7"
	
	; Folder names for different areas
	static TLGFolder := "TLG"
	static CalendarFolders := ["Calendar", "TLG"]
	static MailFolders := ["Inbox", "Wait", "Later Use", "Archive", "Sent Items", "Drafts", "Deleted Items"]
	
	;---------
	; DESCRIPTION:    Determine whether the current screen is one of our mail folders.
	; RETURNS:        true/false
	;---------
	IsCurrentScreenMail() {
		return this.areAnyOfFoldersActive(this.MailFolders)
	}
	
	;---------
	; DESCRIPTION:    Determine whether the current window is a mail message popup
	; RETURNS:        The window ID/false
	;---------
	IsCurrentScreenMailMessage() {
		settings := new TempSettings().titleMatchMode(TitleMatchMode.Contains)
		isMailMessage := WinActive("- Message (")
		settings.restore()
		
		return isMailMessage
	}
	
	;---------
	; DESCRIPTION:    Check whether the TLG calendar is currently active.
	; RETURNS:        true/false
	;---------
	IsTLGCalendarActive() {
		return this.areAnyOfFoldersActive([this.TLGFolder])
	}
	
	;---------
	; DESCRIPTION:    Determine whether the current screen is one of our calendar folders.
	; RETURNS:        true/false
	;---------
	IsCurrentScreenCalendar() {
		return this.areAnyOfFoldersActive(this.CalendarFolders)
	}
	
	;---------
	; DESCRIPTION:    Put the current email message's title on the clipboard, cleaning it up as needed.
	;---------
	CopyCurrentMessageTitle() {
		title := this.getCurrentMessageTitle()
		ClipboardLib.setAndToast(title, "title")
	}
	
	;---------
	; DESCRIPTION:    If the current email message's title describes an EMC2 object, open that object in web mode.
	;---------
	OpenEMC2ObjectFromCurrentMessageWeb() {
		title := this.getCurrentMessageTitle()
		new ActionObjectEMC2(title).openWeb()
	}
	
	;---------
	; DESCRIPTION:    If the current email message's title describes an EMC2 object, open that object in edit mode.
	;---------
	OpenEMC2ObjectFromCurrentMessageEdit() {
		title := this.getCurrentMessageTitle()
		new ActionObjectEMC2(title).openEdit()
	}
	
	
	; #PRIVATE#
	
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
		title := ControlGetText(this.MailSubjectControlClassNN, "A")
		if(title = "") {
			new ErrorToast("Copy title failed", "Could not get title from message control").showMedium()
			return
		}
		
		; Remove the extra email stuff
		return title.clean(["RE:", "FW:"])
	}
	; #END#
}
