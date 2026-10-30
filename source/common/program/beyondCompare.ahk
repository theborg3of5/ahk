class BeyondCompare {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Compare the given strings in Beyond Compare
	; PARAMETERS:
	;  leftString   (I,REQ) - String to compare on the left
	;  middleString (I,REQ) - String to compare in the middle (or on the right if rightString="")
	;  rightString  (I,OPT) - String to compare on the right (only use for a third string)
	;  extraParams  (I,OPT) - Extra CLI parameters to include in the call (before the file paths we
	;                         put the strings into).
	;---------
	compareStrings(leftString := "", middleString := "", rightString := "", extraParams := "") {
		; Put the strings in files (to open in BC, and to allow easier saving/reloading for file
		; types and such)
		pathLeft   := A_Temp "\ahkDiffLeft.txt"
		pathMiddle := A_Temp "\ahkDiffMiddle.txt"
		FileLib.replaceFileWithString(pathLeft,   leftString)
		FileLib.replaceFileWithString(pathMiddle, middleString)
		if (rightString) {
			pathRight := A_Temp "\ahkDiffRight.txt" ; Only set/passed if we have content there
			FileLib.replaceFileWithString(pathRight,  outLines["RIGHT"].join("`n"))
		}

		; Diff it!
		Config.runProgram("Beyond Compare", "/solo " extraParams " " pathLeft " " pathRight " " pathMiddle)
	}
	
	;---------
	; DESCRIPTION:    Compare the given strings in Beyond Compare, as read-only files (i.e. view-only).
	; PARAMETERS:
	;  leftString   (I,REQ) - String to compare on the left
	;  middleString (I,REQ) - String to compare in the middle (or on the right if rightString="")
	;  rightString  (I,OPT) - String to compare on the right (only use for a third string)
	;  extraParams  (I,OPT) - Extra CLI parameters to include in the call (before the file paths we
	;                         put the strings into).
	;---------
	compareStringsReadOnly(leftString := "", middleString := "", rightString := "", extraParams := "") {
		this.compareStrings(leftString, middleString, rightString, extraParams " /readonly")
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
