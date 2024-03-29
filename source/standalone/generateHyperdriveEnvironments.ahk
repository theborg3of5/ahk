; Generate a Hyperdrive environments file from the environments we have configured for Hyperspace.

#Include <includeCommon>
#LTrim, Off

HyperdriveConfigFilePath := Config.private["HYPERDRIVE_CONFIG"] "_" Config.private["WORK_ID"] "Config.json"
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

pt := new ProgressToast("Generating Hyperdrive environments config file").blockingOn()

; Read in our list of environments
pt.nextStep("Reading in environments")
tl := new TableList("epicEnvironments.tls").filterOutIfColumnBlank("HSWEB_URL") ; Filter out stuff without a URL
; Debug.popup("tl",tl)

pt.nextStep("Generating environments XML")
environments := ""
For _,envData in tl.getTable() {
	if(envData["HSWEB_URL"].contains("<LATEST_LOCAL_VERSION"))
		Continue
	
	environment := EnvironmentTemplate.replaceTags(envData)
	; Debug.popup("envData",envData, "environment",environment)
	
	environments := environments.appendPiece(",`n", environment)
}
; Debug.popup("environments",environments)

content := Config.replacePrivateTags(ConfigFileTemplate)
content := content.replaceTag("ENVIRONMENTS", environments)
; Debug.popup("content",content)

pt.nextStep("Writing to file")
FileLib.replaceFileWithString(HyperdriveConfigFilePath, content)

pt.finish()
ExitApp
