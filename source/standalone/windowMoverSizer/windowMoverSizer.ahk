; Based on/inspired by KDE Mover Sizer: http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)
setUpTrayIcons("moveSize.ico", "moveSizeRed.ico", "AHK: Move and resize windows")

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
			getWindowVisualPosition(startX, startY, startWidth, startHeight, titleString)
			MouseGetPos(mouseStartX, mouseStartY)
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(titleString)
				
				; Calculate new window position
				getMouseDistanceMoved(mouseStartX, mouseStartY, distanceX, distanceY)
				x := startX + distanceX
				y := startY + distanceY
				
				; Snap to edges as needed
				if(!GetKeyState("LShift", "P")) ; Suppress snapping with left shift
					snapMovingWindowToMonitorEdges(titleString, x, y, startWidth, startHeight)
				
				; Move window to new (visual) position
				moveWindowVisual(x, y, , , titleString)
			}
		}
		moveWindowUnderMouse2() {
			dragWindowPrep(winStart, mouseStart)
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(winStart.titleString)
				
				; Calculate new window position
				getMouseDistanceMoved2(mouseStart, distanceX, distanceY)
				x := mouseStart.x + distanceX
				y := mouseStart.y + distanceY
				
				; Snap to edges as needed
				if(!GetKeyState("LShift", "P")) ; Suppress snapping with left shift
					snapMovingWindowToMonitorEdges2(winStart, x, y)
				
				; Move window to new (visual) position
				moveWindowVisual(x, y, , , winStart.titleString)
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
			
			; Determine which direction to resize the window in, based on which quadrant of the window we're in
			getResizeDirections(startX, startY, startWidth, startHeight, mouseStartX, mouseStartY, resizeHorizontal, resizeVertical)
			
			Loop {
				; Loop exit condition: right-click is released
				if(!GetKeyState("RButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(titleString)
				
				; Calculate new window position/size
				getMouseDistanceMoved(mouseStartX, mouseStartY, distanceX, distanceY)
				if(resizeHorizontal = RESIZE_HORIZ_LEFT) {
					x     := startX     + distanceX   ; Left edge moves with mouse
					width := startWidth - distanceX   ; Right edge stays still (via width adjustment)
				} else {
					x     := startX                   ; Left edge stays still
					width := startWidth + distanceX   ; Right edge moves with mouse (via width adjustment)
				}
				if(resizeVertical = RESIZE_VERT_UP) {
					y      := startY      + distanceY ; Top edge moves with mouse
					height := startHeight - distanceY ; Bottom edge stays still (via height adjustment)
				} else {
					y      := startY                  ; Top edge stays still
					height := startHeight + distanceY ; Bottom edge moves with mouse (via height adjustment)
				}
				
				; Snap to edges as needed
				if(!GetKeyState("LShift", "P")) ; Suppress snapping with left shift
					snapResizingWindowToMonitorEdges(titleString, x, y, width, height, resizeHorizontal, resizeVertical)
				
				; Resize window to new (visual) size
				moveWindowVisual(x, y, width, height, titleString)
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



dragWindowPrep(ByRef winStart, ByRef mouseStart) {
	
}


getTitleStringForWindowUnderMouse() {
	MouseGetPos( , , winId)
	return "ahk_id " winId
}


restoreWindowIfMaximized(titleString) {
	minMaxState := WinGet("MinMax", titleString)
	if(minMaxState = WINMINMAX_MAX) ; Window is maximized
		WinRestore, % titleString
}

getMouseDistanceMoved(startX, startY, ByRef distanceX, ByRef distanceY) {
	MouseGetPos(x, y)
	
	distanceX := x - startX
	distanceY := y - startY
}
getMouseDistanceMoved2(mouseStart, ByRef distanceX, ByRef distanceY) {
	MouseGetPos(x, y)
	
	distanceX := x - mouseStart.x
	distanceY := y - mouseStart.y
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
; x/y/width/height are visual dimensions, so we don't need to worry about window offsets.
snapMovingWindowToMonitorEdges2(winStart, ByRef x, ByRef y) {
	monitorBounds := getMonitorBounds("", titleString)
	
	x := snapMoveX2(x, width,  monitorBounds)
	y := snapMoveY2(y, height, monitorBounds)
}
snapMoveX2(x, width, monitorBounds) {
	; Snap to left edge of screen
	if(abs(x - monitorBounds["LEFT"]) <= SnappingDistance)
		return monitorBounds["LEFT"]
	
	; Snap to right edge of screen
	if(abs(x + width - monitorBounds["RIGHT"]) <= SnappingDistance)
		return monitorBounds["RIGHT"] - width
	
	return x
}
snapMoveY2(y, height, monitorBounds) {
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