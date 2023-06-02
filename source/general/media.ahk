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
		Toast.ShowMedium(muteMessage)
	}

; Media control
^!Down:: Send, {Media_Play_Pause}
^!Left:: Send, {Media_Prev}
^!Right::Send, {Media_Next}
^!Up::
Media_Stop::
	Config.runProgram("Spotify")
return

; SoundSwitch handling
#If Config.doesWindowExist("SoundSwitch")
	^F12::SoundSwitch.toggleDevices()
#If
