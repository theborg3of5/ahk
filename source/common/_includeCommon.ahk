; ==============================
; == Includes ==================
; ==============================
#Include %A_LineFile%\..
	; Auto-execute scripts
	#Include _constants.ahk  ; Constants must be first so that they're available to all other scripts.
	#Include _base.ahk
	
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
	#Include window.ahk
	#Include XInput.ahk

#Include %A_LineFile%\..\class
	#Include commonHotkeys.ahk
	#Include debug.ahk
	#Include duration.ahk
	#Include epicRecord.ahk
	#Include flexTable.ahk
	#Include formatList.ahk
	#Include hyperlinker.ahk
	#Include mainConfig.ahk
	#Include mousePosition.ahk
	#Include programInfo.ahk
	#Include scriptTrayInfo.ahk
	#Include selector.ahk
	#Include tableList.ahk
	#Include toast.ahk
	#Include visualWindow.ahk
	#Include windowActions.ahk
	#Include windowInfo.ahk

#Include %A_LineFile%\..\class\actionObject
	#Include actionObjectBase.ahk
	#Include actionObjectCodeSearch.ahk
	#Include actionObjectEMC2.ahk
	#Include actionObjectEpicStudio.ahk
	#Include actionObjectHelpdesk.ahk
	#Include actionObjectPath.ahk
	#Include actionObjectRedirector.ahk


; ==============================
; == Startup ===================
; ==============================
MainConfig.init("local\settings.ini", "windows.tl", "paths.tl", "programs.tl", "games.tl", "ahkPrivate\privates.tl")
WindowActions.init("windowActions.tl")
