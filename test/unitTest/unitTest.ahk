{ ; Includes, other here-to-stay auto-execute things.
	#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
	SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	; #NoTrayIcon
	#SingleInstance force
	
	#Include <autoInclude>
	
	; State flags.
	global suspended := 0
	
	; Icon setup.
	states                 := []
	states["suspended", 1] := "unitTest.ico"
	states["suspended", 0] := "unitTest.ico"
	setupTrayIcons(states)
	
	global RUN_TEST		:= 1
	global GENERATE_TEST := 2
	
	global ACTUAL	:= 1
	global CORRECT := 2
}

^+r::
	performUnitTest()
return

^+g::
	generateUnitTest()
return

; ^a::
	; DEBUG.popup("test", doTest("Selector", "selector.tl", "selectorSource1.tl"))
; return

; Gather info for unit test action.
getUnitTestInfo(type, ByRef area, ByRef subArea, ByRef inFile, ByRef outFile, ByRef sourceFile = "", ByRef error = "") {
	errMsgs := []
	
	areaInfo 	:= Selector.select("unitTestAreas.tl", "RET_DATA")
	area			:= areaInfo["AREA"]
	subArea		:= areaInfo["SUBAREA"]
	inFile		:= areaInfo["INPUT"]
	outFile		:= areaInfo["OUTPUT"]
	sourceFile	:= areaInfo["SOURCE"]
	; DEBUG.popup("Area Info", areaInfo, "Area", area, "In File", inFile, "Out File", outFile, "Source File", sourceFile)
	
	if(!areaInfo)
		return false
	
	; Allow user to pick individual files for anything not provided.
	if((area = "Selector") && !sourceFile) {
		FileSelectFile, sourceFile, 2, , "Select source file"
		if(!sourceFile)
			errMsgs.Insert("No source file provided")
	}
	if(!inFile) {
		FileSelectFile, inFile, 2, , "Select test file"
		if(!inFile)
			errMsgs.Insert("No test file provided")
	}
	if(!outFile) {
		if(type = RUN_TEST) {
			FileSelectFile, outFile, 2, , "Select results file"
		} else if(type = GENERATE_TEST) {
			FileSelectFile, outFile, S26, , "Select file to output results to"
		}
		
		if(!outFile)
			errMsgs.Insert("No results file provided")
	}
	
	; Check for file existence.
	if(sourceFile && !FileExist(sourceFile))
		errMsgs.Insert("Source file doesn't exist: " sourceFile)
	if(inFile && !FileExist(inFile))
		errMsgs.Insert("Test file doesn't exist: " inFile)
	if(outFile && (type = RUN_TEST) && !FileExist(outFile))
		errMsgs.Insert("Results file doesn't exist: " outFile)
	
	; DEBUG.popup("Source file", sourceFile, "Test file", inFile, "Results file", outFile, "Errors", errMsgs)
	
	; Return (and show error if applicable)
	if(!errMsgs.MaxIndex()) {
		return true
	} else {
		error := "Could not get unit test info: `n"
		For i,e in errMsgs
			error .= "`t" e "`n"
		
		return false
	}
}

performUnitTest(area = "", inFile = "", outFile = "", sourceFile = "") {
	failedTests := []
	
	if(!getUnitTestInfo(RUN_TEST, area, subArea, inFile, outFile, sourceFile, errorMsg)) {
		if(errorMsg)
			MsgBox, % errorMsg
		return
	}
	
	; Run the test.
	results := doTest(area, subArea, inFile, sourceFile)
	
	; Read in what we're checking it against.
	correctLines := fileLinesToArray(outFile)
	; DEBUG.popup("Correct results from file", correctLines)
	
	; Loop over and check the result against the correct one.
	success := true
	For i,r in results {
		correctResult := correctLines[i]
		
		; DEBUG.popup("Line", i, "Transformed result", r, "Correct result", correctResult)
		if(r != correctResult) {
			failedTests[i] := []
			failedTests[i, ACTUAL] := r
			failedTests[i, CORRECT] := correctResult
			success := false
		}
	}
	
	if(success) {
		MsgBox, Unit test is good!
	} else {
		failedString := "Unit tests failed: `n`n"
		For i,f in failedTests {
			failedString .= "Test " i ":`n`tCorrect: " f[CORRECT] "`n`tActual: " f[ACTUAL] "`n`n"
		}
		
		MsgBox, % failedString
		; DEBUG.popup("Success", success, "Failed tests", failedString)
	}
}

generateUnitTest(area = "", inFile = "", outFile = "", sourceFile = "") {
	results := []
	
	if(!getUnitTestInfo(GENERATE_TEST, area, subArea, inFile, outFile, sourceFile, errorMsg)) {
		MsgBox, % errorMsg
		return
	}
	
	; Run the test.
	results := doTest(area, subArea, inFile, sourceFile)
	; DEBUG.popup("Generated lines to store", results)
	
	; Write the results to the output file.
	FileDelete, % outFile ; In case it exists already, need a clean slate.
	For i,r in results {
		if(i > 1)
			FileAppend, `n, %outFile%
		FileAppend, %r%, %outFile%
	}
	
	if(ERRORLEVEL = 1)
		MsgBox, Failed to write results to file!
	else
		Run, % outFile
}

doTest(area, subArea, inFile, sourceFile) {
	outLines := []
	
	if(area = "TableList") {
		
		if(subArea = "SETTINGS") {
			tlSettings := []
			tlSettings["FILTER", "COLUMN"] := "MACHINE"
			tlSettings["FILTER", "INCLUDE", "VALUE"]  := "HOME_DESKTOP"
			; tlSettings["FILTER", "INCLUDE", "BLANKS"] ; Defaults to true
		}
		
		results := TableList.parseFile(inFile, tlSettings)
		; DEBUG.popup("results", results)
		
		; Loop over and transform the outputs.
		For line,res in results {
			; Transform the output into ^-delimited form.
			actualResult := ""
			For j,r in res {
				if(IsObject(r))
					For m,subResult in r
						actualResult .= subResult "_"
				else
					actualResult .= r
				actualResult .= "^"
			}
			
			outLines[line] := actualResult
		}
	} else if(area = "Selector") { ; For east in list of choices, do a selection and put it into outLines.
		if(subArea = "DATA")
			actionType := "RET_OBJ"
		else
			actionType := "RET"
		
		lines := fileLinesToArray(inFile)
		For i,line in lines {
			output := Selector.select(sourceFile, actionType, line)
			
			if(subArea = "DATA") ; Returned object for special case, so we can see if model data is coming through.
				output := output.data["RESULT"] "^" output.data["MODIFIER"]
			
			outLines[i] := output
		}
	} else {
		MsgBox, Unknown area!
	}
	
	; DEBUG.popup("Unit test doTest", "Finish", "Out lines", outLines)
	
	return outLines
}


{ ; Exit/reload hotkeys.
	~#!x::
		Suspend
		suspended := !suspended
		updateTrayIcon()
	return

	; Exit, reload, and suspend.
	~!+x::ExitApp
	; ~#!x::Suspend
	~^!r::
	~!+r::
		Suspend, Permit
		Reload
	return
}
