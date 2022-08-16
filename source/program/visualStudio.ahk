; Visual Studio hotkeys.
#If Config.isWindowActive("Visual Studio")
	^+t::Send, !fj1 ; Open last-closed project

	; Copy current file/folder paths to clipboard
	!c::  ClipboardLib.copyFilePathWithHotkey(  VisualStudio.Hotkey_CopyCurrentFile) ; Current file
	!#c:: VisualStudio.copyCodeLocationWithPath()                                    ; Current full code lcoation (file::function())
	^!#c::ClipboardLib.copyPathRelativeToSource(VisualStudio.Hotkey_CopyCurrentFile) ; Current file, but drop the usual EpicSource stuff up through the DLG folder.
	^+o:: VisualStudio.openParentFolder()
	
	; Subword navigation, because I can't use the windows key in hotkeys otherwise
	^#Left::  Send, ^!{Numpad1} ; Previous subword
	^#Right:: Send, ^!{Numpad2} ; Next subword
	^#+Left:: Send, ^!{Numpad3} ; Extend selection previous
	^#+Right::Send, ^!{Numpad4} ; Extend selection next
	
	:X:dbpop::VisualStudio.sendDebugCodeStringTS(clipboard) ; Debug popup
#If
