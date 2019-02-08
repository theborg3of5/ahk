#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance Off
#Include <includeCommon>

; Optional input from command line
txId = %1%

; Prompt the user for the transaction ID if nothing was passed via command line
if(!txId)
	txId := InputBox("Dump Data Transaction for All Current Environments", "Enter data transaction ID", , , , , , , , MainConfig.getPrivate("RFL_TX_ID"))

; Clean out any leading/trailing odd characters (generally spaces).
txId := cleanupText(txId)

if(!txId)
	ExitApp

; Get the list of environments from a static file.
commIdAry := fileLinesToArray(findConfigFilePath("allCurrentEpicEnvironments.txt"))
; DEBUG.popup("commIdAry",commIdAry)

; Start in the dump script's directory.
SetWorkingDir, % MainConfig.getPath("TX_DIFF")

For _,commId in commIdAry {
	runString := buildTxDumpRunString(txId, commId)
	if(runString)
		Run(runString)
}

ExitApp
