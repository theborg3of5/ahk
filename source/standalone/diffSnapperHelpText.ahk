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
	inputText := inputText.afterString("`n").clean() ; Drop first line (should be a line 0) and trailing newline
	prevLineNum := 0
	
	; Split into 2 blocks to diff
	leftLines  := []
	rightLines := []
	onLeft     := true
	For _,line in inputText.split("`n", "`r ") {
		if(isZeroLine(line)) {
			onLeft := false
			prevLineNum := 0
			Continue
		}
		
		; Decide which side we're putting this line into.
		if(onLeft)
			outLines := leftLines
		else
			outLines := rightLines
		
		; Track the line number and add empty lines if we jump
		lineNum := line.beforeString(" ")
		expectedNum := prevLineNum + 1
		if(lineNum > expectedNum) {
			Loop, % lineNum - expectedNum
				outLines.push("")
		}
		prevLineNum := lineNum
		
		; Remove line number
		line := line.removeFromStart(lineNum " ")
		
		outLines.push(line)
	}
	
	; Put the blocks in files and diff it
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
