; Searches the source solutions folder for solutions that contain a particular project.

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
	
	searchRoot := Config.path["EPIC_SOURCE_S1"] "\HSWeb\Solutions\Apps\"
	Loop, Files, % searchRoot "*.sln", RF ; [R]ecursive, [F]iles (not [D]irectories)
	{
		content := FileRead(A_LoopFilePath)
		if(content.contains(projectName))
			tt.addRow(A_LoopFilePath.removeFromStart(searchRoot))
	}
	
	return tt.getText()
}
