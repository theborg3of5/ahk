#If Config.isWindowActive("VSCode")
	; GDB TODO consider which of the below to re-enable and/or keep.
	
	; Current file/folder operations
	; !c::  ClipboardLib.copyFilePathWithHotkey(  "!c")
	; ^+o::VSCode.openCurrentParentFolder()
	
	; For program scripts, swap to corresponding class script and back.
	Pause::VSCode.toggleProgramAndClass()
	
	; Redo the indentation for the selected documentation lines
	^Enter::new AHKDocBlock().rewrapSelection()
	
	; AHK debug strings
	:X:dbpop::	VSCode.sendAHKDebugCodeString("Debug.popup",      clipboard) ; Debug popup
	:X:dbto::	VSCode.sendAHKDebugCodeString("Debug.toast",      clipboard) ; Debug toast
	:X:edbpop::	VSCode.sendAHKDebugCodeString("Debug.popupEarly", clipboard) ; Debug popup that appears at startup
	^e::		VSCode.editDebugLine()

	; Other AHK dev strings
	:X:`;`;`;::VSCode.sendDocHeader()
#If
