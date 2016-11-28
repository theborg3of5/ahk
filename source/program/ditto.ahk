#IfWinActive, ahk_class QPasteClass
	; Easy access to options dialog.
	!o::
		Send, {AppsKey}o
	return
#IfWinActive
