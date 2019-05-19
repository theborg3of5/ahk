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
				window.moveTopLeftToPos(startLeftX + distanceX, startTopY  + distanceY)
				
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
	
	window := new VisualWindow(titleString, SnappingDistance, false) ; autoApply=false - Don't auto-apply changes
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


#Include <commonHotkeys>