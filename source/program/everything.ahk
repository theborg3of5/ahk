#If Config.isWindowActive("Everything")
	; Copy current file/folder paths to clipboard
	!c::  ClipboardLib.copyFilePath(                "!c") ; Current file path
	^!#c::ClipboardLib.copyFilePathRelativeToSource("!c") ; Current file path, but drop the usual EpicSource stuff up through the DLG folder.
#If
