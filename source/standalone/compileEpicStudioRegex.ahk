#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

/* .bits file format:
		One line per regex bit
			Each should be valid by itself
		Optional headers should be left-justified (no indentation) and start with a hash (#)
			Regex bit lines under a header should not be indented
		Optional explanation lines can come after each regex bit line
			They must be indented at least once
*/

; Start in the relevant folder.
SetWorkingDir, % Config.path["EPICSTUDIO_GLOBAL_HIGHLIGHTS"]

; Loop over all .bits files and compile them into .regex files.
Loop, Files, % "*.bits"
{
	regexString := ""
	For _,line in FileLib.fileLinesToArray(A_LoopFileName) {
		if(line = "") ; Empty line
			Continue
		if(line.startsWith("#")) ; Header
			Continue
		if(line.startsWith("`t")) ; Explanation line
			Continue
		
		line := "(" line ")" ; Wrap each bit in parens
		regexString := regexString.appendPiece(line,"|")
	}
	
	; Generate the name of the compiled regex file from the base name of the original
	SplitPath(A_LoopFileName, "", "", "", baseName)
	
	; Overwrite the file if it exists
	FileLib.replaceFileWithString(baseName ".regex", regexString)
}

new Toast("Compiled all .bits files into .regex files").blockingOn().showMedium()

ExitApp
