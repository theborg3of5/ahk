#If MainConfig.isWindowActive("Everything")

	; Copy current file path to clipboard
	!c::
		everythingCopyCurrentFilePath() {
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
		everythingCopyCurrentFolderPath() {
			clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
			Send, !#c ; QTTabBar's hotkey for copying current folder path
			ClipWait, 2 ; Wait for 2 seconds for the clipboard to contain the new path.
			
			path := clipboard
			if(!path) {
				Toast.showShort("Failed to get folder path")
				return
			}
			
			path .= "\" ; Add the trailing backslash since it's a folder
			path := cleanupPath(path)
			path := mapPath(path)
			
			setClipboardAndToast(path, "containing folder path")
		}
	
#If
