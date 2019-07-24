#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

s := new Selector("epicEnvironments.tls")
data := s.selectGui("", "Toggle HSWeb local server URL for environment")
if(!data)
	ExitApp

environmentName := data["NAME"]
commId          := data["COMM_ID"]

regKeyBase := MainConfig.private["HSWEB_LOCAL_SERVER_REG_KEY"]
regValue   := MainConfig.private["HSWEB_LOCAL_SERVER_REG_VALUE"]
debugURL   := MainConfig.private["HSWEB_LOCAL_SERVER_URL"]

regKey := replaceTag(regKeyBase, "COMM_ID", commId)
currentURL := RegRead(regKey, regValue)
; DEBUG.popup("environmentName",environmentName, "commId",commId, "regKeyBase",regKeyBase, "regValue",regValue, "debugURL",debugURL, "regKey",regKey, "currentURL",currentURL)

if(currentURL != "") {
	RegWrite, REG_SZ, % regKey, % regValue, % ""
	Toast.showMedium("Cleared HSWeb local server URL for environment: " environmentName)
} else {
	RegWrite, REG_SZ, % regKey, % regValue, % debugURL
	Toast.showMedium("Set HSWeb local server URL for environment: " environmentName)
}

Sleep, 2000 ; For toasts to finish
ExitApp