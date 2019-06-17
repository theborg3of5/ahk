; Up and down at an interval.
#PgUp::Send {Volume_Up 5}
#PgDn::Send {Volume_Down 5}

; Toggle Mute.
#Enter::VA_SetMasterMute(!VA_GetMasterMute())

; Change the media player that media keys will deal with.
^Volume_Mute::
	changeMediaPlayer() {
		s := new Selector("mediaPlayers.tls")
		programName := s.selectGui("PROGRAM_NAME")
		if(programName) {
			MainConfig.mediaPlayer := programName
			Toast.showMedium("Media player set to: " programName)
		}
	}

#If !MainConfig.doesMediaPlayerExist()
	^!Up::
	^!Down::
	^!Left::
	^!Right::
	Media_Stop::
	Media_Play_Pause::
	Media_Prev::
	Media_Next::
		MainConfig.runMediaPlayer()
	return
#If MainConfig.doesMediaPlayerExist()
	^!Up::
	Media_Stop::
		MainConfig.runMediaPlayer()
	return
	
	Media_Play_Pause::sendMediaKey("Media_Play_Pause")
	Media_Prev::      sendMediaKey("Media_Prev")
	Media_Next::      sendMediaKey("Media_Next")
	^!Down::          sendMediaKey("Media_Play_Pause")
	^!Left::          sendMediaKey("Media_Prev")
	^!Right::         sendMediaKey("Media_Next")
#If
