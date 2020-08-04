; Visual Studio hotkeys.
#If Config.isWindowActive("Visual Studio")
	Pause::+Pause ; For CodeMaid switch between related files
	
	^+t::Send, !fj1 ; Open last-closed project

	; Copy current file/folder paths to clipboard
	!c::  ClipboardLib.copyFilePathWithHotkey(      "^+c") ; Current file
	!#c:: ClipboardLib.copyFolderPathWithFileHotkey("^+c") ; Current file's folder
	^!#c::ClipboardLib.copyPathRelativeToSource(    "^+c") ; Current file, but drop the usual EpicSource stuff up through the DLG folder.
	
	; Subword navigation, because I can't use the windows key in hotkeys otherwise
	^#Left::  Send, ^!{Numpad1} ; Previous subword
	^#Right:: Send, ^!{Numpad2} ; Next subword
	^#+Left:: Send, ^!{Numpad3} ; Extend selection previous
	^#+Right::Send, ^!{Numpad4} ; Extend selection next
#If
