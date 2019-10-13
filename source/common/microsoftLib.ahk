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
	
	
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	; SysGet command numbers ( https://autohotkey.com/docs/commands/SysGet.htm )
	static SM_CXBORDER     := 5  ; For non-3D windows (which should be most), the width of the border on the left and right.
	static SM_CYBORDER     := 6  ; For non-3D windows (which should be most), the width of the border on the top and bottom.
	static SM_CXFIXEDFRAME := 7  ; Width of the horizontal frame for a window with a caption that cannot be resized.
	static SM_CYFIXEDFRAME := 8  ; Width of the vertical frame for a window with a caption that cannot be resized.
	static SM_CXSIZEFRAME  := 32 ; Width of the horizontal frame for a window with a caption that cannot be resized (aka SM_CXFRAME).
	static SM_CYSIZEFRAME  := 33 ; Width of the vertical frame for a window with a caption that cannot be resized (aka SM_CYFRAME).
	static SM_CXMAXIMIZED  := 61 ; Width of a maximized window on the primary monitor. Includes any weird offsets.
	static SM_CYMAXIMIZED  := 62 ; Height of a maximized window on the primary monitor. Includes any weird offsets.
	
	; Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	static WM_SYSCOMMAND := 0x112
	static WM_HSCROLL    := 0x114
	
	; Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	static SB_LINELEFT  := 0
	static SB_LINERIGHT := 1
	
	; Windows Screen constants (from MonitorFromWindow: https://docs.microsoft.com/en-us/windows/desktop/api/winuser/nf-winuser-monitorfromwindow )
	static MONITOR_DEFAULTTONEAREST := 0x00000002
	
}
