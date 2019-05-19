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
	
	; X and Y coordinates for the mouse at the time this instance was created.
	x := 0
	y := 0
	
	
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
	
}
