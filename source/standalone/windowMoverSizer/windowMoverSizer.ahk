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
global SnappingDistance := 25 ; 25px
global RESIZE_VERT_UP     := "UP"
global RESIZE_VERT_DOWN   := "DOWN"
global RESIZE_HORIZ_LEFT  := "LEFT"
global RESIZE_HORIZ_RIGHT := "RIGHT"


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
			getWindowVisualPosition(startX, startY, startWidth, startHeight, titleString)
			MouseGetPos(mouseStartX, mouseStartY)
			
			; Determine which quadrant of the window we're in, so we can tell which 2 edges are anchored
			getResizeDirections(startX, startY, startWidth, startHeight, mouseStartX, mouseStartY, resizeHorizontal, resizeVertical)
			
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
				if(resizeHorizontal = RESIZE_HORIZ_LEFT) {
					newX     := startX     + distanceX
					newWidth := startWidth - distanceX
				} else {
					newX     := startX
					newWidth := startWidth + distanceX
				}
				if(resizeVertical = RESIZE_VERT_UP) {
					newY      := startY      + distanceY
					newHeight := startHeight - distanceY
				} else {
					newY      := startY
					newHeight := startHeight + distanceY
				}
				
				snapResizingWindowToMonitorEdges(titleString, newX, newY, newWidth, newHeight, resizeHorizontal, resizeVertical)
				
				; Resize window to new (visual) size
				moveWindowVisual(newX, newY, newWidth, newHeight, titleString)
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
	
	x := snapMoveX(x, width,  monitorBounds)
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



getResizeDirections(x, y, width, height, mouseX, mouseY, ByRef resizeHorizontal, ByRef resizeVertical) {
	middleX := x + (width / 2)
	if(mouseX < middleX)
		resizeHorizontal := RESIZE_HORIZ_LEFT
	else
		resizeHorizontal := RESIZE_HORIZ_RIGHT
	
	middleY := y + (height / 2)
	if(mouseY < middleY)
		resizeVertical := RESIZE_VERT_UP
	else
		resizeVertical := RESIZE_VERT_DOWN
}

snapResizingWindowToMonitorEdges(titleString, ByRef x, ByRef y, ByRef width, ByRef height, resizeHorizontal, resizeVertical) {
	monitorBounds := getMonitorBounds("", titleString)
	
	snapResizeX(x, width,  monitorBounds, resizeHorizontal)
	snapResizeY(y, height, monitorBounds, resizeVertical)
}
snapResizeX(ByRef x, ByRef width, monitorBounds, resizeHorizontal) {
	; Snap to left edge of screen
	if(resizeHorizontal = RESIZE_HORIZ_LEFT) {
		distance := x - monitorBounds["LEFT"]
		if(abs(distance) <= SnappingDistance) {
			x := monitorBounds["LEFT"]
			width += distance
		}
	
	; Snap to right edge of screen
	} else if(resizeHorizontal = RESIZE_HORIZ_RIGHT) {
		distance := monitorBounds["RIGHT"] - (x + width)
		if(abs(distance) <= SnappingDistance) {
			; x stays the same
			width += distance
		}
	}
}
snapResizeY(ByRef y, ByRef height, monitorBounds, resizeVertical) {
	; Snap to top edge of screen
	if(resizeVertical = RESIZE_VERT_UP) {
		distance := y - monitorBounds["TOP"]
		if(abs(distance) <= SnappingDistance) {
			y := monitorBounds["TOP"]
			height += distance
		}
	
	; Snap to bottom edge of screen
	} else if(resizeVertical = RESIZE_VERT_DOWN) {
		distance := monitorBounds["BOTTOM"] - (y + height)
		if(abs(distance) <= SnappingDistance) {
			; y stays the same
			height += distance
		}
	}
}



#Include <commonHotkeys>