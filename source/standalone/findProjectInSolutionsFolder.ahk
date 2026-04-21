; Searches the source solutions folder for solutions that contain a particular project.

#Include <includeCommon>

; Get name of project to search for
ib := InputBox("Enter project to search for:", "Search solutions for project", "w400 h125")
if(ib.Result = "Cancel" || ib.Value = "")
	ExitApp
projectName := ib.Value
projectName := projectName.appendIfMissing(".csproj")

tt := TextTable("Found solutions containing project")
tt.addRow("Project name:", projectName)

solutions := findSolutions(projectName)
if(solutions = "")
	solutions := "<none>"
tt.addRow("Solutions:", solutions)

TextPopup(tt).show()
ExitApp


findSolutions(projectName) {
	tt := TextTable().setBorderType(TextTable.BorderType_Line)

	searchRoot := Config.path["EPIC_SOURCE_S1"] "\HSWeb\Solutions\Apps\"
	Loop Files, searchRoot "*.sln", "RF" ; [R]ecursive, [F]iles (not [D]irectories)
	{
		content := FileRead(A_LoopFilePath)
		if(content.contains(projectName))
			tt.addRow(A_LoopFilePath.removeFromStart(searchRoot))
	}
	
	return tt.getText()
}
