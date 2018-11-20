; Up and down at an interval.
#PgUp::Send {Volume_Up 5}
#PgDn::Send {Volume_Down 5}

; Toggle Mute.
#Enter::VA_SetMasterMute(!VA_GetMasterMute())



^Volume_Mute::
	changeMediaPlayer() {
		s := new Selector("mediaPlayers.tls")
		programName := s.selectGui("PROGRAM_NAME")
		if(programName)
			MainConfig.setSetting("MEDIA_PLAYER", programName)
	}


	
#If !MainConfig.doesMediaPlayerExist()
	^!Up::
	^!Down::
	^!Left::
	^!Right::
	Media_Play_Pause::
	Media_Prev::
	Media_Next::
		Toast.showForTime(MainConfig.getMediaPlayer() " not yet running, launching...", 2)
		MainConfig.runMediaPlayer()
	return
#If MainConfig.doesMediaPlayerExist()
	^!Up::MainConfig.runMediaPlayer()
	
	Media_Play_Pause::sendMediaKey("Media_Play_Pause")
	Media_Prev::      sendMediaKey("Media_Prev")
	Media_Next::      sendMediaKey("Media_Next")
	^!Down::          sendMediaKey("Media_Play_Pause")
	^!Left::          sendMediaKey("Media_Prev")
	^!Right::         sendMediaKey("Media_Next")
#If

sendMediaKey(keyName) {
	if(!keyName)
		return
	
	if(MainConfig.isMediaPlayer("Chrome")) { ; Youtube - special case that won't respond to media keys natively
		; GDB TODO
		
	} else {
		Send, % "{" keyName "}"
	}
}
