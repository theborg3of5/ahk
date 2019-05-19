#Include %A_LineFile%\..
	#Include _constants.ahk  ; Constants must be first so that they're available to all other scripts.
	#Include _setup.ahk

	#Include clipboard.ahk
	#Include commandFunctions.ahk
	#Include data.ahk
	#Include dateTime.ahk
	#Include epic.ahk
	#Include file.ahk
	#Include gui.ahk
	#Include HTTPRequest.ahk
	#Include io.ahk
	#Include runCommands.ahk
	#Include string.ahk
	#Include VA.ahk
	#Include window.ahk
	#Include XInput.ahk

#Include %A_LineFile%\..\class
	#Include actionObject.ahk
	#Include debug.ahk
	#Include duration.ahk
	#Include flexTable.ahk
	#Include hyperlinker.ahk
	#Include iniObject.ahk
	#Include listConverter.ahk
	#Include mainConfig.ahk
	#Include mousePosition.ahk
	#Include programInfo.ahk
	#Include selector.ahk
	#Include tableList.ahk
	#Include toast.ahk
	#Include visualWindow.ahk
	#Include windowActions.ahk
	#Include windowInfo.ahk

MainConfig.init("local\settings.ini", "windows.tl", "paths.tl", "programs.tl", "games.tl", "ahkPrivate\privates.tl")
WindowActions.init("windowActions.tl")
