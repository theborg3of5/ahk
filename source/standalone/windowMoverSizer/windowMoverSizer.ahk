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
			
			; Get initial state - (visual) window position/size and mouse position
			getWindowVisualPosition(startX, startY, width, height, titleString)
			MouseGetPos(mouseStartX, mouseStartY)
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(titleString)
				
				; Calculate new window position (original position + mouse distance from start) and
				; snap to edges as needed
				getTotalMouseDistance(mouseStartX, mouseStartY, distanceX, distanceY)
				newX := startX + distanceX
				newY := startY + distanceY
				snapMovingWindowToMonitorEdges(titleString, newX, newY, width, height)
				
				; Move window to new (visual) position
				moveWindowVisual(newX, newY, , , titleString)
			}
		}

	; Alt+Right Drag to resize
	!RButton::
		resizeWindowUnderMouse() {
			titleString := getTitleStringForWindowUnderMouse()
			restoreWindowIfMaximized(titleString)
			
			; Get initial state - (visual) window position/size and mouse position
			getWindowVisualPosition(x, y, startWidth, startHeight, titleString)
			MouseGetPos(mouseStartX, mouseStartY)
			
			; Determine which quadrant of the window we're in, so we can tell which 2 edges are anchored
			; GDB TODO
			
			Loop {
				; Loop exit condition: right-click is released
				if(!GetKeyState("RButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(titleString)
				
				
				; Calculate new window size (original size + mouse distance from start) and
				; snap to edges as needed
				getTotalMouseDistance(mouseStartX, mouseStartY, distanceX, distanceY)
				newWidth  := startWidth  + distanceX
				newHeight := startHeight + distanceY
				snapResizingWindowToMonitorEdges(titleString, x, y, newWidth, newHeight)
				
				; Resize window to new (visual) size
				moveWindowVisual(, , newWidth, newHeight, titleString)
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

getTotalMouseDistance(startX, startY, ByRef distanceX, ByRef distanceY) {
	MouseGetPos(newX, newY)
	
	distanceX := newX - startX
	distanceY := newY - startY
}

; x/y/width/height are visual dimensions, so we don't need to worry about window offsets.
snapMovingWindowToMonitorEdges(titleString, ByRef x, ByRef y, width, height) {
	monitorBounds := getMonitorBounds("", titleString)
	
	x := snapMoveX(x, width, monitorBounds)
	y := snapMoveY(y, height, monitorBounds)
}
snapMoveX(x, width, monitorBounds) {
	; Snap to left edge of screen
	if(abs(x - monitorBounds["LEFT"]) <= SnappingDistance)
		return monitorBounds["LEFT"]
	
	; Snap to right edge of screen
	if(abs(x + width - monitorBounds["RIGHT"]) <= SnappingDistance)
		return monitorBounds["RIGHT"] - width
	
	return x
}
snapMoveY(y, height, monitorBounds) {
	; Snap to top edge of screen
	if(abs(y - monitorBounds["TOP"]) <= SnappingDistance)
		return monitorBounds["TOP"]
	
	; Snap to bottom edge of screen
	if(abs(y + height - monitorBounds["BOTTOM"]) <= SnappingDistance)
		return monitorBounds["BOTTOM"] - height
	
	return y
}

snapResizingWindowToMonitorEdges(titleString, x, y, ByRef width, ByRef height) {
	
}



#Include <commonHotkeys>