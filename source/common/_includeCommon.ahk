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

ahkRootPath := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
configFolder := ahkRootPath "\config"
MainConfig.init(configFolder "\local\settings.ini", configFolder "\windows.tl", configFolder "\folders.tl", configFolder "\programs.tl", configFolder "\games.tl")
