/* GDB TODO
	
	Example Usage
		GDB TODO
*/

class MicrosoftLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	; Window styles ( https://www.autohotkey.com/docs/commands/SysGet.htm#Numeric )
	static WS_CAPTION := 0xC00000   ; Window has a caption (top bar + borders).
	static WS_SIZEBOX := 0x40000    ; Window can be sized (aka WS_THICKFRAME).
	static WS_VISIBLE := 0x10000000 ; Window is visible
	
	; Extended window styles
	static WS_EX_TOPMOST      := 0x8   ; Always on top
	static WS_EX_CLICKTHROUGH := 0x20  ; Clicking on the window actually clicks on whatever is below it.
	static WS_EX_CLIENTEDGE   := 0x200 ; Controls: border with sunken edge (on by default for many control types)
	
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
