@PlaceholderChar=-

=Select type of search to run and input search text:
+ShowArbitraryInputs=1
+ColumnWidth=500

(	NAME					ABBREV		SUBTYPE															SEARCH_TYPE		ARG1		ARG2		ARG3		ARG4		ARG5
)	0						0				0																	0					1			2			3			4			5
	
# Codesearch
[+1|{SEARCH_TYPE}b:CODESEARCH]
	Server				s				Server
	Client				c				Client
	Server + Client	sc|cs			Server|Client
	Records				r				Records
	Other					o|p			ProgPoint
	All					a				Server|Client|Records|ProgPoint
[-1]
	
# Other
	Guru					gu				-																	GURU
	DBC Wiki				d				dbc																WIKI

# General
	Google				g				https://www.google.com/search?q=%s						WEB
	Youtube				yt				https://www.youtube.com/results?search_query=%s		WEB
