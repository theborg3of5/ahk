#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.

#Include <includeCommon>

; Optional input from command line
txId = %1%

; Default to the referrals data tx if nothing given on command line.
if(!txId)
	txId := Config.private["RFL_TX_ID"]

; Create a Selector so the user can pick the environment and give us the TX's ID.
s := new Selector("epicEnvironments.tls").setTitle("Dump Data Transaction from Environment to File")
s.addOverrideFields(["TX_ID"]).setDefaultOverrides({"TX_ID":txId}) ; Add a field for the TX's ID and default it in if it was given already.
data := s.selectGui()
if(!data)
	ExitApp

envName := data["NAME"]
envId   := data["COMM_ID"]
txId    := data["TX_ID"].clean() ; Clean out any leading/trailing odd characters (generally spaces).

if(envId = "")
	ExitApp
if(envId = "LAUNCH") ; Special case - just launching the script without picking an environment
	envId := ""

runString := buildTxDumpRunString(txId, envId, envName)
if(runString)
	RunLib.runCommand(runString, Config.path["TX_DIFF"], true)

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
