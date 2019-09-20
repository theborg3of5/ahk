#If Config.isWindowActive("Everything")
	; Copy current file/folder paths to clipboard
	!c::copyFilePathWithHotkey("!c") ; Current file
	!#c::copyFolderPathWithHotkey("!#c") ; Current file's folder
#If
