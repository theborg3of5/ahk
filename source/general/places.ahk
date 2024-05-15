; Hotkeys for opening different locations, both local (folders) and remote (URLs).

; Specific folders
 !+a::openPath("AHK_ROOT")
$!+d::openPath("USER_DOWNLOADS") ; $ because otherwise it conflicts with our Deluminate site-specific toggle hotkey in Chrome
 !+o::openPath("USER_ONEDRIVE")
 !+u::openPath("USER_ROOT")
openPath(folderName) {
	folderPath := Config.path[folderName]
	if(FileLib.folderExists(folderPath))
		Run(folderPath)
}

; Open folder from list
!+w::
	selectFolder() {
		folderPath := new Selector("folders.tls").setIcon(Config.getProgramPath("Explorer")).prompt("PATH")
		folderPath := Config.replacePathTags(folderPath)
		
		if(folderPath = "")
			return
		folderPath := DateTimeLib.replaceTags(folderPath) ; For any date/time-based folder paths, use the current date/time.
		
		; If the folder doesn't exist, try to create it (with permission from user)
		if(!FileLib.folderExists(folderPath)) {
			if(!FileLib.folderExists(FileLib.getParentFolder(folderPath))) {
				Toast.ShowError("Could not open chosen folder", "Neither the folder nor its parent folder exist.")
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
!+#p::sendCleanedUpPath(true) ; Force Unix path
sendCleanedUpPath(mapToUnix := false) {
	path := FileLib.cleanupPath(clipboard)

	if(mapToUnix)
		path := FileLib.mapWindowsPathToUnix(path)

	SendRaw, % path
}

; Selector to allow easy editing of config or code files that we edit often
!+c::
	selectEditFile() {
		path := new Selector("editFiles.tls").setIcon(Config.getProgramPath("VSCode")).prompt("PATH")
		if(!path)
			return
		
		path := Config.replacePathTags(path)
		if(!FileExist(path)) {
			Toast.ShowError("Script does not exist: " path)
			return
		}
		
		Config.runProgram("VSCode", path)
	}


;region Websites
^!+f:: Run("http://feedly.com/i/latest")
^!+m:: Config.runProgram("Gmail")
^!+#m::Config.runProgram("Messenger")
^!+a::
openUsualSites() {
	Config.runProgram("Gmail")
	Sleep, 100
	Run("https://lemmy.world/")
	Sleep, 100
	Run("http://feedly.com/i/latest")
}

; OneNote Online
!+t::Run(Config.private["ONENOTE_ONLINE_NOTEBOOK_DO"])
;endregion Websites
