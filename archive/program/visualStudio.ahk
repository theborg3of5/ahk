; Visual Studio hotkeys.
#If Config.isWindowActive("Visual Studio")
	; Copy current file/folder paths to clipboard
	!c::  ClipboardLib.copyCodeLocationPath(            VisualStudio.Hotkey_CopyCurrentFile) ; Code location (full path)
	!#c:: ClipboardLib.copyCodeLocationFile(            VisualStudio.Hotkey_CopyCurrentFile) ; Code location (file name only)
	^!#c::ClipboardLib.copyCodeLocationRelativeToSource(VisualStudio.Hotkey_CopyCurrentFile) ; Code location (path from source)
	^!f:: ClipboardLib.openActiveFileParentFolder(      VisualStudio.Hotkey_CopyCurrentFile)
	
	; Subword navigation, because I can't use the windows key in hotkeys otherwise
	^#Left::  Send, ^!{Numpad1} ; Previous subword
	^#Right:: Send, ^!{Numpad2} ; Next subword
	^#+Left:: Send, ^!{Numpad3} ; Extend selection previous
	^#+Right::Send, ^!{Numpad4} ; Extend selection next
	
	:X:dbpop::VisualStudio.sendDebugCodeStringTS(clipboard) ; Debug popup
#If
