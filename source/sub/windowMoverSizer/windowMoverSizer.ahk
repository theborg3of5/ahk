; Based on/inspired by KDE Mover Sizer: http://corz.org/windows/software/accessories/KDE-resizing-moving-for-Windows.php

#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Move and resize windows", "moveSize.ico", "moveSizeRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub)

SetWinDelay, 2 ; This makes WinActivate and such have less of a delay - otherwise alt+drag stuff looks super choppy
CoordMode, Mouse, Screen
global SnappingDistance := 25 ; 25px

; Corners of a window, for resizing purposes
global WINDOWCORNER_TOPLEFT     := "TOP_LEFT"
global WINDOWCORNER_TOPRIGHT    := "TOP_RIGHT"
global WINDOWCORNER_BOTTOMLEFT  := "BOTTOM_LEFT"
global WINDOWCORNER_BOTTOMRIGHT := "BOTTOM_RIGHT"

; Don't do anything while certain windows are active.
#If !Config.windowIsGame() && !Config.isWindowActive("Remote Desktop") && !Config.isWindowActive("VMware Horizon Client")

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
			titleString := WindowLib.getIdTitleStringUnderMouse()
			
			if(WindowLib.isMaximized(titleString))
				WinRestore, % titleString
			else if(!WindowLib.isMinimized(titleString)) ; Window is not maximized or minimized
				WinMaximize, % titleString
		}
	
#If


;---------
; DESCRIPTION:    Set up window for being dragged (for either moving or resizing) and gather
;                 needed information.
; PARAMETERS:
;  window     (O,REQ) - VisualWindow object connected to the window under the mouse.
;  mouseStart (O,REQ) - MousePosition object representing where the mouse is right now (before we
;                       start dragging).
; SIDE EFFECTS:   Restores the window if it's maximized, before we take our initial measurements of
;                 the window.
;---------
dragWindowPrep(ByRef window, ByRef mouseStart) {
	titleString := WindowLib.getIdTitleStringUnderMouse()
	if(WindowLib.isNoMoveSizeWindow(titleString))
		return false
	
	window := new VisualWindow(titleString, SnappingDistance)
	window.snapOn() ; Turn on snapping
	mouseStart := new MousePosition()
	
	return true
}

;---------
; DESCRIPTION:    Do different things depending on what modifier keys are pressed/being held down.
;                 Specifically:
;                    * If left ctrl is pressed, activate the window we're dragging
;                    * While left shift is held down, disable snapping
; PARAMETERS:
;  window (IO,REQ) - VisualWindow object connected to the window that's being moved or resized.
;---------
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

;---------
; DESCRIPTION:    Decide which corner we're resizing towards (that is, which corner moves with the
;                 mouse) based on which quadrant of the window we're in.
; PARAMETERS:
;  window     (I,REQ) - VisualWindow object connected to the window under the mouse.
;  mouseStart (I,REQ) - MousePosition object representing where the mouse started (before we
;                       started dragging).
; RETURNS:        One of the WINDOWCORNER_* constants from this script, representing which corner
;                 should move with the mouse as we resize.
;---------
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
