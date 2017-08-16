#Include %A_LineFile%\..

#Include constants.ahk  ; Constants must be first so that they're available to all other scripts.

#Include actionObject.ahk
#Include data.ahk
#Include dateTime.ahk
#Include debug.ahk
#Include epic.ahk
#Include gui.ahk
#Include HTTPRequest.ahk
#Include io.ahk
#Include mainConfig.ahk
#Include runCommands.ahk
#Include selector.ahk
#Include selectorActions.ahk
#Include selectorRow.ahk
#Include string.ahk
#Include tableList.ahk
#Include tableListMod.ahk
#Include tray.ahk
#Include VA.ahk
#Include window.ahk
#Include XInput.ahk

MainConfig.init(localConfigFolder "settings.ini", configFolder "windows.tl", configFolder "programs.tl")
