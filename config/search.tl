@PlaceholderChar=-

=Select type of search to run and input search text:
+DefaultAction=RET_DATA
+ShowDataInputs=1

(		NAME					ABBREV		SUBTYPE															SEARCH_TYPE		ARG1		ARG2		ARG3		ARG4		ARG5	APPKEY	MACHINE
)		0						0				0																	0					1			2			3			4			5		0			0

[+1|{MACHINE}b:EPIC_DESKTOP]
	[+2|{SEARCH_TYPE}b:CODESEARCH]
		# Codesearch
		Server				s				Server
		Client				c				Client
		Server + Client	sc|cs			Server|Client
		Records				r				Records
		Other					o|p			ProgPoint
		All					a				Server|Client|Records|ProgPoint
	[-2]
		
		# Codesearch Specifics
		Server DBC			sd				Server															CODESEARCH		-			-			-			-			-		DBC
		
		# | Other
		Guru					gu				-																	GURU
		DBC Wiki				d				dbc																WIKI
[-1]
	
		# General
		Google				g				https://www.google.com/search?q=%s						WEB
		Youtube				yt				https://www.youtube.com/results?search_query=%s		WEB
		AutoHotkey Docs	ahk			https://cse.google.com/cse?cx=010629462602499112316:ywoq_rufgic&q=menu#gsc.tab=0&gsc.q=%s&gsc.sort=&gsc.page=1&gsc.ref=more%3Adocumentation	WEB
