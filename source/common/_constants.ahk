; (MS) Windows-related
	; Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	global WM_SYSCOMMAND := 0x112
	global WM_HSCROLL    := 0x114
	
	; Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	global SB_LINELEFT  := 0
	global SB_LINERIGHT := 1
	
	; Windows Screen constants (from MonitorFromWindow: https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	global MONITOR_DEFAULTTONEAREST := 0x00000002
