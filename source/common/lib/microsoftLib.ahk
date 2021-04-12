; A static library of Microsoft-level constants/system values and helper functions.

class MicrosoftLib {
	; #PUBLIC#
	
	; @GROUP@ Window styles ( https://www.autohotkey.com/docs/commands/SysGet.htm#Numeric )
	static Style_Caption     := 0xC00000   ; The window has a caption - that is, a top bar + borders (WS_CAPTION)
	static Style_CaptionHead := 0x400000   ; Window has a top bar (WS_DLGFRAME). Included in Style_Caption.
	static Style_Sizable     := 0x40000    ; Window can be sized (WS_SIZEBOX/WS_THICKFRAME).
	static Style_Visible     := 0x10000000 ; Window is visible (WS_VISIBLE)
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
	; @GROUP-END@
	
	; @GROUP@ Windows Messages ( https://autohotkey.com/docs/misc/SendMessageList.htm )
	static Message_WindowMenu  := 0x112 ; Doing something from the "Window" menu, or clicking one of the max/min/restore/close buttons (WM_SYSCOMMAND)
	static Message_VertScroll  := 0x115 ; Scroll event in the window's vertical scroll bar (WM_VSCROLL)
	static Message_HorizScroll := 0x114 ; Scroll event in the window's horizontal scroll bar (WM_HSCROLL)
	static Message_AppCommand  := 0x319 ; Send a specific command to an app (WM_APPCOMMAND)
	; @GROUP-END@
	
	; @GROUP@ System Commands ( https://docs.microsoft.com/en-us/windows/win32/menurc/wm-syscommand )
	static SystemCommand_Minimize := 0xF020 ; Minimize the window (SC_MINIMIZE)
	; @GROUP-END@
	
	; @GROUP@ Scroll Bar Requests/Messages ( https://docs.microsoft.com/en-us/windows/desktop/Controls/about-scroll-bars )
	static ScrollBar_Up    := 0 ; Scroll 1 unit to the left (SB_LINEUP)
	static ScrollBar_Down  := 1 ; Scroll 1 unit to the right (SB_LINEDOWN)
	static ScrollBar_Left  := 0 ; Scroll 1 unit to the left (SB_LINELEFT)
	static ScrollBar_Right := 1 ; Scroll 1 unit to the right (SB_LINERIGHT)
	; @GROUP-END@
	
	; @GROUP@ App Commands for use with WM_APPCOMMAND ( https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-appcommand )
	static AppCommand_PlayPause     := 0xE0000 ; Media - play/pause toggle (APPCOMMAND_MEDIA_PLAY_PAUSE)
	static AppCommand_NextTrack     := 0xB0000 ; Media - next track (APPCOMMAND_MEDIA_NEXTTRACK)
	static AppCommand_PreviousTrack := 0xC0000 ; Media - previous track (APPCOMMAND_MEDIA_PREVIOUSTRACK)
	; @GROUP-END@
	
	; @GROUP@ Info options, for use with SystemParametersInfoA (https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfoa )
	static SPI_SETCURSORS := 0x0057 ; Reload system cursors
	; @GROUP-END@
	
	; @GROUP@ Mouse cursor types, for use with LoadCursorA (https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-loadcursora )
	static IDC_ARROW       := 32512 ; Normal Select
	static IDC_IBEAM       := 32513 ; Text Select
	static IDC_WAIT        := 32514 ; Busy
	static IDC_CROSS       := 32515 ; Precision Select
	static IDC_UPARROW     := 32516 ; Alternate Select
	static IDC_SIZE        := 32640 ; Obsolete, use ICD_SIZEALL instead
	static IDC_ICON        := 32641 ; Obsolete
	static IDC_SIZENWSE    := 32642 ; Diagonal Resize 1
	static IDC_SIZENESW    := 32643 ; Diagonal Resize 2
	static IDC_SIZEWE      := 32644 ; Horizontal Resize
	static IDC_SIZENS      := 32645 ; Vertical Resize
	static IDC_SIZEALL     := 32646 ; Move
	static IDC_NO          := 32648 ; Unavailable
	static IDC_HAND        := 32649 ; Link Select
	static IDC_APPSTARTING := 32650 ; Working In Background
	static IDC_HELP        := 32651 ; Help Select
	; @GROUP-END@
	

	;---------
	; DESCRIPTION:    Set all mouse cursors to use the given icon.
	; PARAMETERS:
	;  icon (I,REQ) - Filepath of the icon (.cur file) to use.
	; NOTES:          Logic based on SetSystemCursor() here: https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
	;                 You can restore cursors to their defaults with .restoreAllCursors() .
	;---------
	setAllCursorsToIcon(icon) {
		cursorTypes := [ this.IDC_ARROW,    this.IDC_IBEAM,  this.IDC_WAIT,   this.IDC_CROSS,   this.IDC_UPARROW, this.IDC_SIZE, this.IDC_ICON,        this.IDC_SIZENWSE
		               , this.IDC_SIZENESW, this.IDC_SIZEWE, this.IDC_SIZENS, this.IDC_SIZEALL, this.IDC_NO,      this.IDC_HAND, this.IDC_APPSTARTING, this.IDC_HELP ]
		For _,type in cursorTypes {
			cursorHandle := DllCall("LoadCursorFromFile", "Str",icon) ; We seem to need a new handle for each replacement
			DllCall("SetSystemCursor", "UInt",cursorHandle, "Int",type)
		}
	}
	
	;---------
	; DESCRIPTION:    Restore all mouse cursors to their default values.
	; NOTES:          Based on RestoreCursors() here: https://autohotkey.com/board/topic/32608-changing-the-system-cursor/
	;---------
	restoreAllCursors() {
		DllCall("SystemParametersInfo", "UInt",this.SPI_SETCURSORS, "UInt",0, "UInt",0, "UInt",0 )
	}
	; #END#
}
