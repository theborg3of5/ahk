; Buddy list.
#IfWinActive, ahk_class tSkMainForm
	; Close the window.
	^!s::Send !{F4}
	
	; Options.
	!o::Send !to
#IfWinActive

; Conversation window.
#IfWinActive, ahk_class TConversationForm
	; Snapshot.
	^+s::
		Send !adv
		Sleep, 500
		WinActivate, ahk_class TConversationForm
	return
#IfWinActive
