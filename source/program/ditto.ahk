#IfWinActive, ahk_class QPasteClass
	; Easy access to options dialog.
	!o::
		Send, {AppsKey}o
	return
#IfWinActive

#IfWinActive, ahk_class Ditto Edit Wnd
	; Better hotkey to save clip and put it on the clipboard.
	^s::
	+Enter::
	^Enter::
		Send, +{Escape}
		WinWaitActive, Copy Properties
		Send, {Enter}
	return
#IfWinActive

; Edit the clipboard using Ditto.
$!v::
	Send, ^+v
	WinWaitActive, ahk_class QPasteClass
	Send, ^n ; New clip
return
