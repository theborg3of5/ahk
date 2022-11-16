#If Config.isWindowActive("VSCode")
	; GDB TODO consider which of the below to re-enable and/or keep.
	
	; !f:: Send, ^!+f ; Use !f hotkey for highlighting with the first style (ControlSend so we don't trigger other hotkeys)
	; F6:: Send, ^w   ; Close with F6 hotkey, like we do for browsers.
	
	; Snippets
	; :X:.default::VSCode.sendDefaultingCodeString(clipboard)
	
	; Current file/folder operations
	; !c::  ClipboardLib.copyFilePathWithHotkey(  "!c")
	; !#c:: ClipboardLib.copyPathRelativeToSource("!c")         ; Current file path, but drop the usual EpicSource stuff up through the DLG folder.
	; ^!#c::ClipboardLib.copyCodeLocationRelativeToSource("!c") ; Current file + selected text as a function, but drop the usual EpicSource stuff up through the DLG folder.
	; ^+o::VSCode.openCurrentParentFolder()
	
	; For program scripts, swap to corresponding class script and back.
	Pause::VSCode.toggleProgramAndClass()
	
	; Redo the indentation for the selected documentation lines
	; ^Enter::new AHKDocBlock().rewrapSelection() ; GDB TODO this isn't selecting the current line, seems like? Shouldn't it?
	
	; AHK debug strings
	:X:dbpop::	VSCode.sendAHKDebugCodeString("Debug.popup",      clipboard) ; Debug popup
	:X:dbto::	VSCode.sendAHKDebugCodeString("Debug.toast",      clipboard) ; Debug toast
	:X:edbpop::	VSCode.sendAHKDebugCodeString("Debug.popupEarly", clipboard) ; Debug popup that appears at startup
	^e::		VSCode.editDebugLine()

	; Other AHK dev strings
	; :X:`;`;`;::VSCode.sendDocHeader()
#If
