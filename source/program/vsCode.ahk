#If Config.isWindowActive("VS Code")
	; GDB TODO consider which of the below to re-enable and/or keep.
	
	; !f:: Send, ^!+f ; Use !f hotkey for highlighting with the first style (ControlSend so we don't trigger other hotkeys)
	; F6:: Send, ^w   ; Close with F6 hotkey, like we do for browsers.
	
	; Snippets
	; :X:.if:: NotepadPlusPlus.sendSnippet("if")
	; :X:.for::NotepadPlusPlus.sendSnippet("for")
	:X:.default::NotepadPlusPlus.sendDefaultingCodeString(clipboard)
	
	; Current file/folder operations
	; !c::  ClipboardLib.copyFilePathWithHotkey(  "!c")
	; !#c:: ClipboardLib.copyPathRelativeToSource("!c")         ; Current file path, but drop the usual EpicSource stuff up through the DLG folder.
	; ^!#c::ClipboardLib.copyCodeLocationRelativeToSource("!c") ; Current file + selected text as a function, but drop the usual EpicSource stuff up through the DLG folder.
	; ^+o::NotepadPlusPlus.openCurrentParentFolder()
	
	; For program scripts, swap to corresponding class script and back.
	; Pause::NotepadPlusPlus.toggleProgramAndClass()
	
	; Redo the indentation for the selected documentation lines
	^Enter::new AHKDocBlock().rewrapSelection()
	
	; AHK debug strings
	:X:dbpop::  NotepadPlusPlus.sendDebugCodeString("Debug.popup",      clipboard) ; Debug popup
	:X:dbto::   NotepadPlusPlus.sendDebugCodeString("Debug.toast",      clipboard) ; Debug toast
	:X:edbpop:: NotepadPlusPlus.sendDebugCodeString("Debug.popupEarly", clipboard) ; Debug popup that appears at startup
	^e::NotepadPlusPlus.editDebugLine() ; GDB TODO can we pull this off with snippets?
	
	; Other AHK dev strings
	:X:`;`;`;::  NotepadPlusPlus.sendDocHeader()
	; :X:ahkcont:: NotepadPlusPlus.sendContinuationBlock() ; GDB TODO doesn't work here, double text
	:X:ahkto:: Send, Toast.ShowMedium(""){Left 2}
	:X:ahketo::Send, Toast.ShowError(""){Left 2}
	:X:.clipboard::NotepadPlusPlus.sendClipboardAsString() ; GDB TODO needs an update to work properly with newlines (probably either a continuation section, or I'm not removing enough newlines?)
#If
