; Main Snapper window
#If Config.isWindowActive("Snapper")
	^h:: Snapper.sendItemsToIgnore() ; Send string of items to ignore, based on the given INI.
	^+d::Snapper.diffHelpText()      ; Diff the selected help text
#If

; Add record window
#If Config.isWindowActive("Snapper Add Records")
	^Enter::Snapper.addMultipleRecordsFromAddPopup()
#If
