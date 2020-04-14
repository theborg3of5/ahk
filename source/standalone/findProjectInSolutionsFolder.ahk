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

matchedSolutions := []
searchRoot := Config.private["EPIC_SOURCE_S1"] "\" Config.private["EPIC_HSWEB_SOLUTIONS"] "\"
Loop, Files, % searchRoot "*.sln", RF ; [R]ecursive, [F]iles (not [D]irectories)
{
	content := FileRead(A_LoopFilePath)
	if(content.contains(projectName))
		matchedSolutions.push(A_LoopFilePath.removeFromStart(searchRoot))
}

Debug.popup("Project name",projectName, "Found in solutions",matchedSolutions)
ExitApp
