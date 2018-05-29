; Hotkeys for opening different locations, both local (folders) and remote (URLs).

; Specific folders
!+a::openFolder("AHK_ROOT")
!+m::openFolder("MUSIC")
!+d::openFolder("DOWNLOADS")
!+u::openFolder("USER_ROOT")

; Open folder from list
^+!w::
	doSelectFolder() {
		folderPath := selectFolder()
		if(FileExist(folderPath))
			Run(folderPath)
	}

; Send cleaned-up path:
; - Turn network paths into their drive-mapped equivalents
; - Remove file:///, quotes, and other garbage from around the path.
!+p::sendCleanedUpPath()
!+#p::sendCleanedUpPath(true)
sendCleanedUpPath(containingFolderOnly := false) {
	path := getFirstLineOfSelectedText()
	if(!path) ; Fall back to clipboard if nothing selected
		path := clipboard
	
	path := cleanupPath(path)
	path := mapPath(path)
	
	if(containingFolderOnly)
		path := reduceFilepath(path, 1) "\" ; Remove last element at end, add trailing slash
	
	sendTextWithClipboard(path)
}


; Sites
^+!a::
	openAllSites() {
		Run("https://mail.google.com/mail/u/0/#inbox")
		Sleep, 100
		Run("http://www.facebook.com/")
		Sleep, 100
		Run("http://www.reddit.com/")
		Sleep, 100
		Run("http://feedly.com/i/latest")
	}

^+!m::Run("https://www.messenger.com")
^+!f::Run("http://feedly.com/i/latest")
^!#m::Run("https://mail.google.com/mail/u/0/#inbox")
!+o:: Run("https://www.onenote.com/notebooks?auth=1&nf=1&fromAR=1")
!+t:: Run(MainConfig.getPrivate("ONENOTE_ONLINE_DO_SECTION"))
