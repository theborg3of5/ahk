; Hotkey catches for if foobar isn't running.
#IfWinNotExist, ahk_class {97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}
	^!Up::
	^!Down::
	^!Left::
	^!Right::
		RunAsUser(MainConfig.getProgram("Foobar", "PATH"))
	return
#IfWinNotExist

; If foobar is indeed running.
#IfWinExists, ahk_class {97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}
	^!Up::   Send, ^!{NumPad1} ; {Media_Stop}
	^!Down:: Send, ^!{NumPad2} ; {Media_Play_Pause}
	^!Left:: Send, ^!{NumPad3} ; {Media_Prev}
	^!Right::Send, ^!{NumPad4} ; {Media_Next}
	
	; Special activation of foobar window for search.
	~#j::
		WinGetTitle, prevWin, A
		Sleep, 100
		WinActivate, ahk_class {483DF8E3-09E3-40d2-BEB8-67284CE3559F}
	return
#IfWinExists
	
; Main foobar window.
#IfWinActive, ahk_class {97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}
	; Turn cursor-following-playback off.
	; ^+c::Send !pf
	
	; Turn playback-following-cursor off.
	; ^+p::Send !pu
	
	; Similar to library shortcuts, but for main window.
	^Enter::
		Send, {Enter}
		minimizeWindow()
	return
	+Enter::
		Send, ^+q
		minimizeWindow()
	return
#IfWinActive

; Media library search.
#IfWinActive, Media Library Search
	; Special search ability: enter moves it down to the list instead of playing the search.
	Enter::PlaySong()

	; Special search ability: shift-enter moves it down to the list instead of playing the search.
	+Enter::PlaySong(1)

	; nowOrLater = 1 for adding to queue instead of playing now.
	PlaySong(nowOrLater = 0) {
		ControlGetFocus, currentlyActiveControl
		; MsgBox, % currentlyActiveControl
		
		if(currentlyActiveControl != "{4B94B650-C2D8-40de-A0AD-E8FADF62D56C}1" or currentlyActiveControl == "Edit1") {	; Bottom control is not selected, so input textbox is, or else textbox is - grab first result.
			ControlFocus, {4B94B650-C2D8-40de-A0AD-E8FADF62D56C}1  ; Activate bottom area for consistency.
			Send, {Home}
		}
		
		if(!nowOrLater) {
			Send, ^p
		} else {
			Send, ^+q
		}
		
		Sleep, 100
		WinClose, A
		WinActivate %prevWin%
	}

	; Special for search: moves to first item in list instead of buttons on right, and back.
	Tab::
		send {TAB}{TAB}{TAB}{DOWN}
	return
	+Tab::
		send +{TAB}{TAB}{TAB}
	return	
#IfWinActive
