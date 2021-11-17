; Hotkeys for opening different locations, both local (folders) and remote (URLs).

; [[Local/Remote Paths]] --=
; Specific folders
 !+a::openPath("AHK_ROOT")
$!+d::openPath("USER_DOWNLOADS")
 !+u::openPath("USER_ROOT")
openPath(folderName) {
	folderPath := Config.path[folderName]
	if(FileLib.folderExists(folderPath))
		Run(folderPath)
}

; Open folder from list
^!+w::
	selectFolder() {
		folderPath := new Selector("folders.tls").selectGui("PATH")
		folderPath := Config.replacePathTags(folderPath)
		
		if(folderPath = "")
			return
		folderPath := DateTimeLib.replaceTags(folderPath) ; For any date/time-based folder paths, use the current date/time.
		
		; If the folder doesn't exist, try to create it (with permission from user)
		if(!FileLib.folderExists(folderPath)) {
			if(!FileLib.folderExists(FileLib.getParentFolder(folderPath))) {
				new ErrorToast("Could not open chosen folder", "Neither the folder nor its parent folder exist.").showMedium()
				return ; Not going to try creating if not even the parent exists.
			}
			
			if(GuiLib.showConfirmationPopup("This folder does not exist:`n" folderPath "`n`nCreate it?", "Folder does not exist"))
				FileCreateDir, % folderPath
		}
		if(FileLib.folderExists(folderPath))
			Run(folderPath)
	}

; Send cleaned-up path (remove odd garbage from around path, switch to mapped network drives)
!+p:: sendCleanedUpPath()
!+#p::sendCleanedUpPath(true)
sendCleanedUpPath(containingFolderOnly := false) {
	path := FileLib.cleanupPath(clipboard)
	
	if(containingFolderOnly)
		path := FileLib.getParentFolder(path) "\" ; Remove last element at end, add trailing slash
	
	SendRaw, % path
}

; Selector to allow easy editing of config or code files that we edit often
!+c::
	selectEditFile() {
		path := new Selector("editFiles.tls").selectGui("PATH")
		if(!path)
			return
		
		path := Config.replacePathTags(path)
		if(!FileExist(path)) {
			new ErrorText("Script does not exist: " path).showMedium()
			return
		}
		
		Config.runProgram("Notepad++", path)
	}


; [[Websites]] ===
$^!+f::Run("http://feedly.com/i/latest") ; $ as Notepad++ highlight-all hotkey sends these keys
^!#m:: Config.runProgram("Gmail")
^!+a::
	openUsualSites() {
		Config.runProgram("Gmail")
		Sleep, 100
		Run("http://old.reddit.com/")
		Sleep, 100
		Run("http://feedly.com/i/latest")
	}

; OneNote Online
!+o:: Run("https://www.onenote.com/notebooks")
!+#t::Run(Config.private["ONENOTE_ONLINE_NOTEBOOK_DO"])
; =--
