#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.

#Include <includeCommon>

; Optional input from command line
txId = %1%

; Default to the referrals data tx if nothing given on command line.
if(!txId)
	txId := Config.private["RFL_TX_ID"]

; Start in the dump script's directory.
SetWorkingDir, % Config.path["TX_DIFF"]

; Create a Selector so the user can pick the environment and give us the TX's ID.
s := new Selector("epicEnvironments.tls").SetTitle("Dump Data Transaction from Environment to File")
s.AddOverrideFields(["TX_ID"]).SetDefaultOverrides({"TX_ID":txId}) ; Add a field for the TX's ID and default it in if it was given already.
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
	Run(runString)

ExitApp
