#If Config.isWindowActive("Explorer")
	; Focus address bar
	^l::Send, !d
		
	; Open "new tab" (to This PC)
	#e:: ; While explorer is already active - otherwise, this activates it.
	^t::
		Run(Explorer.ThisPCFolderUUID)
	return
	
	; Copy current folder/file paths to clipboard
	!c::  ClipboardLib.copyFilePathWithHotkey(  Explorer.Hotkey_CopyCurrentFile)   ; Current file
	!#c:: ClipboardLib.copyFolderPathWithHotkey(Explorer.Hotkey_CopyCurrentFolder) ; Current folder
	^!#c::ClipboardLib.copyPathRelativeToSource(Explorer.Hotkey_CopyCurrentFile)   ; Current file, but drop the usual EpicSource stuff up through the DLG folder.
	
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
	
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
	return
	
	; Relative shortcut creation
	^+s::Explorer.createRelativeShortcutToFile()
	
	; Open EMC2 objects based on the active folder name.
	!w::Explorer.getActiveFolderEMC2Object().openWeb()
	!e::Explorer.getActiveFolderEMC2Object().openEdit()
#If
