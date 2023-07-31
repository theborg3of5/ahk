#If Config.isWindowActive("Notepad++")
	!x::return      ; Block close-document hotkey that can't be changed/removed.
	^+t::Send, !f1  ; Re-open last closed document.
	!f:: Send, ^!+f ; Use !f hotkey for highlighting with the first style (ControlSend so we don't trigger other hotkeys)
	F6:: Send, ^w   ; Close with F6 hotkey, like we do for browsers.
	
	; Current file/folder operations
	!c::  ClipboardLib.copyCodeLocationPath(            "!c")
	!#c:: ClipboardLib.copyCodeLocationFile(            "!c")
	^!#c::ClipboardLib.copyCodeLocationRelativeToSource("!c") ; Current file + selected text as a function, but drop the usual EpicSource stuff up through the DLG folder.
	^!f:: ClipboardLib.openActiveFileParentFolder(      "!c")
#If
