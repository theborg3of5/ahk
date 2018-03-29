#Include %A_LineFile%\..

#Include _constants.ahk  ; Constants must be first so that they're available to all other scripts.
#Include _setup.ahk

#Include actionObject.ahk
#Include commandFunctions.ahk
#Include data.ahk
#Include dateTime.ahk
#Include debug.ahk
#Include debugBuilder.ahk
#Include epic.ahk
#Include file.ahk
#Include gui.ahk
#Include HTTPRequest.ahk
#Include iniObject.ahk
#Include io.ahk
#Include mainConfig.ahk
#Include runCommands.ahk
#Include selector.ahk
#Include selectorActions.ahk
#Include selectorRow.ahk
#Include string.ahk
#Include tableList.ahk
#Include tableListMod.ahk
#Include VA.ahk
#Include window.ahk
#Include XInput.ahk

; MainConfig.init("local\settings.ini", "windows.tl", "paths.tl", "programs.tl", "games.tl", "private\privates.tl")
MainConfig.init("local\settings.ini", "windows.tl", "folders.tl", "programs.tl", "games.tl", "private\privates.tl", "paths.tl")
