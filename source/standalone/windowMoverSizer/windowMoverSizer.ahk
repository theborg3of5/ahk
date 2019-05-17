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
			dragWindowPrep(window, mouseStart)
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P"))
					Break
				
				; If LControl is pressed while we're moving, activate the window
				if(GetKeyState("LControl"))
					WindowActions.activateWindow(window.titleString)
				
				; Calculate new window position
				mouseStart.getCurrentDistanceFromPosition(distanceX, distanceY)
				window.moveRelativeToStart(distanceX, distanceY)
				; window.moveToLeftX(window.leftX + distanceX)
				; window.moveToTopY( window.topY  + distanceY)
				
				; Snap to edges as needed
				if(!GetKeyState("LShift", "P")) ; Suppress snapping with left shift
					snapMovingWindowToMonitorEdges(winStart, x, y)
				
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



dragWindowPrep(ByRef window, ByRef mouseStart) {
	MouseGetPos( , , winId)
	window := new VisualWindow("ahk_id " winId, 25)
	
	mouseStart := new MousePosition()
	
	; getWindowVisualPosition(startX, startY, startWidth, startHeight, titleString)
	; MouseGetPos(mouseStartX, mouseStartY)
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


class VisualWindow {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	
	__New(titleString := "A", snapDistance := 0) {
		this._titleString := titleString
		this._snapDistance := snapDistance
		
		getWindowVisualPosition(x, y, width, height, titleString)
		this._leftX   := x
		this._rightX  := x + width
		this._topY    := y
		this._bottomY := y + height
		this._width   := width
		this._height  := height
		
		this._startLeftX   := this._leftX
		this._startRightX  := this._rightX
		this._startBottomY := this._bottomY
		this._startTopY    := this._topY
		this._startWidth   := this._width
		this._startHeight  := this._height
	}
	
	titleString[] {
		get {
			return this._titleString
		}
	}
	
	snapDistance[] {
		get {
			return this._snapDistance
		}
		set {
			this._snapDistance := value
		}
	}
	
	leftX[] {
		get {
			return this._leftX
		}
	}
	rightX[] {
		get {
			return this._rightX
		}
	}
	topY[] {
		get {
			return this._topY
		}
	}
	bottomY[] {
		get {
			return this._bottomY
		}
	}
	width[] {
		get {
			return this._width
		}
	}
	height[] {
		get {
			return this._height
		}
	}
	
	startLeftX[] {
		get {
			return this._startLeftX
		}
	}
	startRightX[] {
		get {
			return this._startRightX
		}
	}
	startTopY[] {
		get {
			return this._startTopY
		}
	}
	startBottomY[] {
		get {
			return this._startBottomY
		}
	}
	startWidth[] {
		get {
			return this._startWidth
		}
	}
	startHeight[] {
		get {
			return this._startHeight
		}
	}
	
	
	moveToLeftX(x) {
		this._moveToLeftX(x)
		this.snapMoveX()
	}
	moveToRightX(x) {
		this._moveToRightX(x)
		this.snapMoveX()
	}
	moveToTopY(y) {
		this._moveToTopY(y)
		this.snapMoveY()
	}
	moveToBottomY(y) {
		this._moveToBottomY(y)
		this.snapMoveY()
	}
	
	moveRelativeToStart(distanceX := 0, distanceY := 0) {
		this.moveToLeftX(this._startLeftX + distanceX)
		this.moveToTopY( this._startTopY  + distanceY)
	}
	
	
	resizeToWidth(width) {
		this._width  := width
		this._rightX := this._leftX + width
	}
	resizeToHeight(height) {
		this._height  := height
		this._bottomY := this._topY + height
	}
	
	
	resizeLeftToX(x) {
		this._leftX := x
		this._width := this._rightX - x
	}
	
	resizeRightToX(x) {
		this._rightX := x
		this._width  := x - this._leftX
	}
	
	resizeUpToY(y) {
		this._topY   := y
		this._height := this._bottomY - y
	}
	
	resizeDownToY(y) {
		this._bottomY := y
		this._height  := y - this._topY
	}
	
	applyPosition() { ; GDB TODO should this happen automatically on moving or resizing?
		moveWindowVisual(this._leftX, this._topY, this._width, this._height, this._titleString)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	_titleString  := ""
	_snapDistance := 0
	_leftX        := 0
	_rightX       := 0
	_topY         := 0
	_bottomY      := 0
	_width        := 0
	_height       := 0
	_startLeftX   := 0
	_startRightX  := 0
	_startTopY    := 0
	_startBottomY := 0
	_startWidth   := 0
	_startHeight  := 0
	
	
	
	snapMoveX() {
		if(this._snapDistance <= 0)
			return
		
		monitorBounds := getMonitorBounds("", this._titleString)
		leftDistance  := abs(this._leftX  - monitorBounds["LEFT"])
		rightDistance := abs(this._rightX - monitorBounds["RIGHT"])
		
		; Snap to left or right edge of screen
		if((leftDistance > 0) && (leftDistance <= this._snapDistance))
			this._moveToLeftX(monitorBounds["LEFT"])
		else if((rightDistance > 0) && (rightDistance <= this._snapDistance))
			this._moveToRightX(monitorBounds["RIGHT"])
	}
	
	snapMoveY() {
		if(this._snapDistance <= 0)
			return
		
		monitorBounds := getMonitorBounds("", this._titleString)
		topDistance    := abs(this._topY    - monitorBounds["TOP"])
		bottomDistance := abs(this._bottomY - monitorBounds["BOTTOM"])
		
		; Snap to top or bottom edge of screen
		if((topDistance > 0) && (topDistance <= this._snapDistance))
			this._moveToTopY(monitorBounds["TOP"])
		else if((bottomDistance > 0) && (bottomDistance <= this._snapDistance))
			this._moveToBottomY(monitorBounds["BOTTOM"])
	}
	
	_moveToLeftX(x) {
		this._leftX  := x
		this._rightX := x + width
	}
	_moveToRightX(x) {
		this._leftX  := x - width
		this._rightX := x
	}
	_moveToTopY(y) {
		this._topY    := y
		this._bottomY := y + height
	}
	_moveToBottomY(y) {
		this._topY    := y - height
		this._bottomY := y
	}
	
}

class MousePosition {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	
	__New() {
		MouseGetPos(x, y)
		this._x := x
		this._y := y
	}
	
	x[] {
		get {
			return this._x
		}
		set {
			this._x := value
		}
	}
	
	y[] {
		get {
			return this._y
		}
		set {
			this._y := value
		}
	}
	
	getCurrentDistanceFromPosition(ByRef distanceX, ByRef distanceY) {
		MouseGetPos(x, y)
		
		distanceX := x - this._x
		distanceY := y - this._y
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	_x := 0
	_y := 0
	
}




#Include <commonHotkeys>