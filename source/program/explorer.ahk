#If Config.isWindowActive("Explorer")
	; Open "new tab" (to This PC)	
	#e::Send, ^t ; While explorer is already active - otherwise, this activates it.

	; Copy current folder/file paths to clipboard
	!c::  Explorer.copySelectedPath()                 ; Current file (or folder if nothing selected)
	^!#c::Explorer.copySelectedPathRelativeToSource() ; Current file (or folder if nothing selected), but drop the usual EpicSource stuff up through the DLG folder.
	
	; Shortcuts creation
	^+s::Explorer.selectSolutionShortcut()       ; DLG solution shortcut
	^!s::Explorer.createRelativeShortcutToFile() ; Relative shortcut
	
	; Open EMC2 objects based on the active folder name.
	!w::Explorer.getEMC2ObjectFromSelectedFolder().openWeb()
	!e::Explorer.getEMC2ObjectFromSelectedFolder().openEdit()

	; Open Windows Terminal in the current directory.
	!r::
		openWindowsTerminalInCurrFolder() {
			folderPath := Explorer.getCurrentFolder()
			if(!folderPath)
				return
			
			Config.activateProgram("Windows Terminal", "--profile ""Git Bash"" --startingDirectory " folderPath)
		}
	
#If Config.isWindowActive("Explorer") || WinActive("ahk_class Progman ahk_exe explorer.exe") ; Explorer window or Desktop
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
#If

#If Explorer.mouseIsOverTaskbar() && Config.machineIsWorkDesktop
	; Middle-click on taskbar buttons to close them.
	$MButton::
		closeWindowFromTaskbar() {
			; Open up basic right-click menu to try and close the window.
			Send, +{RButton}
			
			; Some windows don't have a shift+right click menu for some reason, so rely on the fact
			; that shift+right-click focuses the window and just close it directly.
			Sleep, 100 ; Give window a chance to get focus before we check
			if (Explorer.currentWindowHasNoBasicRightClickMenu()) {
				WindowActions.closeWindow("A")
				return
			}

			; Wait up to 1 second for right-click menu to appear and get focus
			WinWait, ahk_class #32768, , 1

			; If it didn't (we timed out), show an error toast that this is probably a new
			; window we should add to Explorer.currentWindowHasNoBasicRightClickMenu().
			if (ErrorLevel = 1) {
				Toast.ShowError("Failed to close window", "Shift-right-click menu did not appear", "Consider adding window to Explorer.currentWindowHasNoBasicRightClickMenu()")
				return
			}
	
			Send, c ; Close
		}
#If

