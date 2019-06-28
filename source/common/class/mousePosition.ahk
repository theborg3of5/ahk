/* Simple class that represents a mouse position and can easily tell you how far the mouse is from that position currently.
	
	Example Usage
		mp := new MousePosition() ; Stores off current mouse position
		originalXPos := mp.x ; Original X coordinate of the mouse
		mp.getDistanceFromCurrentPosition(distanceX, distanceY)
*/

class MousePosition {

; ==============================
; == Public ====================
; ==============================
	x := 0 ; X coordinate for the mouse at the time this instance was created.
	y := 0 ; Y coordinate for the mouse at the time this instance was created.
	
	;---------
	; DESCRIPTION:    Create a new MousePosition object which stores off the current mouse position.
	; RETURNS:        Reference to new MousePosition instance
	;---------
	__New() {
		MouseGetPos(x, y)
		this.x := x
		this.y := y
	}
	
	;---------
	; DESCRIPTION:    Calculates the distance that the mouse has moved, relative to where it was
	;                 when this instance was created.
	; PARAMETERS:
	;  distanceX (O,OPT) - The distance along the X axis (if the mouse moved to the right, this is positive)
	;  distanceY (O,OPT) - The distance along the Y asix (if the mouse moved down, this is positive)
	;---------
	getDistanceFromCurrentPosition(ByRef distanceX, ByRef distanceY) {
		MouseGetPos(x, y)
		
		distanceX := x - this.x
		distanceY := y - this.y
	}
	
}
