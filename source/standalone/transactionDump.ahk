#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode, Input  ; Recommended for new scripts due to its superior speed and reliability.
#SingleInstance Off
#Include <includeCommon>

; Optional input from command line
txId = %1%

; Start in the dump script's directory.
SetWorkingDir, % MainConfig.getPath("TX_DIFF")

; Create a Selector so the user can pick the environment and give us the TX's ID.	
s := new Selector("epicEnvironments.tls")
s.addExtraOverrideFields(["TX_ID"])

defaultOverrideData := []
defaultOverrideData["TX_ID"] := txId ; Default in the tx name from the command line

data := s.selectGui("", "Dump Data Transaction from Environment to File", defaultOverrideData)
if(!data)
	ExitApp

txId   := cleanupText(data["TX_ID"]) ; Clean out any leading/trailing odd characters (generally spaces).
commId := data["COMM_ID"]

if(commId = "LAUNCH") ; Special case - just launching the script without picking an environment
	commId := ""

runString := buildTxDumpRunString(txId, commId)
if(runString)
	Run(runString)

ExitApp
