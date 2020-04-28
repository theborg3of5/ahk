#If Config.isWindowActive("Explorer")
	; Focus address bar
	^l::Send, !d
		
	; Open "new tab" (to This PC)
	#e::
	^t::
		Run(Explorer.ThisPCFolderUUID)
	return
	
	; Copy current folder/file paths to clipboard
	!c::ClipboardLib.copyFilePathWithHotkey(Explorer.Hotkey_CopyCurrentFile)      ; Current file
	!#c::ClipboardLib.copyFolderPathWithHotkey(Explorer.Hotkey_CopyCurrentFolder) ; Current folder
	
	; Relative shortcut creation
	^+s::Explorer.createRelativeShortcutToFile()
	
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
	
	; Show TortoiseSVN/TortoiseGit log for current selection (both have an "l" hotkey in the
	; right-click menu, and appear only when the item is in that type of repo)
	!l::
		HotkeyLib.waitForRelease()
		Send, {AppsKey}
		Send, l
	return
#If
