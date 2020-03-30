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

; Change the media player that media keys will deal with.
^Volume_Mute::
	changeMediaPlayer() {
		programName := new Selector("mediaPlayers.tls").selectGui("PROGRAM_NAME")
		if(programName) {
			Config.mediaPlayer := programName
			new Toast("Media player set to: " programName).showMedium()
		}
	}

#If Config.machineIsHomeDesktop()
	; SoundSwitch: toggle the recording device along with the output device.
	~^F12::^+F12
#If

#If !Config.doesMediaPlayerExist()
	^!Up::
	^!Down::
	^!Left::
	^!Right::
	Media_Stop::
	Media_Play_Pause::
	Media_Prev::
	Media_Next::
		Config.runMediaPlayer()
	return
#If Config.doesMediaPlayerExist()
	^!Up::
	Media_Stop::
		Config.runMediaPlayer()
	return
	
	^!Down:: Send, {Media_Play_Pause}
	^!Left:: Send, {Media_Prev}
	^!Right::Send, {Media_Next}
#If
