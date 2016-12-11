; GENERAL SPECIAL CHARS
# This	should	not	be	separated	at	all.

# MODS WITH NO LABELS OR ROW PARTS
; Begin
[b:A]
	123456
[]
; End
[e:B]
	123456
[]
; Modify
[m(2):D|m(3,2):E]
	123456
[]

# PARTS
; Begin
[{1}b:A]
	123456	7891011
[]
; End
[{1}e:B]
	123456	7891011
[]
; Modify
[{1}m(2):D|{2}m(3,2):E]
	123456	7891011
[]

# LABELS
; Begin
[+1|{1}b:A]
	123456
[-1]
; End
[+2|{1}e:B]
	123456
[-2]
; Modify
[+4|{1}m(2):D|{2}m(3,2):E]
	123456	7891011
[-4]

# MOD PRE-PROCESSING
; Begin
[+1|{1}b:A]
	[+2|*{1}b:a]
		123456
	[-2]
[-1]
; End
[+3|{1}e:B]
	[+4|*{1}e:b]
		123456
	[-3]
[-4]
; Modify
[+7|{1}m(2):D|{2}m(3,2):E]
	[+8|*{1}m(2):d|*{2}m(3,2):e]
		123456	7891011
	[-7]
[-8]

