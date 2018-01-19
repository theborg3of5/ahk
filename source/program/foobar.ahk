; Hotkey catches for if foobar isn't running.
#IfWinNotExist, ahk_class {97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}
	; ^!Up::
	; ^!Down::
	; ^!Left::
	; ^!Right::
	; ~Media_Stop::
	; ~Media_Play_Pause::
	; ~Media_Prev::
	; ~Media_Next::
	#j::
		RunAsUser(MainConfig.getProgram("Foobar", "PATH"))
	return
#IfWinNotExist

^!Up::   Send, {Media_Stop}
^!Down:: Send, {Media_Play_Pause}
^!Left:: Send, {Media_Prev}
^!Right::Send, {Media_Next}

^!Space::Send, {Volume_Down}{Volume_Up} ; Makes Windows 10 media panel show up

; If foobar is indeed running.
#IfWinExists, ahk_class {97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}
	
	#j::
		Send, ^+j
		WinWait, Media Library Search ahk_exe foobar2000.exe
		WinActivate
	return
#IfWinExists

; Media library search.
bottomAreaControl := "{4B94B650-C2D8-40de-A0AD-E8FADF62D56C}1"
#IfWinActive, Media Library Search ahk_exe foobar2000.exe
	; Special search ability: enter moves it down to the list instead of playing the search.
	Enter::
		ControlGetFocus, currentlyActiveControl
		
		if(currentlyActiveControl != bottomAreaControl) { ; Bottom control is not selected, so input textbox is, or else textbox is - grab first result.
			ControlFocus, % bottomAreaControl ; Activate bottom area for consistency.
			Send, {Home}
		}
		
		Send, ^p ; Play
		Sleep, 100
		WinClose
	return

	; Special for search: moves to first item in list instead of buttons on right, and back.
	Tab::
		send {TAB}{TAB}{TAB}{DOWN}
	return
	+Tab::
		send +{TAB}{TAB}{TAB}
	return	
#IfWinActive
