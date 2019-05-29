; Based on/inspired by KDE Mover Sizer: http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_SubMaster)
setUpTrayIcons("moveSize.ico", "moveSizeRed.ico", "AHK: Move and resize windows")

SetWinDelay, 2 ; This makes WinActivate and such have less of a delay - otherwise alt+drag stuff looks super choppy
CoordMode, Mouse, Screen
global SnappingDistance := 25 ; 25px

; Corners of a window, for resizing purposes
global WINDOWCORNER_TOPLEFT     := "TOP_LEFT"
global WINDOWCORNER_TOPRIGHT    := "TOP_RIGHT"
global WINDOWCORNER_BOTTOMLEFT  := "BOTTOM_LEFT"
global WINDOWCORNER_BOTTOMRIGHT := "BOTTOM_RIGHT"

; Don't do anything while certain windows are active.
#If !MainConfig.windowIsGame() && !MainConfig.isWindowActive("Remote Desktop") && !MainConfig.isWindowActive("VMware Horizon Client")

	; Alt+Left Drag to move
	!LButton::
		moveWindowUnderMouse() {
			if(!dragWindowPrep(window, mouseStart))
				return
			
			startLeftX := window.leftX
			startTopY  := window.topY
			
			Loop {
				; Loop exit condition: left-click is released
				if(!GetKeyState("LButton", "P")) ; P for physical because it's this hotkey
					Break
				
				; Additional modifier keys can disable snapping, focus window, etc.
				handleDragWindowKeys(window)
				
				; Calculate new position and move window
				mouseStart.getDistanceFromCurrentPosition(distanceX, distanceY)
				newX := startLeftX + distanceX
				newY := startTopY  + distanceY
				window.moveTopLeftToPos(newX, newY)
			}
		}

	; Alt+Right Drag to resize
	!RButton::
		resizeWindowUnderMouse() {
			if(!dragWindowPrep(window, mouseStart))
				return
			
			; Determine which directions to resize the window in, based on which quadrant of the window the mouse is over
			; getResizeDirections(window, mouseStart, resizeDirectionX, resizeDirectionY)
			resizeCorner := getResizeCorner(window, mouseStart)
			
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
				
				; Calculate new position/size and move window
				mouseStart.getDistanceFromCurrentPosition(distanceX, distanceY)
				
				if(resizeCorner = WINDOWCORNER_TOPLEFT)
					window.resizeTopLeftToPos(startLeftX + distanceX, startTopY + distanceY)
				else if(resizeCorner = WINDOWCORNER_TOPRIGHT)
					window.resizeTopRightToPos(startRightX + distanceX, startTopY + distanceY)
				else if(resizeCorner = WINDOWCORNER_BOTTOMLEFT)
					window.resizeBottomLeftToPos(startLeftX + distanceX, startBottomY + distanceY)
				else if(resizeCorner = WINDOWCORNER_BOTTOMRIGHT)
					window.resizeBottomRightToPos(startRightX + distanceX, startBottomY + distanceY)
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
	if(isExcludedWindow(titleString))
		return false
	
	restoreWindowIfMaximized(titleString)
	
	window := new VisualWindow(titleString, SnappingDistance)
	window.snapOn() ; Turn on snapping
	mouseStart := new MousePosition()
	
	return true
}

getTitleStringForWindowUnderMouse() {
	MouseGetPos( , , winId)
	return "ahk_id " winId
}

isExcludedWindow(titleString) {
	windowName := MainConfig.findWindowName(titleString)
	if(windowName = "Windows Taskbar")
		return true
	
	return false
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

getResizeCorner(window, mouseStart) {
	x := mouseStart.x
	y := mouseStart.y
	middleX := window.leftX + (window.width  / 2)
	middleY := window.topY  + (window.height / 2)
	
	if(x < middleX && y < middleY)
		return WINDOWCORNER_TOPLEFT
	if(x < middleX && y >= middleY)
		return WINDOWCORNER_BOTTOMLEFT
	if(x >= middleX && y < middleY)
		return WINDOWCORNER_TOPRIGHT
	if(x >= middleX && y >= middleY)
		return WINDOWCORNER_BOTTOMRIGHT
}


#Include <commonHotkeys>