#If Config.isWindowActive("Everything")
	; Copy current file/folder paths to clipboard
	!c::ClipboardLib.copyFilePathWithHotkey(       "!c") ; Current file
	!#c::ClipboardLib.copyFolderPathWithFileHotkey("!c") ; Current file's folder
	^!#c::ClipboardLib.copyPathRelativeToSource(   "!c") ; Current file, but drop the usual EpicSource stuff up through the DLG folder.
#If
