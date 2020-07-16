#If Config.isWindowActive("Notepad++")
	!x::return      ; Block close-document hotkey that can't be changed/removed.
	^+t::Send, !f1  ; Re-open last closed document.
	!f:: Send, ^!+f ; Use !f hotkey for highlighting with the first style (ControlSend so we don't trigger other hotkeys)
	F6:: Send, ^w   ; Close with F6 hotkey, like we do for browsers.
	
	; Snippets
	:X:.if:: NotepadPlusPlus.sendSnippet("if")
	:X:.for::NotepadPlusPlus.sendSnippet("for")
	
	; Current file/folder operations
	!c::ClipboardLib.copyFilePathWithHotkey("!c")
	!#c::ClipboardLib.copyFolderPathWithFileHotkey("!c")
	^+o::NotepadPlusPlus.openCurrentParentFolder()
	
	; Redo the indentation for the selected documentation lines
	^Enter::new AHKDocBlock().rewrapSelection()
	
	; AHK debug strings
	:X:dbpop::  NotepadPlusPlus.sendDebugCodeString("Debug.popup")      ; Debug popup
	:X:dbto::   NotepadPlusPlus.sendDebugCodeString("Debug.toast")      ; Debug toast
	:X:edbpop:: NotepadPlusPlus.sendDebugCodeString("Debug.popupEarly") ; Debug popup that appears at startup
	:X:dbparam::NotepadPlusPlus.insertDebugParams()                     ; Debug parameters
	:X:dbm::    SendRaw, % "MsgBox, % "
	
	; Other AHK dev strings
	:X:`;`;`;::  NotepadPlusPlus.sendDocHeader()
	:X:ahkcont:: NotepadPlusPlus.sendContinuationBlock()
	:X:ahkclass::NotepadPlusPlus.sendClassTemplate()
	:X:ahkto:: Send, new Toast("").showMedium(){Left 15}
	:X:ahketo::Send, new ErrorToast("").showMedium(){Left 15}
#If
