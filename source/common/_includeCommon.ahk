#Include %A_LineFile%\..

#Include _constants.ahk  ; Constants must be first so that they're available to all other scripts.
#Include _setup.ahk

#Include actionObject.ahk
#Include commandFunctions.ahk
#Include data.ahk
#Include dateTime.ahk
#Include debug.ahk
#Include epic.ahk
#Include file.ahk
#Include flexTable.ahk
#Include gui.ahk
#Include HTTPRequest.ahk
#Include iniObject.ahk
#Include io.ahk
#Include mainConfig.ahk
#Include runCommands.ahk
#Include selector.ahk
#Include string.ahk
#Include tableList.ahk
#Include toast.ahk
#Include VA.ahk
#Include window.ahk
#Include XInput.ahk

MainConfig.init("local\settings.ini", "windowsLegacy.tl", "paths.tl", "programs.tl", "games.tl", "private\privates.tl")
