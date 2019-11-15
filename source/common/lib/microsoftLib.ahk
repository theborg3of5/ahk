; A static library of Microsoft-level constants and system values.

class MicrosoftLib {
	; #PUBLIC#
	
	; [[ Window styles ( https://www.autohotkey.com/docs/commands/SysGet.htm#Numeric ) ]] =--
	;---------
	; DESCRIPTION:    The window has a caption (top bar + borders)
	; NOTES:          WS_CAPTION
	;---------
	static Style_Caption := 0xC00000
	;---------
	; DESCRIPTION:    Window can be sized.
	; NOTES:          WS_SIZEBOX (aka WS_THICKFRAME)
	;---------
	static Style_Sizable := 0x40000
	;---------
	; DESCRIPTION:    Window is visible
	; NOTES:          WS_VISIBLE
	;---------
	static Style_Visible := 0x10000000
	; --=
	
	; [[ Extended window styles ]] =--
	;---------
	; DESCRIPTION:    Always on top
	; NOTES:          WS_EX_TOPMOST
	;---------
	static ExStyle_AlwaysOnTop  := 0x8
	;---------
	; DESCRIPTION:    Clicking on the window actually clicks on whatever is below it.
	; NOTES:          WS_EX_CLICKTHROUGH
	;---------
	static ExStyle_ClickThrough := 0x20
	;---------
	; DESCRIPTION:    Controls: border with sunken edge (on by default for many control types)
	; NOTES:          WS_EX_CLIENTEDGE
	;---------
	static ExStyle_SunkenBorder := 0x200
	; --=
	
	; [[ System-level window measurements ( https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics ) ]] =--
	;---------
	; DESCRIPTION:    For non-3D windows (which should be most), the thickness of the left/right borders.
	; NOTES:          Uses SM_CXBORDER
	;---------
	static BorderX := SysGet(5)
	;---------
	; DESCRIPTION:    For non-3D windows (which should be most), the thickness of the top/bottom borders.
	; NOTES:          Uses SM_CYBORDER
	;---------
	static BorderY := SysGet(6)
	;---------
	; DESCRIPTION:    Thickness of the left/right borders for windows with a caption that are NOT sizable.
	; NOTES:          Uses SM_CXFIXEDFRAME
	;---------
	static FrameX_CaptionNoSizable := SysGet(7)
	;---------
	; DESCRIPTION:    Thickness of the top/bottom borders for windows with a caption that are NOT sizable.
	; NOTES:          Uses SM_CYFIXEDFRAME
	;---------
	static FrameY_CaptionNoSizable := SysGet(8)
	;---------
	; DESCRIPTION:    Thickness of the left/right borders for windows with a caption that are sizable (aka SM_CXFRAME).
	; NOTES:          Uses SM_CXSIZEFRAME
	;---------
	static FrameX_CaptionSizable := SysGet(32)
	;---------
	; DESCRIPTION:    Thickness of the top/bottom borders for windows with a caption that are sizable (aka SM_CYFRAME).
	; NOTES:          Uses SM_CYSIZEFRAME
	;---------
	static FrameY_CaptionSizable := SysGet(33)
	;---------
	; DESCRIPTION:    Total width of a maximized window on the primary monitor. Includes any weird offsets.
	; NOTES:          Uses SM_CXMAXIMIZED
	;---------
	static MaximizedWindowHeight := SysGet(61)
	;---------
	; DESCRIPTION:    Total height of a maximized window on the primary monitor. Includes any weird offsets.
	; NOTES:          Uses SM_CYMAXIMIZED
	;---------
	static MaximizedWindowWidth := SysGet(62)
	; --=
	
	; [[ Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm ) ]] =--
	;---------
	; DESCRIPTION:    Doing something from the "Window" menu, or clicking one of the max/min/restore/close buttons
	; NOTES:          WM_SYSCOMMAND
	;---------
	static Message_WindowMenu := 0x112
	;---------
	; DESCRIPTION:    Scroll event in the window's horizontal scroll bar
	; NOTES:          WM_HSCROLL
	;---------
	static Message_HorizScroll := 0x114
	; --=
	
	; [[ Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars ) ]] =--
	;---------
	; DESCRIPTION:    Scroll 1 unit to the left
	; NOTES:          SB_LINELEFT
	;---------
	static ScrollBar_Left := 0
	;---------
	; DESCRIPTION:    Scroll 1 unit to the right
	; NOTES:          SB_LINERIGHT
	;---------
	static ScrollBar_Right := 1
	; --=
	; #END#
}
