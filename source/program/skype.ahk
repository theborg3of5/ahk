; Buddy list.
#IfWinActive, ahk_class tSkMainForm
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
