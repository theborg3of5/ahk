; Main Snapper window
#HotIf Config.isWindowActive("Snapper")
	^h:: Snapper.sendItemsToIgnore()       ; Send string of items to ignore, based on the given INI.
	^+d::Snapper.diffMultiResponseValues() ; Diff the selected help text
#HotIf

; Add record window
#HotIf Config.isWindowActive("Snapper Add Records")
	^Enter::Snapper.addMultipleRecordsFromAddPopup()
#HotIf
