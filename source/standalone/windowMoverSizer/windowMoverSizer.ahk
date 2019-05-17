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
			dragWindowPrep(window, mouseStart)
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P")) ; P for physical because it's this hotkey
					Break
				
				; Additional modifier keys can disable snapping, focus window, etc.
				handleDragWindowKeys(window)
				
				; Move window to new position
				mouseStart.getDistanceFromCurrentPosition(distanceX, distanceY)
				window.moveRelativeToStart(distanceX, distanceY)
			}
		}

	; Alt+Right Drag to resize
	!RButton::
		resizeWindowUnderMouse() {
			dragWindowPrep(window, mouseStart)
			
			; Determine which directions to resize the window in, based on which quadrant of the window the mouse is over
			getResizeDirections(window, mouseStart, resizeDirectionX, resizeDirectionY)
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("RButton", "P")) ; P for physical because it's this hotkey
					Break
				
				; Additional modifier keys can disable snapping, focus window, etc.
				handleDragWindowKeys(window)
				
				; Resize window to new size
				mouseStart.getDistanceFromCurrentPosition(distanceX, distanceY)
				window.resizeRelativeToStart(distanceX, distanceY, resizeDirectionX, resizeDirectionY)
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
	titleString := getTitleStringForWindowUnderMouse()
	
	restoreWindowIfMaximized(titleString)
	
	window := new VisualWindow(titleString)
	mouseStart := new MousePosition()
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

handleDragWindowKeys(window) {
	; If LControl is pressed while we're moving, activate the window
	if(GetKeyState("LControl"))
		WindowActions.activateWindow(window.titleString)
	
	; Holding down left Shift suppresses snapping
	if(GetKeyState("LShift"))
		window.snapDistance := 0
	else
		window.snapDistance := SnappingDistance
}

getResizeDirections(window, mouseStart, ByRef resizeHorizontal, ByRef resizeVertical) {
	middleX := window.leftX + (window.width / 2)
	if(mouseStart.x < middleX)
		resizeHorizontal := RESIZE_HORIZ_LEFT
	else
		resizeHorizontal := RESIZE_HORIZ_RIGHT
	
	middleY := window.topY + (window.height / 2)
	if(mouseStart.y < middleY)
		resizeVertical := RESIZE_VERT_UP
	else
		resizeVertical := RESIZE_VERT_DOWN
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
		this._startTopY    := this._topY
		this._startBottomY := this._bottomY
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
		this.moveWinToLeftX(x)
		this.moveSnapX()
		this.applyPosition()
	}
	moveToRightX(x) {
		this.moveWinToRightX(x)
		this.moveSnapX()
		this.applyPosition()
	}
	moveToTopY(y) {
		this.moveWinToTopY(y)
		this.moveSnapY()
		this.applyPosition()
	}
	moveToBottomY(y) {
		this.moveWinToBottomY(y)
		this.moveSnapY()
		this.applyPosition()
	}
	
	moveRelativeToStart(distanceX := 0, distanceY := 0) {
		this.moveWinToLeftX(this._startLeftX + distanceX)
		this.moveSnapX()
		
		this.moveWinToTopY( this._startTopY  + distanceY)
		this.moveSnapY()
		
		this.applyPosition()
	}
	
	
	
	resizeToWidth(width) {
		this.resizeWinToWidth(width)
		this.applyPosition()
	}
	resizeToHeight(height) {
		this.resizeWinToHeight(height)
		this.applyPosition()
	}
	
	
	resizeLeftToX(x) {
		this.resizeWinLeftToX(x)
		this.resizeSnapX()
		this.applyPosition()
	}
	resizeRightToX(x) {
		this.resizeWinRightToX(x)
		this.resizeSnapX()
		this.applyPosition()
	}
	resizeUpToY(y) {
		this.resizeWinUpToY(y)
		this.resizeSnapY()
		this.applyPosition()
	}
	resizeDownToY(y) {
		this.resizeWinDownToY(y)
		this.resizeSnapY()
		this.applyPosition()
	}
	
	resizeRelativeToStart(distanceX := 0, distanceY := 0, resizeDirectionX := "", resizeDirectionY := "") {
		if(resizeDirectionX = RESIZE_HORIZ_LEFT)
			this.resizeWinLeftToX(this._startLeftX + distanceX)
		else if(resizeDirectionX = RESIZE_HORIZ_RIGHT)
			this.resizeWinRightToX(this._startRightX + distanceX)
		this.resizeSnapX(resizeDirectionX)
		
		if(resizeDirectionY = RESIZE_VERT_UP)
			this.resizeWinUpToY(this._startTopY + distanceY)
		else if(resizeDirectionY = RESIZE_VERT_DOWN)
			this.resizeWinDownToY(this._startBottomY + distanceY)
		this.resizeSnapY(resizeDirectionY)
		
		this.applyPosition()
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
	
	
	
	moveWinToLeftX(x) {
		this._leftX  := x
		this._rightX := x + this._width
	}
	moveWinToRightX(x) {
		this._leftX  := x - this._width
		this._rightX := x
	}
	moveWinToTopY(y) {
		this._topY    := y
		this._bottomY := y + this._height
	}
	moveWinToBottomY(y) {
		this._topY    := y - this._height
		this._bottomY := y
	}
	
	
	
	moveSnapX() {
		if(this._snapDistance <= 0)
			return
		
		monitorBounds := getMonitorBounds("", this._titleString)
		leftDistance  := abs(this._leftX  - monitorBounds["LEFT"])
		rightDistance := abs(this._rightX - monitorBounds["RIGHT"])
		
		; Snap to left or right edge of screen
		if((leftDistance > 0) && (leftDistance <= this._snapDistance))
			this.moveWinToLeftX(monitorBounds["LEFT"])
		else if((rightDistance > 0) && (rightDistance <= this._snapDistance))
			this.moveWinToRightX(monitorBounds["RIGHT"])
	}
	moveSnapY() {
		if(this._snapDistance <= 0)
			return
		
		monitorBounds := getMonitorBounds("", this._titleString)
		topDistance    := abs(this._topY    - monitorBounds["TOP"])
		bottomDistance := abs(this._bottomY - monitorBounds["BOTTOM"])
		
		; Snap to top or bottom edge of screen
		if((topDistance > 0) && (topDistance <= this._snapDistance))
			this.moveWinToTopY(monitorBounds["TOP"])
		else if((bottomDistance > 0) && (bottomDistance <= this._snapDistance))
			this.moveWinToBottomY(monitorBounds["BOTTOM"])
	}
	
	
	
	resizeWinToWidth(width) {
		this._width  := width
		this._rightX := this._leftX + width
	}
	resizeWinToHeight(height) {
		this._height  := height
		this._bottomY := this._topY + height
	}
	
	
	resizeWinLeftToX(x) {
		this._leftX := x
		this._width := this._rightX - x
	}
	resizeWinRightToX(x) {
		this._rightX := x
		this._width  := x - this._leftX
	}
	resizeWinUpToY(y) {
		this._topY   := y
		this._height := this._bottomY - y
	}
	resizeWinDownToY(y) {
		this._bottomY := y
		this._height  := y - this._topY
	}
	
	
	resizeSnapX(resizeDirectionX) {
		if(this._snapDistance <= 0)
			return
		
		monitorBounds := getMonitorBounds("", this._titleString)
		leftDistance  := abs(this._leftX  - monitorBounds["LEFT"])
		rightDistance := abs(this._rightX - monitorBounds["RIGHT"])
		
		; Snap to left edge of screen
		if(resizeDirectionX = RESIZE_HORIZ_LEFT) {
			if((leftDistance > 0) && (leftDistance <= this._snapDistance))
				this.resizeWinLeftToX(monitorBounds["LEFT"])
		
		; Snap to right edge of screen
		} else if(resizeDirectionX = RESIZE_HORIZ_RIGHT) {
			if((rightDistance > 0) && (rightDistance <= this._snapDistance))
				this.resizeWinRightToX(monitorBounds["RIGHT"])
		}
	}
	resizeSnapY(resizeDirectionY) {
		if(this._snapDistance <= 0)
			return
		
		monitorBounds := getMonitorBounds("", this._titleString)
		topDistance    := abs(this._topY    - monitorBounds["TOP"])
		bottomDistance := abs(this._bottomY - monitorBounds["BOTTOM"])
		
		; Snap to top edge of screen
		if(resizeDirectionY = RESIZE_VERT_UP) {
			if((topDistance > 0) && (topDistance <= this._snapDistance))
				this.resizeWinUpToY(monitorBounds["TOP"])
		
		; Snap to bottom edge of screen
		} else if(resizeDirectionY = RESIZE_VERT_DOWN) {
			if((bottomDistance > 0) && (bottomDistance <= this._snapDistance))
				this.resizeWinDownToY(monitorBounds["BOTTOM"])
		}
	}
	
	
	applyPosition() {
		moveWindowVisual(this._leftX, this._topY, this._width, this._height, this._titleString)
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
	
	getDistanceFromCurrentPosition(ByRef distanceX, ByRef distanceY) {
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