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
configPath := FileLib.findConfigFilePath("allCurrentEpicEnvironments.txt")
commIdAry := FileLib.fileLinesToArray(configPath)
; Debug.popup("commIdAry",commIdAry)

; Start in the dump script's directory.
SetWorkingDir, % Config.path["TX_DIFF"]

For _,commId in commIdAry {
	runString := buildTxDumpRunString(txId, commId)
	if(runString)
		Run(runString)
}

ExitApp

buildTxDumpRunString(txId, environmentCommId := "", environmentName := "") {
	if(!txId)
		return ""
	
	; Build the full output filepath.
	if(!environmentName)
		if(environmentCommId)
			environmentName := environmentCommId
		else
			environmentName := "OTHER"
	outputPath := Config.path["TX_DIFF_OUTPUT"] "\" txId "-" environmentName ".txt"
	
	; Build the string to run
	runString := Config.private["TX_DIFF_DUMP_BASE"]
	runString := runString.replaceTag("TX_ID",       txId)
	runString := runString.replaceTag("OUTPUT_PATH", outputPath)
	
	; Add on the environment if it's given - if not, leave off the flag (which will automatically cause the script to show an environment selector instead).
	if(environmentCommId)
		runString .= " --env " environmentCommId
	
	; Debug.popup("buildTxDumpRunString","Finish", "txId",txId, "outputFolder",outputFolder, "environmentCommId",environmentCommId, "runString",runString)
	return runString
}
