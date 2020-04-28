
; Compare the selected text to the last-copied clip.
+#d::
	; Put the selected text on the clipboard.
	Send, ^c
	
	; Open Ditto and wait for it to appear
	Send, ^+v
	WinWaitActive, ahk_class QPasteClass
	
	; Select both the latest clip (auto-selected) and the next one down (which was previously the last-copied clip).
	Sleep, 500 ; Takes a smidge longer before we can do this for some reason.
	Send, +{Down}
	
	; Compare with Ditto functionality.
	Send, ^{F2}
return

; Clip edit window
#IfWinActive, ahk_exe Ditto.exe ahk_class Ditto Edit Wnd
	; Better hotkey to save clip and put it on the clipboard.
	^s::
	Enter::
	NumPadEnter::
		Send, +{Escape}
		WinWaitActive, Copy Properties
		Send, {Enter}
	return
#IfWinActive
