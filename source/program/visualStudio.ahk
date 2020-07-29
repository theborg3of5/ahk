; Visual Studio hotkeys.
#If Config.isWindowActive("Visual Studio")
	Pause::+Pause ; For CodeMaid switch between related files
	
	^+t::Send, !fj1 ; Open last-closed project

	; Copy current file/folder paths to clipboard
	!c::  ClipboardLib.copyFilePathWithHotkey(      "^+c") ; Current file
	!#c:: ClipboardLib.copyFolderPathWithFileHotkey("^+c") ; Current file's folder
	^!#c::ClipboardLib.copyPathRelativeToSource(    "^+c") ; Current file, but drop the usual EpicSource stuff up through the DLG folder.
#If
