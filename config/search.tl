@PlaceholderChar=-

=Select type of search to run and input search text:
+DefaultAction=RET_DATA
+ShowDataInputs=1

(		NAME								ABBREV		SUBTYPE															SEARCH_TYPE		ARG1		ARG2		ARG3		ARG4		ARG5	APPKEY	MACHINE
)		0									0				0																	0					1			2			3			4			5		0			0

[+1|{MACHINE}r:EPIC_LAPTOP]
	[+2|{SEARCH_TYPE}r:CODESEARCH]
		# Codesearch
		Server							s				Server
		Client							c				Client
		Server + Client				sc|cs			Server|Client
		Records							r				Records
		Other								o|p			ProgPoint
		All								a				Server|Client|Records|ProgPoint
		
		# Codesearch Specifics
		Server DBC						sd				Server															CODESEARCH		-			-			-			-			-		DBC
	[-2]
		
		# | Other
		Guru								gu				-																	GURU
		DBC Wiki							d				dbc																WIKI
[-1]

[+3|{SEARCH_TYPE}r:WEB]
		# Web
		; (SUBTYPE = <URL with %s for query>)
		Google							g				https://www.google.com/search?q=%s
		Youtube							yt				https://www.youtube.com/results?search_query=%s
		AutoHotkey Docs				ahkd			https://cse.google.com/cse?cx=010629462602499112316:ywoq_rufgic&q=menu#gsc.tab=0&gsc.q=%s&gsc.sort=&gsc.page=1&gsc.ref=more%3Adocumentation
		Translate Dutch > English	tde|detrans	https://translate.google.com/#nl/en/%s
		Translate English > Dutch	ted|edtrans	https://translate.google.com/#en/nl/%s
[-3]
		
[+4|{SEARCH_TYPE}r:GREPWIN]
		# GrepWin
		; (SUBTYPE = folder)
		AHK Root							ahkr			<AHK_ROOT>
		AHK Source						ahkf|ahks	<AHK_SOURCE>
[-4]
		
		# Other
		Everything (file search)	ev				-																	EVERYTHING
