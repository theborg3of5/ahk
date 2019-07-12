; Hotkeys for opening different locations, both local (folders) and remote (URLs).

; Specific folders
!+a::openFolder("AHK_ROOT")
!+d::openFolder("USER_DOWNLOADS")
!+u::openFolder("USER_ROOT")

; Open folder from list
^+!w::
	doSelectFolder() {
		folderPath := selectFolder()
		if(folderPath = "")
			return
		folderPath := replaceDateTimeTags(folderPath) ; For any date/time-based folder paths, use the current date/time.
		
		; If the folder doesn't exist, try to create it (with permission from user)
		if(!folderExists(folderPath)) {
			if(!folderExists(getParentFolder(folderPath))) {
				Toast.showError("Could not open chosen folder", "Neither the folder nor its parent folder exist.")
				return ; Not going to try creating if not even the parent exists.
			}
			
			if(showConfirmationPopup("This folder does not exist:`n" folderPath "`n`nCreate it?", "Folder does not exist"))
				FileCreateDir, % folderPath
		}
		if(folderExists(folderPath))
			Run(folderPath)
	}

; Send cleaned-up path:
; - Remove file:///, quotes, and other garbage from around the path.
; - Turn network paths into their drive-mapped equivalents
!+p::sendCleanedUpPath()
!+#p::sendCleanedUpPath(true)
sendCleanedUpPath(containingFolderOnly := false) {
	path := getFirstLineOfSelectedText()
	if(!path) ; Fall back to clipboard if nothing selected
		path := clipboard
	
	path := cleanupPath(path)
	path := mapPath(path)
	
	if(containingFolderOnly)
		path := getParentFolder(path) "\" ; Remove last element at end, add trailing slash
	
	Send, % path
}


; Sites
^+!a::
	openAllSites() {
		Run("https://mail.google.com/mail/u/0/#inbox")
		Sleep, 100
		Run("http://www.facebook.com/")
		Sleep, 100
		Run("http://old.reddit.com/")
		Sleep, 100
		Run("http://feedly.com/i/latest")
	}

^+!m::Run("https://www.messenger.com")
^+!f::Run("http://feedly.com/i/latest")
^!#m::Run("https://mail.google.com/mail/u/0/#inbox")
!+o:: Run("https://www.onenote.com/notebooks?auth=1&nf=1&fromAR=1")
!+t:: Run(generateOneNoteOnlineURLForPrivateNotebook("ONENOTE_ONLINE_NOTEBOOK_ID_DO"))
!+#t::Run(generateOneNoteOnlineURLForPrivateNotebook("ONENOTE_ONLINE_NOTEBOOK_ID_SHARED"))

generateOneNoteOnlineURLForPrivateNotebook(notebookTagName) {
	baseURL         := "https://onedrive.live.com/edit.aspx?cid=<ONENOTE_ONLINE_CID>&resid=<ONENOTE_ONLINE_CID>!<NOTEBOOK_TAG>&app=OneNote"
	specificBaseURL := replaceTag(baseURL, "NOTEBOOK_TAG", "<" notebookTagName ">") ; Plug in the specific private tag that we were given, so that when we replace private tags we'll get everything at once.
	finalURL        := MainConfig.replacePrivateTags(specificBaseURL)
	
	; DEBUG.popup("Base URL",baseURL, "Specific base URL",specificBaseURL, "Final URL",finalURL)
	return finalURL
}