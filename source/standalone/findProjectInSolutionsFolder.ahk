; Searches the source solutions folder for solutions that contain a particular project.

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

; Get name of project to search for
projectName := InputBox("Search solutions for project", "Enter project to search for:", "", "", 125)
if(projectName = "")
	ExitApp
projectName := projectName.appendIfMissing(".csproj")

tt := new TextTable("Found solutions containing project")
tt.addRow("Project name:", projectName)

solutions := findSolutions(projectName)
if(solutions = "")
	solutions := "<none>"
tt.addRow("Solutions:", solutions)

new TextPopup(tt).show()
ExitApp


findSolutions(projectName) {
	tt := new TextTable().setBorderType(TextTable.BorderType_Line)
	
	searchRoot := Config.private["EPIC_SOURCE_S1"] "\" Config.private["EPIC_HSWEB_SOLUTIONS"] "\"
	Loop, Files, % searchRoot "*.sln", RF ; [R]ecursive, [F]iles (not [D]irectories)
	{
		content := FileRead(A_LoopFilePath)
		if(content.contains(projectName))
			tt.addRow(A_LoopFilePath.removeFromStart(searchRoot))
	}
	
	return tt.getText()
}
