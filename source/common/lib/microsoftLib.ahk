; A static library of Microsoft-level constants and system values.

class MicrosoftLib {
	; #PUBLIC#
	
	; @GROUP@ Window styles ( https://www.autohotkey.com/docs/commands/SysGet.htm#Numeric )
	static Style_Caption := 0xC00000   ; The window has a caption - that is, a top bar + borders (WS_CAPTION)
	static Style_Sizable := 0x40000    ; Window can be sized (WS_SIZEBOX/WS_THICKFRAME).
	static Style_Visible := 0x10000000 ; Window is visible (WS_VISIBLE)
	; @GROUP-END@
	
	; @GROUP@ Extended window styles
	static ExStyle_AlwaysOnTop  := 0x8   ; Always on top (WS_EX_TOPMOST)
	static ExStyle_ClickThrough := 0x20  ; Clicking on the window actually clicks on whatever is below it (WS_EX_CLICKTHROUGH).
	static ExStyle_SunkenBorder := 0x200 ; Controls: border with sunken edge, on by default for many control types (WS_EX_CLIENTEDGE).
	; @GROUP-END@
	
	; @GROUP@ System-level window measurements ( https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics )
	static BorderX                 := SysGet(5)  ; For non-3D windows (which should be most), the thickness of the left/right borders (uses SM_CXBORDER).
	static BorderY                 := SysGet(6)  ; For non-3D windows (which should be most), the thickness of the top/bottom borders (uses SM_CYBORDER).
	static FrameX_CaptionNoSizable := SysGet(7)  ; Thickness of the left/right borders for windows with a caption that are NOT sizable (uses SM_CXFIXEDFRAME).
	static FrameY_CaptionNoSizable := SysGet(8)  ; Thickness of the top/bottom borders for windows with a caption that are NOT sizable (uses SM_CYFIXEDFRAME).
	static FrameX_CaptionSizable   := SysGet(32) ; Thickness of the left/right borders for windows with a caption that are sizable (uses SM_CXSIZEFRAME/SM_CXFRAME).
	static FrameY_CaptionSizable   := SysGet(33) ; Thickness of the top/bottom borders for windows with a caption that are sizable (uses SM_CYSIZEFRAME/SM_CYFRAME).
	static MaximizedWindowHeight   := SysGet(61) ; Total width of a maximized window on the primary monitor. Includes any weird offsets. (uses SM_CXMAXIMIZED)
	static MaximizedWindowWidth    := SysGet(62) ; Total height of a maximized window on the primary monitor. Includes any weird offsets. (uses SM_CYMAXIMIZED)
	; @GROUP-END@
	
	; @GROUP@ Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	static Message_WindowMenu  := 0x112 ; Doing something from the "Window" menu, or clicking one of the max/min/restore/close buttons (WM_SYSCOMMAND)
	static Message_HorizScroll := 0x114 ; Scroll event in the window's horizontal scroll bar (WM_HSCROLL)
	; @GROUP-END@
	
	; @GROUP@ Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	static ScrollBar_Left  := 0 ; Scroll 1 unit to the left (SB_LINELEFT)
	static ScrollBar_Right := 1 ; Scroll 1 unit to the right (SB_LINERIGHT)
	; @GROUP-END@
	; #END#
}
