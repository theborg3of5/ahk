; Launch the bunch of programs I typically need open, for use after I restart the computer.

#Include <includeCommon>

Config.runProgram("Chrome")
Config.runProgram("Explorer", Explorer.ThisPCFolderUUID)
Config.runProgram("OneNote")
if(Config.contextIsWork) {
	Config.runProgram("Outlook")
	Config.runProgram("EMC2", "EMC2Update env=TRACKAPPTCP")
	Config.runProgram("EpicStudio")
	Config.runProgram("Thunder")
}

ExitApp
