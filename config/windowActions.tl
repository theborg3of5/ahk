(	NAME										ESC		MIN		SELECT_ALL	DELETE_WORD		CLOSE

	Cisco AnyConnect VPN					CLOSE
	Explorer									MIN		OTHER
	GitHub									CLOSE
	grepWin									CLOSE
	KDiff										CLOSE
	Mattermost								CLOSE		CLOSE
	Notepad									CLOSE		-			-				CTRL_SHIFT
	Pidgin Buddy List						CLOSE		CLOSE
	RepublicAnywhere						CLOSE		CLOSE
	Skype Buddy List						CLOSE
	Spotify									CLOSE		CLOSE		-				-					OTHER
	Telegram									CLOSE		CLOSE		-				-					-
	Thunder									CLOSE
	WinSpy									CLOSE
	
	VB6										-			POST_MESSAGE
	
	; EMC2 popups
[ESC.replaceWith(CLOSE)|DELETE_WORD.replaceWith(CTRL_SHIFT)]
	EMC2 DLG email
	EMC2 QAN notes
	EMC2 Issue email
	EMC2 Issue popup
	EMC2 QAN email notify
	EMC2 QAN email							-			-			HOME_END
[]
	
	; EpicStudio popups
	EpicStudio New Object Window		-			-			-				CTRL_SHIFT
	EpicStudio Tokenize String			-			-			-				CTRL_SHIFT
	
	AHK GUIs									CLOSE		-			-				CTRL_SHIFT
	
	; Web popups - close on Escape.
	Chrome Join								CLOSE
	Chrome TickTick						CLOSE
	