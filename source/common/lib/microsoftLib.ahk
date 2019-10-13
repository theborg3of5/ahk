/* A static library of Microsoft-level constants and system values.
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
	
	; Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	static Message_WindowMenu  := 0x112 ; WM_SYSCOMMAND - Doing something from the "Window" menu, or clicking one of the max/min/restore/close buttons
	static Message_HorizScroll := 0x114 ; WM_HSCROLL    - Scroll event in the window's horizontal scroll bar
	
	; Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	static ScrollBar_Left  := 0 ; SB_LINELEFT  - Scroll 1 unit to the left
	static ScrollBar_Right := 1 ; SB_LINERIGHT - Scroll 1 unit to the right
}
