; Up and down at an interval.
#PgUp:: Send("{Volume_Up 5}")
#PgDn:: Send("{Volume_Down 5}")
#+PgUp::Send("{Volume_Up}")
#+PgDn::Send("{Volume_Down}")

; Toggle Mute.
#Enter::
	toggleMute(*) {
		SoundSetMute(-1)
		if(SoundGetMute())
			muteMessage := "Volume muted"
		else
			muteMessage := "Volume unmuted"
		Toast.ShowMedium(muteMessage)
	}
