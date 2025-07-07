; AHK-specific handling
#If Config.isWindowActive("VSCode AHK")
	; For program scripts, swap to corresponding class script and back.
	Pause::VSCode.toggleProgramAndClass()
	
	; Redo the indentation for the selected documentation lines
	^+Enter:: new HeaderDocBlock().rewrapSelection()
	^+!Enter::new HeaderDocBlock().unwrapSelection()
	
	; AHK debug strings
	:X:dbpop::	VSCode.sendAHKDebugCodeString("Debug.popup",      clipboard) ; Debug popup
	:X:dbto::	VSCode.sendAHKDebugCodeString("Debug.toast",      clipboard) ; Debug toast
	:X:edbpop::	VSCode.sendAHKDebugCodeString("Debug.popupEarly", clipboard) ; Debug popup that appears at startup
	:X:dbcon::	VSCode.sendAHKDebugCodeString("Debug.console",    clipboard) ; Debug console
	^e::		VSCode.editDebugLine()

	; Other AHK dev strings
	:X:`;`;`;::VSCode.sendDocHeader()
	
; EpicCode-specific handling
#If Config.isWindowActive("VSCode EpicCode")
	!c:: VSCode.copyCleanEpicCodeLocation()
	!#c::VSCode.copyEpicRoutineName()

	; Generate and insert snippets
	:X:.snip::MSnippets.insertSnippet()

	; Pass this one through (it's for opening the parent folder below)
	$^!f::Send, ^!f

	; Tiny snippet to insert a variable (with linking _s) in the middle of a string. This can't
	; quite be a proper snippet because I often use it directly next to other characters (no
	; spaces/newlines separating it so it can be treated as a snippet).
	::.qs::
		Send, % """__"""
		Send, {Left 2}
	return

; All profiles (unless overridden above)
#If Config.isWindowActive("VSCode")
	; Current file/folder operations
	!c::  ClipboardLib.copyCodeLocationPath(      VSCode.Hotkey_CopyCurrentFile)
	!#c:: ClipboardLib.copyCodeLocationFile(      VSCode.Hotkey_CopyCurrentFile)
	^!f:: ClipboardLib.openActiveFileParentFolder(VSCode.Hotkey_CopyCurrentFile) ; Yes, there's a built-in command for this, but it doesn't work consistently and take forever to happen.

	; Block/column selection reminder
	!#LButton::Toast.ShowShort("Column/block select in VSCode is Alt+Shift+Click.")

	; Subword navigation (ctrl+win+left/right are stolen by Windows for virtual desktops otherwise)
	^#Left::  Send, ^!{Numpad1} ; Previous subword
	^#Right:: Send, ^!{Numpad2} ; Next subword
	^#+Left:: Send, ^!{Numpad4} ; Select previous subword
	^#+Right::Send, ^!{Numpad6} ; Select next subword
#If
