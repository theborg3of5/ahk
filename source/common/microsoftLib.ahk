/* A library of Microsoft-level constants and system values (cached at startup).
*/

class MicrosoftLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	; Window styles ( https://www.autohotkey.com/docs/commands/SysGet.htm#Numeric )
	static Style_Caption := 0xC00000   ; WS_CAPTION - Window has a caption (top bar + borders).
	static Style_Sizable := 0x40000    ; WS_SIZEBOX - Window can be sized (aka WS_THICKFRAME).
	static Style_Visible := 0x10000000 ; WS_VISIBLE - Window is visible
	
	; Extended window styles
	static ExStyle_AlwaysOnTop  := 0x8   ; WS_EX_TOPMOST - Always on top
	static ExStyle_ClickThrough := 0x20  ; WS_EX_CLICKTHROUGH - Clicking on the window actually clicks on whatever is below it.
	static ExStyle_SunkenBorder := 0x200 ; WS_EX_CLIENTEDGE - Controls: border with sunken edge (on by default for many control types)
	
	; System-level window measurements ( https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics )
	static BorderX                 := SysGet(5 ) ; SM_CXBORDER     - For non-3D windows (which should be most), the thickness of the left/right borders.
	static BorderY                 := SysGet(6 ) ; SM_CYBORDER     - For non-3D windows (which should be most), the thickness of the top/bottom borders.
	static FrameX_CaptionNoSizable := SysGet(7 ) ; SM_CXFIXEDFRAME - Thickness of the left/right borders for windows with a caption that are NOT sizable.
	static FrameY_CaptionNoSizable := SysGet(8 ) ; SM_CYFIXEDFRAME - Thickness of the top/bottom borders for windows with a caption that are NOT sizable.
	static FrameX_CaptionSizable   := SysGet(32) ; SM_CXSIZEFRAME  - Thickness of the left/right borders for windows with a caption that are sizable (aka SM_CXFRAME).
	static FrameY_CaptionSizable   := SysGet(33) ; SM_CYSIZEFRAME  - Thickness of the top/bottom borders for windows with a caption that are sizable (aka SM_CYFRAME).
	static MaximizedWindowHeight   := SysGet(61) ; SM_CXMAXIMIZED  - Total width of a maximized window on the primary monitor. Includes any weird offsets.
	static MaximizedWindowWidth    := SysGet(62) ; SM_CYMAXIMIZED  - Total height of a maximized window on the primary monitor. Includes any weird offsets.
	
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	; Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	static WM_SYSCOMMAND := 0x112
	static WM_HSCROLL    := 0x114
	
	; Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	static SB_LINELEFT  := 0
	static SB_LINERIGHT := 1
	
	; Windows Screen constants (from MonitorFromWindow: https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	static MONITOR_DEFAULTTONEAREST := 0x00000002
	
}
