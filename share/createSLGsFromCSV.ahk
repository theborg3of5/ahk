; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; true to use label indices on array passed to createSLG(), otherwise numeric indices will be used.
	useLabelIndices := true
}


; --------------------------------------------------
; - Setup, Includes, Constants ---------------------
; --------------------------------------------------
{
	#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
	#SingleInstance Force        ; Running this script while it's already running just replaces the existing instance.
	SendMode Input               ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	
	; Mappings from number to label (and back) for later ease-of-use if desired.
	global slgColumnLabels := []                                        ; Excel column:
	slgColumnLabels.insertAt(1,  "NEEDS_INVESTIGATION")                 ; A
	slgColumnLabels.insertAt(2,  "REQUIREMENT_FEATURE")                 ; B
	slgColumnLabels.insertAt(3,  "EPIC_PRJ")                            ; C
	slgColumnLabels.insertAt(4,  "PRIMARY_APP")                         ; D
	slgColumnLabels.insertAt(5,  "HEALTH_SOCIAL")                       ; E
	slgColumnLabels.insertAt(6,  "IS_OWNER")                            ; F
	slgColumnLabels.insertAt(7,  "APP_IS_OWNER_UPDATED")                ; G
	slgColumnLabels.insertAt(8,  "RD_REVIEWER")                         ; H
	slgColumnLabels.insertAt(9,  "ID")                                  ; I
	slgColumnLabels.insertAt(10, "MANDATORY")                           ; J
	slgColumnLabels.insertAt(11, "FUNCTIONALITY_GROUP")                 ; K
	slgColumnLabels.insertAt(12, "FUNCTIONALITY")                       ; L
	slgColumnLabels.insertAt(13, "DESCRIPTION")                         ; M
	slgColumnLabels.insertAt(14, "FINNISH_DESCRIPTION")                 ; N
	slgColumnLabels.insertAt(15, "REVIEW_LEVEL")                        ; O
	slgColumnLabels.insertAt(16, "SIGN_OFF_DATE")                       ; P
	slgColumnLabels.insertAt(17, "DIRECTION_ADOPTION_SESSION_WORKFLOW") ; Q
	slgColumnLabels.insertAt(18, "HEALTH_USE_CASE_DEMO_STEPS")          ; R
	slgColumnLabels.insertAt(19, "SOCIAL_USE_CASE_DEMO_STEPS")          ; S
	slgColumnLabels.insertAt(20, "TEST_SCRIPT")                         ; T
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{
	; Get the file to read from the user.
	FileSelectFile, fileName, 1, , File to read SLG info from, *.csv
	
	; Loop over each line in the file.
	Loop, READ, %filename%
	{
		; Ignore the first line of column headers.
		if(A_Index = 1)
			continue
		
		; Loop over each (comma-delimited) field in the line and put it in an array.
		slgFields := []
		Loop, PARSE, A_LoopReadLine, CSV
		{
			slgFields[ A_Index ] := A_LoopField
		}
		
		; Turn numeric indices into easier-to-read labels (specified in global slgColumnLabels at top)
		if(useLabelIndices)
			slgFields := mapIndexNumsToLabels(slgFields)
		
		; Create the SLG with our gathered info from this line.
		createSLG(slgFields)
	}
	
	; Finished, exit.
	ExitApp
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	createSLG(slgFields = "") {
		
		; ADD SLG CREATION LOGIC HERE (and remove below example usage)
		
		; Note: set useLabelIndices to false to get number-indexed slgFields instead of labels defined at top.
		
		; Example usage:
		MsgBox, 4, , % "Primary app: " slgFields["PRIMARY_APP"] "`nReview level: " slgFields["REVIEW_LEVEL"] "`nDescription: " slgFields["DESCRIPTION"] "`n`nContinue?"
		; Example with useLabelIndices = false:
		; MsgBox, 4, , % "Primary app: " slgFields[4] "`nReview level: " slgFields[15] "`nDescription: " slgFields[13] "`n`nContinue?"
		IfMsgBox, No
			ExitApp
	}
	
	; Switches from numeric indices to the labels defined in slgColumnLabels at the top, for better code readability.
	mapIndexNumsToLabels(slgArrayIn) {
		global slgColumnLabels
		slgArrayOut := []
		
		for i,v in slgArrayIn
			slgArrayOut[ slgColumnLabels[i] ] := v
		
		return slgArrayOut
	}
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp



