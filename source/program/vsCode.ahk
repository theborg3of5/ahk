#If Config.isWindowActive("VSCode")
	; Current file/folder operations
	!c::  ClipboardLib.copyFilePathWithHotkey(    "^+c") ; Custom hotkey for copyFilePath command
	^!f:: ClipboardLib.openActiveFileParentFolder("^+c") ; Yes, there's a built-in command for this, but it doesn't work consistently and take forever to happen.
	
	; For program scripts, swap to corresponding class script and back.
	Pause::VSCode.toggleProgramAndClass()
	
	; Redo the indentation for the selected documentation lines
	^+Enter::new AHKDocBlock().rewrapSelection()
	
	; AHK debug strings
	:X:dbpop::	VSCode.sendAHKDebugCodeString("Debug.popup",      clipboard) ; Debug popup
	:X:dbto::	VSCode.sendAHKDebugCodeString("Debug.toast",      clipboard) ; Debug toast
	:X:edbpop::	VSCode.sendAHKDebugCodeString("Debug.popupEarly", clipboard) ; Debug popup that appears at startup
	^e::		VSCode.editDebugLine()

	; Other AHK dev strings
	:X:`;`;`;::VSCode.sendDocHeader()
#If
