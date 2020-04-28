; Main Snapper window
#If Config.isWindowActive("Snapper")
	; Send string of items to ignore, based on the given INI.
	^h::Snapper.sendItemsToIgnore()
#If

; Add record window
#If WinActive("Add a Record " Config.windowInfo["Snapper"].titleString)
	^Enter::Snapper.addMultipleRecordsFromAddPopup()
#If
