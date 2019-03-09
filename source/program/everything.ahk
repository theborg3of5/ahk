#If MainConfig.isWindowActive("Everything")
	; Copy current file path to clipboard
	!c::copyFilePathWithHotkey("!c")
	; Copy current folder path to clipboard
	!#c::copyFolderPathWithHotkey("!#c")
#If
