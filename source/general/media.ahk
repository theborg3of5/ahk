; Up and down at an interval.
#PgUp::Send {Volume_Up 5}
#PgDn::Send {Volume_Down 5}

; Toggle Mute.
#Enter::
	toggleMute() {
		SoundSet, +1, , MUTE
		if(SoundGet("", "MUTE") = "On")
			muteMessage := "Volume muted"
		else
			muteMessage := "Volume unmuted"
		new Toast(muteMessage).showMedium()
	}

; SoundSwitch handling
#If Config.doesWindowExist("SoundSwitch")
	^F12::SoundSwitch.toggleDevices()
#If

#If !Config.doesWindowExist("Spotify")
	^!Up::
	^!Down::
	^!Left::
	^!Right::
	Media_Stop::
	Media_Play_Pause::
	Media_Prev::
	Media_Next::
		Config.runProgram("Spotify")
	return
#If Config.doesWindowExist("Spotify")
	^!Up::
	Media_Stop::
		Config.runProgram("Spotify")
	return
	
	^!Down:: Send, {Media_Play_Pause}
	^!Left:: Send, {Media_Prev}
	^!Right::Send, {Media_Next}
#If
