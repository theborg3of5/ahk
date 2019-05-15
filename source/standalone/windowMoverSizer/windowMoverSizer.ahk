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

; Based on/inspired by KDE Mover Sizer: http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)

SetWinDelay, 2 ; This makes WinActivate and such have less of a delay - otherwise alt+drag stuff looks super choppy
CoordMode, Mouse, Screen


; Constants
global SnappingDistance := 10 ; 10px


; Don't do anything while certain windows are active.
#If !MainConfig.windowIsGame() && !MainConfig.isWindowActive("Remote Desktop") && !MainConfig.isWindowActive("VMware Horizon Client")

	; Alt+Left Drag to move
	!LButton::
		moveWindowUnderMouse() {
			titleString := getTitleStringForWindowUnderMouse()
			
			restoreWindowIfMaximized(titleString)
			
			WinGetPos, winStartX, winStartY, winStartWidth, winStartHeight, % titleString
			MouseGetPos(mouseXStart, mouseYStart)
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(titleString)
				
				; Calculate new window position (original position with mouse offset)
				getMouseOffset(mouseXStart, mouseYStart, offsetX, offsetY)
				winNewX := winStartX + offsetX
				winNewY := winStartY + offsetY
				snapMovingWindowToMonitorEdges(titleString, winNewX, winNewY, winStartWidth, winStartHeight)
				
				; Get current monitor dimensions and snap if we're close enough to any monitor edge
				
				; Move window to new position
			}
		}

	; Alt+Right Drag to resize
	!RButton::
		resizeWindowUnderMouse() {
			titleString := getTitleStringForWindowUnderMouse()
			
			restoreWindowIfMaximized(titleString)
			
			; Get initial state: mouse position, window position, window size
			
			; Determine which quadrant of the window we're in, so we can tell which 2 edges are anchored
			
			Loop {
				; Loop exit condition: right-click is released
				if(!GetKeyState("RButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(titleString)
				
				; Get current mouse position, figure out the offset between the original and current mouse positions
				
				; Calculate new window position/size (original position/size with mouse offset)
				; Note: X/Y coordinates also change if top-left corner of window moves (so if we're resizing up or left)
				
				; Get current monitor dimensions and snap if edges are close enough to any monitor edge
				
				; Resize/Move window to new position
			}
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
	
#If


getTitleStringForWindowUnderMouse() {
	MouseGetPos( , , winId)
	return "ahk_id " winId
}


restoreWindowIfMaximized(titleString) {
	minMaxState := WinGet("MinMax", titleString)
	if(minMaxState = WINMINMAX_MAX) ; Window is maximized
		WinRestore, % titleString
}

getMouseOffset(startX, startY, ByRef offsetX, ByRef offsetY) {
	MouseGetPos(newX, newY)
	
	offsetX := startX - newX
	offsetY := startY - newY
}

snapMovingWindowToMonitorEdges(titleString, ByRef x, ByRef y, width, height) {
	offsetsAry := getWindowOffsets(titleString)
	monitorBounds := getMonitorBounds("", titleString)
	
	; GDB TODO should we add a function to window.ahk that gives the monitor bounds relative to a particular window (taking offsets into account)?
	
	
}



#Include <commonHotkeys>