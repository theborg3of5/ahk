; Generate a Hyperdrive environments file from the environments we have configured for Hyperspace.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

HyperdriveConfigFilePath := "C:\Program Files (x86)\Epic\Hyperdrive\Config\_0Config.json"
ConfigFileTemplate := "
	(
{
	""WorkstationID"" : ""<WORK_COMPUTER_NAME>"",
	""CustomerName"" : ""- GDB "",
	""Environments"" : {
	
<ENVIRONMENTS>
		
	}
}
	)"
EnvironmentTemplate := "
	(
		""<COMM_ID>"" : {
			""DisplayName"": ""<NAME>"",
			""HSWebServerURL"": ""<HSWEB_URL>""
		}
	)"

; Read in our list of environments
tl := new TableList("epicEnvironments.tls").filterOutIfColumnBlank("HSWEB_URL") ; Filter out stuff without a URL
; Debug.popup("tl",tl)

environments := ""
For _,envData in tl.getTable() {
	environment := EnvironmentTemplate.replaceTags(envData)
	; Debug.popup("envData",envData, "environment",environment)
	
	environments := environments.appendPiece(environment, ",`n")
}
; Debug.popup("environments",environments)

content := Config.replacePrivateTags(ConfigFileTemplate)
content := content.replaceTag("ENVIRONMENTS", environments)
; Debug.popup("content",content)

FileLib.replaceFileWithString(HyperdriveConfigFilePath, content)

ExitApp
