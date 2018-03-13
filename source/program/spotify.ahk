; Hotkey catches for if Spotify isn't running.
#If !WinExist(getWindowTitleString("Spotify"))
	^!Up::
	^!Down::
	^!Left::
	^!Right::
	~Media_Stop::
	~Media_Play_Pause::
	~Media_Prev::
	~Media_Next::
	#j::
		runProgram("Spotify")
	return
#IfWinNotExist

; If Spotify is indeed running.
#If WinExist(getWindowTitleString("Spotify"))
	^!Up::   Send, {Media_Stop}
	^!Down:: Send, {Media_Play_Pause}
	^!Left:: Send, {Media_Prev}
	^!Right::Send, {Media_Next}

	^!Space::Send, {Volume_Down}{Volume_Up} ; Makes Windows 10 media panel show up
	#j::
		runProgram("Spotify")
		WinWaitActive, % getWindowTitleString("Spotify")
		Send, ^l
	return
#IfWinExists
