#If Config.isWindowActive("Explorer")
	; Focus address bar
	^l::Send, !d
		
	; Open "new tab" (to This PC)
	#e:: ; While explorer is already active - otherwise, this activates it.
	^t::
		Run(Explorer.ThisPCFolderUUID)
	return
	
	; Copy current folder/file paths to clipboard
	!c::  Explorer.copySelectedPath()                 ; Current file (or folder if nothing selected)
	^!#c::Explorer.copySelectedPathRelativeToSource() ; Current file (or folder if nothing selected), but drop the usual EpicSource stuff up through the DLG folder.
	
	; Show TortoiseSVN/TortoiseGit log for current selection (both have an "l" hotkey in the
	; right-click menu, and appear only when the item is in that type of repo)
	!l::
		HotkeyLib.waitForRelease()
		Send, {AppsKey}
		Send, l
	return
	!b:: ; Blame for the same
		HotkeyLib.waitForRelease()
		Send, {AppsKey}
		Send, b
		
		; Accept through starting revision window too, never want to start anywhere except first revision.
		WinWaitActive, % Config.windowInfo["TortoiseSVN Blame Popup"].titleString
		Send, {Enter}
	return
	
	; Edit in Notepad++
	^+e::
		HotkeyLib.waitForRelease()
		Send, {AppsKey}
		Send, n{Enter}
	return
	
	; Relative shortcut creation
	^+s::Explorer.createRelativeShortcutToFile()
	
	; Open EMC2 objects based on the active folder name.
	!w::Explorer.getEMC2ObjectFromSelectedFolder().openWeb()
	!e::Explorer.getEMC2ObjectFromSelectedFolder().openEdit()
	
	
#If Config.isWindowActive("Explorer") || WinActive("ahk_class Progman ahk_exe explorer.exe")	; Explorer window or Desktop
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
#If
