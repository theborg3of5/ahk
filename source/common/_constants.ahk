; Window styles
global WS_CAPTION := 0xC00000   ; Window has a caption (top bar + borders).
global WS_SIZEBOX := 0x40000    ; Window can be resized (aka WS_THICKFRAME).
global WS_VISIBLE := 0x10000000 ; Window is visible

; Extended window styles
global WS_EX_CONTROLPARENT := 0x10000
global WS_EX_APPWINDOW     := 0x40000
global WS_EX_WS_EX_TOPMOST := 0x8      ; Always on top
global WS_EX_TOOLWINDOW    := 0x80
global WS_EX_CLICKTHROUGH  := 0x20

; SysGet command numbers (https://autohotkey.com/docs/commands/SysGet.htm)
global SM_CXBORDER     := 5  ; For non-3D windows (which should be most), the width of the border on the left and right.
global SM_CYBORDER     := 6  ; For non-3D windows (which should be most), the width of the border on the top and bottom.
global SM_CXFIXEDFRAME := 7  ; Width of the horizontal frame for a window with a caption that cannot be resized.
global SM_CYFIXEDFRAME := 8  ; Width of the vertical frame for a window with a caption that cannot be resized.
global SM_CXSIZEFRAME  := 32 ; Width of the horizontal frame for a window with a caption that cannot be resized (aka SM_CXFRAME).
global SM_CYSIZEFRAME  := 33 ; Width of the vertical frame for a window with a caption that cannot be resized (aka SM_CYFRAME).
global SM_CXMAXIMIZED  := 61 ; Width of a maximized window on the primary monitor. Includes any weird offsets.
global SM_CYMAXIMIZED  := 62 ; Height of a maximized window on the primary monitor. Includes any weird offsets.

; Windows Messages (https://autohotkey.com/docs/misc/SendMessageList.htm)
global WM_SYSCOMMAND := 0x112
global WM_HSCROLL    := 0x114

; Scroll Bar Requests/Messages (https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars)
global SB_LINELEFT  := 0
global SB_LINERIGHT := 1

; Delimiters and special characters
global DOUBLE_QUOTE := """"

; Title match modes
global TITLE_MATCH_MODE_Start   := 1
global TITLE_MATCH_MODE_Contain := 2
global TITLE_MATCH_MODE_Exact   := 3
global TITLE_MATCH_MODE_RegEx   := "RegEx"

; MsgBox button options
global MSGBOX_BUTTONS_OK                       := 0
global MSGBOX_BUTTONS_OK_CANCEL                := 1
global MSGBOX_BUTTONS_ABORT_RETRY_IGNORE       := 2
global MSGBOX_BUTTONS_YES_NO_CANCEL            := 3
global MSGBOX_BUTTONS_YES_NO                   := 4
global MSGBOX_BUTTONS_RETRY_CANCEL             := 5
global MSGBOX_BUTTONS_CANCEL_TRYAGAIN_CONTINUE := 6

; MinMax states for a window (for WinGet's MinMax sub-command)
global WINMINMAX_MIN   := -1
global WINMINMAX_MAX   := 1
global WINMINMAX_OTHER := 0

; Control styles
global WS_EX_CLIENTEDGE := 0x200 ; Border with sunken edge (on by default for many control types)

; Windows Screen constants (from MonitorFromWindow: https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
global MONITOR_DEFAULTTONEAREST := 0x00000002
