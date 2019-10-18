#If Config.isWindowActive("Everything")
	; Copy current file/folder paths to clipboard
	!c::ClipboardLib.copyFilePathWithHotkey("!c")    ; Current file
	!#c::ClipboardLib.copyFolderPathWithHotkey("!c") ; Current file's folder
#If
