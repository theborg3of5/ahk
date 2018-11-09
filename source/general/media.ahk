; Up and down at an interval.
#PgUp::Send {Volume_Up 5}
#PgDn::Send {Volume_Down 5}

; Toggle Mute.
#Enter::VA_SetMasterMute(!VA_GetMasterMute())



^Volume_Mute::
	changeMediaPlayer() {
		s := new Selector("mediaPlayers.tls")
		MainConfig.setSetting("MEDIA_PLAYER", s.selectGui("KEY"))
	}
