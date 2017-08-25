; So that this doesn't mess with remote desktop.
#If !WinActive("ahk_class TscShellContainerClass") && !WinActive("ahk_class RiotWindowClass")

;	Internationally known as "KDE Mover-Sizer"							Version 1.3
;
;	http://corz.org/windows/software/accessories/KDE-resizing-moving-for-XP-or-Vista.php
;
;	Which is essentially..
;
;	Easy Window Dragging -- KDE style (requires XP/2k/NT) -- by Jonny
;	..with nobs on. See http://www.autohotkey.com and their forum.
;
;	This script makes it much easier to move or resize a window: 1) Hold down
;	the ALT key and LEFT-click anywhere inside a window to drag it to a new
;	location;	2) Hold down ALT and RIGHT-click-drag anywhere inside a window
;	to easily resize it; 3) Press ALT twice, but before releasing it the second
;	time, left-click to minimize the window under the mouse cursor, right-click
;	to maximize it, or middle-click to close it.
;
;	This script was inspired by and built on many like it in the forum. Thanks 
;	go out to ck, thinkstorm, Chris, and aurelian for a job well done.


;	Itstory:
;
;   October 12, 2009:	V3 icon! (the last one produced even more mails!). This one rocks. No complaints please!
;						You can now get straight to the KDE Mover-Sizer page from the About dialog.
;						Removed superfluous default AutoHotKey tray menu items.
;						Added an "Enable HotKeys" tray menu item, which toggles the HotKeys (it un/checks) 
;						Added an Exit menu item and simple exit function.
;						Added a menu option to get to the ini file, to hack at the things there's no menu item for.
;						All current prefs get written to the ini file so the user can see/set what's available.
;						Cleaned up documentation and web page, some. More to come. Maybe even comments!
;						Added about box text, some default prefs, tray, gui + menu fixes, other minor stuff.	~ Cor
;   October 10, 2009:	Added new algorithm for Snapping on Resize (m.ihmig@mytum.de)
;						Added option for Restoring Window on Resize
;   October 4, 2009:	Added full support for multi screens (incl. snapping) (m.ihmig@mytum.de)
;						Fixed Snapping on WorkArea (excluding task bar)
;						Added INI option for Snapping Distance and WinDelay
;						Added About box
;   October 3, 2009:	Added configuration file and option to enable&disable snapping (m.ihmig@mytum.de)
;						Added snapping for (Alt-Left-Click) Moving Windows
;   June 16, 2009:		Added Vista Alt-Tab fix (by jordoex)
;						Added an information tip for the tray hover. Updated Icon (I noticed it 
;						clashed with a portable Linux I recently tried, so I created an original 
;						icon for KDE Mover-Sizer. ~ Cor
;   March    10, 2009:	Moving a maximized windows is now possible (First WinRestore to orig. size, then move)
;						Added: Alt+Middle Button maximizes/restores a window (m.ihmig@mytum.de)
;   December 04, 2007:	Window snap-to-edge - just like KDE, but with extra fun!
;						Added Tray ToolTip help. ~ Cor
;   November 07, 2006:	Optimized resizing code in !RButton, courtesy of bluedawn.
;   February 05, 2006:	Fixed double-alt (the ~Alt hotkey) to work with latest versions of AHK.


;	Snap-To	Edges ..
;
;	If their edge comes within ten pixels of your desktop edge, the window snaps to it. 
;	Very neat;	it's what KDE does. But there's more..
;
;	If you keep mousing after the window snaps, you get a beautiful resizing control which
;	keeps on going. Also you can Alt-right-click any oversized windows and pop them straight back 
;	into the desktop. Note: If you are quick enough, you can break the snap when needed. 
;	Have fun! NOTE: You can now disable the right-click-to-snap behaviour, if preferred.
;
;	;o)
;
;	June 16, 2009:
;
;		Since giving this a page of its own, it's become insanely popular, 
;		and keeps finding its way onto those "five wee apps you can't live
;		without" type lists, which says a lot for the kind of software you
;		can have for yourself if you only rake about in the AutoIt and 
;		AutoHotKey forums once in a while.
;
;
;	NOTE: If your application wants the Alt key for hotkey modifiers, use Alt+Win+Key for that.
;	It's quite easy once you do it a few times, simply roll your thumb and finger on and off.
;
;
return

;
; KDE-Mover-Sizer (created with AutoHotKey: autohotkey.com)		    
; makes it easy to move and resize windows without having 
; to position your mouse cursor accurately; simply hold down
; the Alt key, and click or drag anywhere on the window.
;
; The shortcuts:
;
   ; Alt + Left Button  -> Drag to move a window.
   ; Alt + Right Button -> Drag to resize a window.
   ; Alt + Middle Button -> Maximize/Restore a window.
;
   ; Double-Alt + Left Button   -> Minimize a window.
   ; Double-Alt + Right Button  -> Maximize/Restore a window.  
   ; Double-Alt + Middle Button -> Close a window.
;
     ; The Double-Alt modifier is activated by pressing the
     ; Alt key twice, much like a double-click. Hold the second
     ; Alt-press down until you click the mouse button. Tada!
;
; Known authors (in alphabetical order)..
;
   ; aurelian
   ; Chris
   ; ck
   ; Cor
   ; Jonny
   ; jordoex
   ; Matthias Ihmig
   ; thinkstorm
;
; Do you wish to visit the KDE Mover-Sizer web page?
; )
; IfMsgBox No
    ; return
; else IfMsgBox Yes
	; Run, http://corz.org/windows/software/accessories/KDE-resizing-moving-for-XP-or-Vista.php
	; return
;

; *********** MOVING WINDOW ***********
!LButton::
	; Vista+ Alt-Tab fix by jordoex..
	IfWinActive ahk_class TaskSwitcherWnd
	{
		Send {Blind}{LButton}
		return
	}

	; Get the initial mouse position and window id, and
	; WinRestore if the window is maximized.
	MouseGetPos, KDE_X1, KDE_Y1, KDE_id
	WinGet, KDE_Win, MinMax, ahk_id %KDE_id%
	If KDE_Win
	{
		WinRestore, ahk_id %KDE_id%
		; return    ; restore window size instead of abort
	}

	; Get the initial window position.
	WinGetPos, KDE_WinX1, KDE_WinY1, KDE_WinW, KDE_WinH, ahk_id %KDE_id%
	Loop
	{
		GetKeyState,KDE_Button, LButton, P ; Break if button has been released.
		If KDE_Button = U
			break
		MouseGetPos,Mouse_X2, Mouse_Y2 ; Get the current mouse position.
		KDE_X2 := Mouse_X2
		KDE_Y2 := Mouse_Y2
		KDE_X2 -= KDE_X1    ; Obtain an offset from the initial mouse position.
		KDE_Y2 -= KDE_Y1

		KDE_WinX2 := (KDE_WinX1 + KDE_X2) ; Apply this offset to the window position.
		KDE_WinY2 := (KDE_WinY1 + KDE_Y2)

		; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
		GetCurrentScreenBoarders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom, KDE_id)

		if(SnapOnMoveEnabled) {
			if(KDE_WinX2 < CurrentScreenLeft + SnappingDistance) AND (KDE_WinX2 > CurrentScreenLeft - SnappingDistance)
				KDE_WinX2 := CurrentScreenLeft 

			if(KDE_WinY2 < CurrentScreenTop + SnappingDistance) AND (KDE_WinY2 > CurrentScreenTop - SnappingDistance)
				KDE_WinY2 := CurrentScreenTop

			if(KDE_WinX2 + KDE_WinW > CurrentScreenRight - SnappingDistance) AND (KDE_WinX2 + KDE_WinW < CurrentScreenRight + SnappingDistance)
				KDE_WinX2 := CurrentScreenRight - KDE_WinW

			if(KDE_WinY2 + KDE_WinH > CurrentScreenBottom - SnappingDistance) AND (KDE_WinY2 + KDE_WinH < CurrentScreenBottom + SnappingDistance)
				KDE_WinY2 := CurrentScreenBottom - KDE_WinH
		}

		WinMove, ahk_id %KDE_id%, , %KDE_WinX2%, %KDE_WinY2% ; Move the window to the new position.

		;; BEGIN GAVIN CHANGES
		; Focus findow if CTRL is pressed.
		GetKeyState, ctrlState, LControl
		if ctrlState = D
			WinActivate, ahk_id %KDE_id%
		;; END GAVIN CHANGES
	}
return

; *********** RESIZING WINDOW ***********
!RButton::
	; Get the initial mouse position and window id, and
	; WinRestore if the window is maximized.
	MouseGetPos, KDE_X1, KDE_Y1, KDE_id
	WinGet, KDE_Win, MinMax, ahk_id %KDE_id%
	If KDE_Win
	{
		if DoRestoreOnResize
			WinRestore, ahk_id %KDE_id%
		else
		{
			GetCurrentScreenBoarders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom, KDE_id)
			WinRestore, ahk_id %KDE_id%
			WinMove, ahk_id %KDE_id%, , CurrentScreenLeft                       ; X of resized window
											  , CurrentScreenTop                        ; Y of resized window
											  , CurrentScreenRight  - CurrentScreenLeft ; W of resized window
											  , CurrentScreenBottom - CurrentScreenTop  ; H of resized window
		}
	}

	; Get the initial window position and size.
	WinGetPos, KDE_WinX1, KDE_WinY1, KDE_WinW, KDE_WinH, ahk_id %KDE_id%
	; Define the window region the mouse is currently in.
	; The four regions are Up and Left, Up and Right, Down and Left, Down and Right.
	If (KDE_X1 < KDE_WinX1 + KDE_WinW / 2)
		KDE_WinLeft := 1
	Else
		KDE_WinLeft := -1
	If (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2)
		KDE_WinUp := 1
	Else
		KDE_WinUp := -1
	Loop
	{
		 GetKeyState, KDE_Button, RButton, P ; Break if button has been released.
		 If KDE_Button = U
			  break
		 MouseGetPos, Mouse_X2, Mouse_Y2 ; Get the current mouse position.
		 KDE_X2 := Mouse_X2
		 KDE_Y2 := Mouse_Y2
		 KDE_X2 -= KDE_X1 ; Obtain an offset from the initial mouse position.
		 KDE_Y2 -= KDE_Y1

		 ; snap the window to the edge of the screen if closer than 10 pixels to border
		 ; first, get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
		 ; get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
		 GetCurrentScreenBoarders(CurrentScreenLeft, CurrentScreenRight, CurrentScreenTop, CurrentScreenBottom, KDE_id)

		 if (SnapOnSizeEnabled AND NOT SnapOnResizeMagnetic)    ; "normal" resizing
		 {
			  KDE_WinX2 := (KDE_WinX1 + (KDE_WinLeft + 1) / 2 * KDE_X2) ; X of resized windows
			  KDE_WinY2 := (KDE_WinY1 + (KDE_WinUp   + 1) / 2 * KDE_Y2) ; Y of resized windows
			  KDE_WinW2 := (KDE_WinW  -  KDE_WinLeft          * KDE_X2) ; W of resized windows
			  KDE_WinH2 := (KDE_WinH  -  KDE_WinUp            * KDE_Y2) ; H of resized windows

			  if (KDE_WinX2 < CurrentScreenLeft + SnappingDistance) AND (KDE_WinX2 > CurrentScreenLeft - SnappingDistance) AND (KDE_WinLeft > 0) {
					KDE_WinW2 := KDE_WinW + KDE_WinX1 - CurrentScreenLeft
					KDE_WinX2 := CurrentScreenLeft
			  }
			  if (KDE_WinY2 < CurrentScreenTop + SnappingDistance) AND (KDE_WinY2 > CurrentScreenTop - SnappingDistance) AND (KDE_WinUp > 0) {
					KDE_WinH2 := KDE_WinH + KDE_WinY1 - CurrentScreenTop
					KDE_WinY2 := CurrentScreenTop
			  }
			  if (KDE_WinX2 + KDE_WinW2 > CurrentScreenRight - SnappingDistance) AND (KDE_WinX2 + KDE_WinW2 < CurrentScreenRight + SnappingDistance)  AND (KDE_WinLeft < 0) {
					KDE_WinW2 := - KDE_WinX1 + CurrentScreenRight
			  }
			  if (KDE_WinY2 + KDE_WinH2 > CurrentScreenBottom - SnappingDistance) AND (KDE_WinY2 + KDE_WinH2 < CurrentScreenBottom + SnappingDistance) AND (KDE_WinUp < 0) {
					KDE_WinH2 := - KDE_WinY1 + CurrentScreenBottom
			  }
		 }
		 else if (SnapOnSizeEnabled AND SnapOnResizeMagnetic)    ;  Magnetic Edges resize the window but keep the edge "locked"
		 {
			  ; Get the current window position and size.
			  WinGetPos, KDE_WinX1, KDE_WinY1, KDE_WinW, KDE_WinH, ahk_id %KDE_id%

			  if (KDE_WinX1 < CurrentScreenLeft + SnappingDistance) ;AND (KDE_WinX1 > CurrentScreenLeft - SnappingDistance)
					KDE_WinX1 := CurrentScreenLeft

			  if (KDE_WinY1 < CurrentScreenTop + SnappingDistance) ;AND (KDE_WinY1 > CurrentScreenTop - SnappingDistance)
					KDE_WinY1 := CurrentScreenTop

			  if (KDE_WinX1 + KDE_WinW > CurrentScreenRight - SnappingDistance) ;AND (KDE_WinX1 + KDE_WinW < CurrentScreenRight + SnappingDistance)
					KDE_WinX1 := CurrentScreenRight - KDE_WinW

			  if (KDE_WinY1 + KDE_WinH > CurrentScreenBottom - SnappingDistance) ;AND (KDE_WinY1 + KDE_WinH < CurrentScreenBottom + SnappingDistance)
					KDE_WinY1 := CurrentScreenBottom - KDE_WinH

			  KDE_WinX2 := (KDE_WinX1 + (KDE_WinLeft + 1) / 2 * KDE_X2) ; X of resized windows
			  KDE_WinY2 := (KDE_WinY1 + (KDE_WinUp   + 1) / 2 * KDE_Y2) ; Y of resized windows
			  KDE_WinW2 := (KDE_WinW  -  KDE_WinLeft          * KDE_X2) ; W of resized windows
			  KDE_WinH2 := (KDE_WinH  -  KDE_WinUp            * KDE_Y2) ; H of resized windows
	 
			  KDE_X1 := (KDE_X2 + KDE_X1) ; Reset the initial position for the next iteration.
			  KDE_Y1 := (KDE_Y2 + KDE_Y1)
		 }
		 else    ; no snapping, just resizing
		 {
			  KDE_WinX2 := (KDE_WinX1 + (KDE_WinLeft + 1) / 2 * KDE_X2) ; X of resized windows
			  KDE_WinY2 := (KDE_WinY1 + (KDE_WinUp   + 1) / 2 * KDE_Y2) ; Y of resized windows
			  KDE_WinW2 := (KDE_WinW  -  KDE_WinLeft          * KDE_X2) ; W of resized windows
			  KDE_WinH2 := (KDE_WinH  -  KDE_WinUp            * KDE_Y2) ; H of resized windows
		 }

		 ; Then, act according to the defined region.
		 WinMove, ahk_id %KDE_id%, , KDE_WinX2  ; X of resized window
											, KDE_WinY2  ; Y of resized window
											, KDE_WinW2  ; W of resized window
											, KDE_WinH2  ; H of resized window
	}
return


; Toggle window Maximize/Original size with Alt+Middle mouse button
!MButton::
	MouseGetPos, , , KDE_id
	
	; Toggle between maximized and restored state.
	WinGet, KDE_Win, MinMax, ahk_id %KDE_id%
	if(KDE_Win)
	  WinRestore, ahk_id %KDE_id%
	else
	  WinMaximize, ahk_id %KDE_id%
return


; Function definitions

; Get current screen boarders for monitor where mouse cursor is
GetCurrentScreenBoarders(ByRef CurrentScreenLeft, ByRef CurrentScreenRight, ByRef CurrentScreenTop, ByRef CurrentScreenBottom, winId) {
	offsetsAry := getWindowOffsets("ahk_id " winId)
	; DEBUG.popup("kdeMoverSizer.GetCurrentScreenBoarders", "Got offsets", "Offsets", offsetsAry)
	
	; Get current screen boarders for snapping, do this within the loop to allow snapping an all monitors without releasing button
	MouseGetPos, Mouse_X, Mouse_Y
	SysGet, MonitorCount, MonitorCount
	Loop, %MonitorCount%
	{
		SysGet, MonitorWorkArea, MonitorWorkArea, %A_Index%
		if( (Mouse_X >= MonitorWorkAreaLeft) AND (Mouse_X <= MonitorWorkAreaRight) AND (Mouse_Y >= MonitorWorkAreaTop) AND (Mouse_Y <= MonitorWorkAreaBottom) ) {
			CurrentScreenLeft   := MonitorWorkAreaLeft   - offsetsAry["LEFT"]
			CurrentScreenRight  := MonitorWorkAreaRight  + offsetsAry["RIGHT"]
			CurrentScreenTop    := MonitorWorkAreaTop    - offsetsAry["TOP"]
			CurrentScreenBottom := MonitorWorkAreaBottom + offsetsAry["BOTTOM"]
		}
	}
}

#IfWinNotActive
