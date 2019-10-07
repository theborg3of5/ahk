; Hotkeys for opening different locations, both local (folders) and remote (URLs).

; Specific folders
!+a::openFolder("AHK_ROOT")
!+d::openFolder("USER_DOWNLOADS")
!+u::openFolder("USER_ROOT")
openFolder(folderName) {
	folderPath := Config.path[folderName]
	if(folderExists(folderPath))
		Run(folderPath)
}

; Open folder from list
^+!w::
	selectFolder() {
		folderPath := new Selector("folders.tls").select(folderName, "PATH")
		folderPath := Config.replacePathTags(folderPath)
		
		if(folderPath = "")
			return
		folderPath := replaceDateTimeTags(folderPath) ; For any date/time-based folder paths, use the current date/time.
		
		; If the folder doesn't exist, try to create it (with permission from user)
		if(!folderExists(folderPath)) {
			if(!folderExists(getParentFolder(folderPath))) {
				new ErrorToast("Could not open chosen folder", "Neither the folder nor its parent folder exist.").showMedium()
				return ; Not going to try creating if not even the parent exists.
			}
			
			if(showConfirmationPopup("This folder does not exist:`n" folderPath "`n`nCreate it?", "Folder does not exist"))
				FileCreateDir, % folderPath
		}
		if(folderExists(folderPath))
			Run(folderPath)
	}

; Send cleaned-up path (remove odd garbage from around path, switch to mapped network drives)
!+p::sendCleanedUpPath()
!+#p::sendCleanedUpPath(true)
sendCleanedUpPath(containingFolderOnly := false) {
	path := cleanupPath(clipboard)
	
	if(containingFolderOnly)
		path := getParentFolder(path) "\" ; Remove last element at end, add trailing slash
	
	SendRaw, % path
}


; Websites
^+!m:: Run("https://www.messenger.com")
$^+!f::Run("http://feedly.com/i/latest")
^!#m:: Run("https://mail.google.com/mail/u/0/#inbox")
^+!a::
	openUsualSites() {
		Run("https://mail.google.com/mail/u/0/#inbox")
		Sleep, 100
		Run("http://www.facebook.com/")
		Sleep, 100
		Run("http://old.reddit.com/")
		Sleep, 100
		Run("http://feedly.com/i/latest")
	}

; OneNote Online
!+o:: Run("https://www.onenote.com/notebooks?auth=1&nf=1&fromAR=1")
!+t:: Run(Config.private["ONENOTE_ONLINE_NOTEBOOK_DO"])
!+#t::Run(Config.private["ONENOTE_ONLINE_NOTEBOOK_LIFE"])
