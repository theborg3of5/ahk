#IfWinActive, ahk_exe explorer.exe
	; Focus address bar
	^l::
		Send, !d
	return
	
	; Open "new tab"
	^t::
		Run, % FOLDER_UUID_THISPC
	return
	
	; Copy current file path to clipboard
	!c::
		explorerCopyCurrentFilePath() {
			clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
			Send, !c ; QTTabBar's hotkey for copying current file path
			ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain the new path.
			
			path := clipboard
			if(!path) {
				Toast.showShort("Failed to get file path")
				return
			}
			
			path := cleanupPath(path)
			path := mapPath(path)
			
			setClipboardAndToast(path, "full file path")
		}
	; Copy current folder path to clipboard
	!#c::
		explorerCopyCurrentFolderPath() {
			clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
			Send, ^!c ; QTTabBar's hotkey for copying current folder path
			ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain the new path.
			
			path := clipboard
			if(!path) {
				Toast.showShort("Failed to get folder path")
				return
			}
			
			path .= "\" ; Add the trailing backslash since it's a folder
			path := cleanupPath(path)
			path := mapPath(path)
			
			setClipboardAndToast(path, "full folder path")
		}
	
	; Hide/show hidden files. From http://www.autohotkey.com/forum/post-342375.html#342375
	#h::
		explorerToggleHiddenFiles() {
			ValorHidden := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "Hidden")
			
			if(ValorHidden = 2) {
				Toast.showMedium("Showing hidden files...")
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
			} else {
				Toast.showMedium("Hiding hidden files...")
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
			}
			
			Send, {F5}
		}
#IfWinActive

$#e::
	if(WinActive("ahk_exe explorer.exe"))
		Run(FOLDER_UUID_THISPC) ; Open the "This PC" special folder
	else if(!WinExist("ahk_exe explorer.exe"))
		Send, #e ; Open a new session if nothing exists
	else
		WinActivate ; Show the existing window
return
