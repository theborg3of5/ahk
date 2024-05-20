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
	
#If Config.isWindowActive("Explorer") || WinActive("ahk_class Progman ahk_exe explorer.exe") ; Explorer window or Desktop
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
#If

#If Explorer.mouseIsOverTaskbar()
	; Middle-click on taskbar buttons to close them.
	$MButton::
		closeWindowFromTaskbar() {
			; Open up basic right-click menu to try and close the window.
			Send, +{RButton}
			Sleep, 100
	
			; VSCode is special and doesn't have a shift+right click menu (unless you switch its
			; title bar to "native", which looks terrible).
			if (Config.isWindowActive("VSCode")) {
				Send, !{F4}
				return
			}
	
			Send, c ; Close
		}
#If

