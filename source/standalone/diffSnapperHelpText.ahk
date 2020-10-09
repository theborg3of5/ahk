; GDB TODO

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

global pathLeft  := A_Temp "\ahkDiffLeft.txt"
global pathRight := A_Temp "\ahkDiffRight.txt"

; Show initial instructions
global instructionsToast := new Toast("Ready to diff help text`n`nSelect help text and press Ctrl+Shift+D to diff").show()

return

^+d::
	instructionsToast.close()
	
	; Get input
	inputText := SelectLib.getText()
	if(inputText = "") {
		new ErrorToast("No help text selected, exiting...").blockingOn().showShort()
		ExitApp
	}
	
	; Process into 2 separate blocks of text
	inputText := inputText.afterString("`n").withoutWhitespace() ; Drop first line (should be a line 0)
	
	leftLines  := []
	rightLines := []
	onLeft     := true
	For _,line in inputText.split("`n", "`r ") {
		if(isZeroLine(line)) {
			onLeft := false
			Continue
		}
		
		; Remove all line numbers
		line := line.afterString(" ")
		
		if(onLeft)
			leftLines.push(line)
		else
			rightLines.push(line)
	}
	
	FileLib.replaceFileWithString(pathLeft,  leftLines.join("`n"))
	FileLib.replaceFileWithString(pathRight, rightLines.join("`n"))
	
	Config.runProgram("KDiff", pathLeft " " pathRight)
return

isZeroLine(line) {
	words := line.split(" ")
	
	; First word should be DAT
	if(!words[1].isNum() || words[1].length() != 5)
		return false
	
	; Second word should be 0
	return (words[2] = "0")
}
