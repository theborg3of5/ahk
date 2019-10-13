; (MS) Windows-related
	; Window styles ( https://www.autohotkey.com/docs/commands/SysGet.htm#Numeric )
	global WS_CAPTION := 0xC00000   ; Window has a caption (top bar + borders).
	global WS_SIZEBOX := 0x40000    ; Window can be resized (aka WS_THICKFRAME).
	
	; Extended window styles
	global WS_EX_CLICKTHROUGH := 0x20  ; Clicking on the window actually clicks on whatever is below it.
	global WS_EX_CLIENTEDGE   := 0x200 ; Controls: border with sunken edge (on by default for many control types)
	
	; SysGet command numbers ( https://autohotkey.com/docs/commands/SysGet.htm )
	global SM_CXBORDER     := 5  ; For non-3D windows (which should be most), the width of the border on the left and right.
	global SM_CYBORDER     := 6  ; For non-3D windows (which should be most), the width of the border on the top and bottom.
	global SM_CXFIXEDFRAME := 7  ; Width of the horizontal frame for a window with a caption that cannot be resized.
	global SM_CYFIXEDFRAME := 8  ; Width of the vertical frame for a window with a caption that cannot be resized.
	global SM_CXSIZEFRAME  := 32 ; Width of the horizontal frame for a window with a caption that cannot be resized (aka SM_CXFRAME).
	global SM_CYSIZEFRAME  := 33 ; Width of the vertical frame for a window with a caption that cannot be resized (aka SM_CYFRAME).
	global SM_CXMAXIMIZED  := 61 ; Width of a maximized window on the primary monitor. Includes any weird offsets.
	global SM_CYMAXIMIZED  := 62 ; Height of a maximized window on the primary monitor. Includes any weird offsets.
	
	; Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	global WM_SYSCOMMAND := 0x112
	global WM_HSCROLL    := 0x114
	
	; Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	global SB_LINELEFT  := 0
	global SB_LINERIGHT := 1
	
	; Windows Screen constants (from MonitorFromWindow: https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	global MONITOR_DEFAULTTONEAREST := 0x00000002
