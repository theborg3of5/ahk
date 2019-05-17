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
			
			startLeftX := window.leftX
			startTopY  := window.topY
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P")) ; P for physical because it's this hotkey
					Break
				
				; Additional modifier keys can disable snapping, focus window, etc.
				handleDragWindowKeys(window)
				
				; Calculate new position
				mouseStart.getDistanceFromCurrentPosition(distanceX, distanceY)
				window.moveToLeftX(startLeftX + distanceX)
				window.moveToTopY( startTopY  + distanceY)
				
				; Move window to new position
				window.applyWindowPosition()
			}
		}

	; Alt+Right Drag to resize
	!RButton::
		resizeWindowUnderMouse() {
			dragWindowPrep(window, mouseStart)
			
			; Determine which directions to resize the window in, based on which quadrant of the window the mouse is over
			getResizeDirections(window, mouseStart, resizeDirectionX, resizeDirectionY)
			
			startLeftX   := window.leftX
			startRightX  := window.rightX
			startTopY    := window.topY
			startBottomY := window.bottomY
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("RButton", "P")) ; P for physical because it's this hotkey
					Break
				
				; Additional modifier keys can disable snapping, focus window, etc.
				handleDragWindowKeys(window)
				
				; Calculate new position/size
				mouseStart.getDistanceFromCurrentPosition(distanceX, distanceY)
				
				if(resizeDirectionX = RESIZE_HORIZ_LEFT)
					window.resizeLeftToX(startLeftX + distanceX)
				else if(resizeDirectionX = RESIZE_HORIZ_RIGHT)
					window.resizeRightToX(startRightX + distanceX)
				
				if(resizeDirectionY = RESIZE_VERT_UP)
					window.resizeUpToY(startTopY + distanceY)
				else if(resizeDirectionY = RESIZE_VERT_DOWN)
					window.resizeDownToY(startBottomY + distanceY)
				
				; Move window to new position/size
				window.applyWindowPosition()
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
	
	window := new VisualWindow(titleString, 25, false) ; 25px snapping distance, don't auto-apply changes
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
		window.snapOff()
	else
		window.snapOn()
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
	
	
	__New(titleString := "A", snapDistance := 0, autoApply := true) {
		this.titleString := titleString
		this.snapDistance := snapDistance
		if(snapDistance > 0)
			this.isSnapOn := true
		this.autoApply := autoApply
		
		getWindowVisualPosition(x, y, width, height, titleString)
		this.leftX   := x
		this.rightX  := x + width
		this.topY    := y
		this.bottomY := y + height
		this.width   := width
		this.height  := height
	}
	
	snapOn() {
		this.isSnapOn := true
	}
	snapOff() {
		this.isSnapOn := false
	}
	
	moveToLeftX(x) {
		this.mvToLeftX(x)
		this.mvSnapX()
		this.applyPosition()
	}
	moveToRightX(x) {
		this.mvToRightX(x)
		this.mvSnapX()
		this.applyPosition()
	}
	moveToTopY(y) {
		this.mvToTopY(y)
		this.mvSnapY()
		this.applyPosition()
	}
	moveToBottomY(y) {
		this.mvToBottomY(y)
		this.mvSnapY()
		this.applyPosition()
	}
	
	resizeLeftToX(x) {
		this.rsLeftToX(x)
		this.rsSnapX(RESIZE_HORIZ_LEFT)
		this.applyPosition()
	}
	resizeRightToX(x) {
		this.rsRightToX(x)
		this.rsSnapX(RESIZE_HORIZ_RIGHT)
		this.applyPosition()
	}
	resizeToWidth(width) {
		this.rsToWidth(width)
		this.rsSnapX(RESIZE_HORIZ_RIGHT)
		this.applyPosition()
	}
	resizeUpToY(y) {
		this.rsUpToY(y)
		this.rsSnapY(RESIZE_VERT_UP)
		this.applyPosition()
	}
	resizeDownToY(y) {
		this.rsDownToY(y)
		this.rsSnapY(RESIZE_VERT_DOWN)
		this.applyPosition()
	}
	resizeToHeight(height) {
		this.rsToHeight(height)
		this.rsSnapY(RESIZE_VERT_DOWN)
		this.applyPosition()
	}
	
	applyWindowPosition() {
		this.applyPosition(true)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	titleString  := ""
	snapDistance := 0
	isSnapOn     := false
	autoApply    := true
	
	leftX        := 0
	rightX       := 0
	topY         := 0
	bottomY      := 0
	width        := 0
	height       := 0
	
	
	mvToLeftX(x) {
		this.leftX  := x
		this.rightX := x + this.width
	}
	mvToRightX(x) {
		this.leftX  := x - this.width
		this.rightX := x
	}
	mvToTopY(y) {
		this.topY    := y
		this.bottomY := y + this.height
	}
	mvToBottomY(y) {
		this.topY    := y - this.height
		this.bottomY := y
	}
	
	mvSnapX() {
		if(!this.isSnapOn)
			return
		
		monitorBounds := getMonitorBounds("", this.titleString)
		leftDistance  := abs(this.leftX  - monitorBounds["LEFT"])
		rightDistance := abs(this.rightX - monitorBounds["RIGHT"])
		
		; Snap to left or right edge of screen
		if((leftDistance > 0) && (leftDistance <= this.snapDistance))
			this.mvToLeftX(monitorBounds["LEFT"])
		else if((rightDistance > 0) && (rightDistance <= this.snapDistance))
			this.mvToRightX(monitorBounds["RIGHT"])
	}
	mvSnapY() {
		if(!this.isSnapOn)
			return
		
		monitorBounds := getMonitorBounds("", this.titleString)
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to top or bottom edge of screen
		if((topDistance > 0) && (topDistance <= this.snapDistance))
			this.mvToTopY(monitorBounds["TOP"])
		else if((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
			this.mvToBottomY(monitorBounds["BOTTOM"])
	}
	
	rsLeftToX(x) {
		this.leftX := x
		this.width := this.rightX - x
	}
	rsRightToX(x) {
		this.rightX := x
		this.width  := x - this.leftX
	}
	rsToWidth(width) {
		this.width  := width
		this.rightX := this.leftX + width
	}
	rsUpToY(y) {
		this.topY   := y
		this.height := this.bottomY - y
	}
	rsDownToY(y) {
		this.bottomY := y
		this.height  := y - this.topY
	}
	rsToHeight(height) {
		this.height  := height
		this.bottomY := this.topY + height
	}
	
	rsSnapX(resizeDirectionX) {
		if(!this.isSnapOn)
			return
		
		monitorBounds := getMonitorBounds("", this.titleString)
		leftDistance  := abs(this.leftX  - monitorBounds["LEFT"])
		rightDistance := abs(this.rightX - monitorBounds["RIGHT"])
		
		; Snap to left edge of screen
		if(resizeDirectionX = RESIZE_HORIZ_LEFT) {
			if((leftDistance > 0) && (leftDistance <= this.snapDistance))
				this.rsLeftToX(monitorBounds["LEFT"])
		
		; Snap to right edge of screen
		} else if(resizeDirectionX = RESIZE_HORIZ_RIGHT) {
			if((rightDistance > 0) && (rightDistance <= this.snapDistance))
				this.rsRightToX(monitorBounds["RIGHT"])
		}
	}
	rsSnapY(resizeDirectionY) {
		if(!this.isSnapOn)
			return
		
		monitorBounds := getMonitorBounds("", this.titleString)
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to top edge of screen
		if(resizeDirectionY = RESIZE_VERT_UP) {
			if((topDistance > 0) && (topDistance <= this.snapDistance))
				this.rsUpToY(monitorBounds["TOP"])
		
		; Snap to bottom edge of screen
		} else if(resizeDirectionY = RESIZE_VERT_DOWN) {
			if((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
				this.rsDownToY(monitorBounds["BOTTOM"])
		}
	}
	
	applyPosition(forceApply := false) {
		if(!this.autoApply && !forceApply)
			return
		
		moveWindowVisual(this.leftX, this.topY, this.width, this.height, this.titleString)
	}
	
}

class MousePosition {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	
	__New() {
		MouseGetPos(x, y)
		this.x := x
		this.y := y
	}
	
	getDistanceFromCurrentPosition(ByRef distanceX, ByRef distanceY) {
		MouseGetPos(x, y)
		
		distanceX := x - this.x
		distanceY := y - this.y
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	x := 0
	y := 0
	
}




#Include <commonHotkeys>