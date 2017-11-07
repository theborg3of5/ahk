#IfWinActive, ahk_exe Snapper.exe
	; Send string of status items to ignore, based on the given master file.
	:*:.status::
		doSelect("local\chroniclesStatusItems.tl")
	return
#IfWinActive
