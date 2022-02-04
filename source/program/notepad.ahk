; Notepad hotkeys.
#If Config.isWindowActive("Notepad")
	; Delete a line.
	^d::
		Send, {End}{Right}               ; Start of next line
		Send, {Shift Down}{Up}{Shift Up} ; Select entire original line, including newline
		Send, {Delete}                   ; Delete the selection
		Send, {Home}                     ; Get to the start of the line, after indentation
	return
#If
