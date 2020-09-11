; Main Snapper window
#If Config.isWindowActive("Snapper")
	; Send string of items to ignore, based on the given INI.
	^h::Snapper.sendItemsToIgnore()
#If

; Add record window
#If Config.isWindowActive("Snapper Add Records")
	^Enter::Snapper.addMultipleRecordsFromAddPopup()
#If
