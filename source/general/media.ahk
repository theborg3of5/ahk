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
		new Toast().showMedium(muteMessage)
	}

; Change the media player that media keys will deal with.
^Volume_Mute::
	changeMediaPlayer() {
		programName := new Selector("mediaPlayers.tls").selectGui("PROGRAM_NAME")
		if(programName) {
			Config.mediaPlayer := programName
			Toast.showMedium("Media player set to: " programName)
		}
	}

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
	
	Media_Play_Pause::sendMediaKey("Media_Play_Pause")
	Media_Prev::      sendMediaKey("Media_Prev")
	Media_Next::      sendMediaKey("Media_Next")
	^!Down::          sendMediaKey("Media_Play_Pause")
	^!Left::          sendMediaKey("Media_Prev")
	^!Right::         sendMediaKey("Media_Next")
#If
