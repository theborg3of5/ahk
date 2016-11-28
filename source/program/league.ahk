; League of Legends
#IfWinActive, ahk_class RiotWindowClass
	; Chat hotstrings
	:*:/gg::/all gg{Enter}
	:*:/gl::/all glhf{Enter}
	:*:/s::/surrender{Enter}
	:*:/ns::/nosurrender{Enter}
	
	; Also center map when going out of focus
	~F9::
		Send, c
	return
#IfWinActive

; Main client
#IfWinActive, ahk_exe LolClient.exe
	; Chat hotstrings
	:*:adc::adc{Enter}
#IfWinActive
