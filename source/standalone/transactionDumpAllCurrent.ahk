#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.

#Include <includeCommon>

; Optional input from command line
txId = %1%

; Prompt the user for the transaction ID if nothing was passed via command line
if(!txId)
	txId := InputBox("Dump Data Transaction for All Current Environments", "Enter data transaction ID", , , , , , , , Config.private["RFL_TX_ID"])

; Clean out any leading/trailing odd characters (generally spaces).
txId := txId.clean()

if(!txId)
	ExitApp

; Get the list of environments from a static file.
configPath := FileUtils.findConfigFilePath("allCurrentEpicEnvironments.txt")
commIdAry := FileUtils.fileLinesToArray(configPath)
; DEBUG.popup("commIdAry",commIdAry)

; Start in the dump script's directory.
SetWorkingDir, % Config.path["TX_DIFF"]

For _,commId in commIdAry {
	runString := buildTxDumpRunString(txId, commId)
	if(runString)
		Run(runString)
}

ExitApp
