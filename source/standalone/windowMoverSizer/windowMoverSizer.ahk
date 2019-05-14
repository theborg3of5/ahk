#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)

; Based on/inspired by KDE Mover Sizer: http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php

/* Do
		Find/add icons (with red variant for suspended, ideally)
		Alt+Left Drag to move windows
			Don't focus
				Focus on Ctrl tap
			Snap to monitor edges
				Disable snapping when Shift modifier held down
		Alt+Right Drag to resize windows
			Resize based on quadrant, leave opposite corner untouched
			Don't focus
				Focus on Ctrl tap
			Snap to monitor edges
				Disable snapping when Shift modifier held down
		Alt+Middle Click to maximize/restore
			Don't focus
				Focus on Ctrl tap
*/


; Constants
global SnappingDistance := 10 ; 10px


; Alt+Left Drag to move
!LButton::
	moveWindowUnderMouse() {
		; Get window under mouse and build its title string.
		titleString := getTitleStringForWindowUnderMouse()
		
		; If window is one we should exclude (according to MainConfig.windowIsGame()) then send blind LButton and return early.
		
		; Save off A_WinDelay and set new value (2?) with SetWinDelay, so that moving window isn't super choppy
		; Save off A_CoordModeMouse and set new value (Screen)
		
		; Restore window if maximized
		
		; Get initial state: mouse position, window position, window size
		
		Loop {
			; Loop exit conditions
			if(!GetKeyState("LButton", "P")) ; Break once left-click is released
				Break
			if(GetKeyState("LControl")) ; If LControl is pressed while we're moving, activate the window
				WindowActions.activateWindow(titleString)
			
			; Get current mouse position, figure out the offset between the original and current mouse positions
			
			; Calculate new window position (original position with mouse offset)
			
			; Get current monitor dimensions and snap if we're close enough to any monitor edge
			
			; Move window to new position
		}
		
		; Restore window delay (SetWinDelay) and mouse coordmode (CoordMode, Mouse)
		; GDB TODO do we really need to restore anything? Could we just set all of this stuff in the auto-execute section, since this is standalone now?
	}

; Alt+Right Drag to resize
!RButton::
	resizeWindowUnderMouse() {
		; Get window under mouse and build its title string.
		titleString := getTitleStringForWindowUnderMouse()
		
		; If window is one we should exclude (according to MainConfig.windowIsGame()) then send blind LButton and return early.
		
		; Save off A_WinDelay and set new value (2?) with SetWinDelay, so that moving window isn't super choppy
		; Save off A_CoordModeMouse and set new value (Screen)
		
		; Restore window if maximized
		
		; Get initial state: mouse position, window position, window size
		
		; Determine which quadrant of the window we're in, so we can tell which 2 edges are anchored
		
		Loop {
			; Loop exit conditions
			if(!GetKeyState("RButton", "P")) ; Break once left-click is released
				Break
			if(GetKeyState("LControl")) ; If LControl is pressed while we're moving, activate the window
				WindowActions.activateWindow(titleString)
			
			; Get current mouse position, figure out the offset between the original and current mouse positions
			
			; Calculate new window position/size (original position/size with mouse offset)
			; Note: X/Y coordinates also change if top-left corner of window moves (so if we're resizing up or left)
			
			; Get current monitor dimensions and snap if edges are close enough to any monitor edge
			
			; Resize/Move window to new position
		}
		
		; Restore window delay (SetWinDelay) and mouse coordmode (CoordMode, Mouse)
	}

; Alt+Middle Click to maximize/restore
!MButton::
	maximizeRestoreWindowUnderMouse() {
		titleString := getTitleStringForWindowUnderMouse()
		
		minMaxState := WinGet("MinMax", titleString)
		if(minMaxState = WINMINMAX_MAX) ; Window is maximized
			WinRestore, % titleString
		else if(minMaxState = WINMINMAX_OTHER) ; Window is restored (not minimized or maximized)
			WinMaximize, % titleString
	}


getTitleStringForWindowUnderMouse() {
	MouseGetPos( , , winId)
	return "ahk_id " winId
}






#Include <commonHotkeys>