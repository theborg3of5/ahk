/* Provides a way to interact with windows with AHK at the size/position that they appear to be.
	
	In Windows 10, windows are not always the size that they appear for AHK - there is sometimes a wider, invisible offset around them between, making them look smaller (and further right/down) than they appear. This class provides a way to move and resize a window as if it was the size which it appears, plus a few additional features to save on the math required to say, align a window's right edge to the side of the monitor.
	
	Basic operations
		Moving
			*
		Resizing
			*
		
	Additional features
		Snapping
			*
		
	Example Usage
		*
*/

class VisualWindow {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	leftX   := 0 ; The X coordinate of the visual left edge of the window
	rightX  := 0 ; The X coordinate of the visual right edge of the window
	topY    := 0 ; The Y coordinate of the visual top edge of the window
	bottomY := 0 ; The Y coordinate of the visual bottom edge of the window
	width   := 0 ; The visual width of the window
	height  := 0 ; The visual height of the window
	
	
	;---------
	; DESCRIPTION:    Create a new VisualWindow object to interact with a window as it appears.
	; PARAMETERS:
	;  titleString  (I,OPT) - A title string describing the window this object should
	;                         represent/affect. Defaults to the active window ("A").
	;  snapDistance (I,OPT) - If the window should snap to the edges of the monitor when moved, set
	;                         this to the distance (in pixels) at which the window should snap. If
	;                         this is set to a value > 0, snapping will automatically be turned on.
	;                         Defaults to 0, which leaves snapping off.
	; RETURNS:        Reference to new VisualWindow instance
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	__New(titleString := "A", snapDistance := 0) {
		this.titleString := titleString
		this.snapDistance := snapDistance
		if(snapDistance > 0)
			this.isSnapOn := true
		this.windowOffsets := getWindowOffsets(titleString)
		
		getWindowVisualPosition(x, y, width, height, titleString, this.windowOffsets)
		this.leftX   := x
		this.rightX  := x + width
		this.topY    := y
		this.bottomY := y + height
		this.width   := width
		this.height  := height
	}
	
	move(x := "", y := "") {
		if(x != "")
			this.mvLeftToX(x)
		if(y != "")
			this.mvTopToY(y)
		
		this.applyPosition()
	}
	resize(width := "", height := "") { ; GDB TODO call out that these general functions don't do snapping at all
		if(width != "")
			this.rsToWidth(width)
		if(height != "")
			this.rsToHeight(height)
		
		this.applyPosition()
	}
	moveResize(x := "", y := "", width := "", height := "") {
		if(x != "")
			this.mvLeftToX(x)
		if(y != "")
			this.mvTopToY(y)
		if(width != "")
			this.rsToWidth(width)
		if(height != "")
			this.rsToHeight(height)
		
		this.applyPosition()
	}
	
	
	moveTopLeftToPos(x, y) {
		this.mvLeftToX(x)
		this.mvTopToY(y)
		this.mvSnap()
		this.applyPosition()
	}
	moveBottomLeftToPos(x, y) {
		this.mvLeftToX(x)
		this.mvBottomToY(y)
		this.mvSnap()
		this.applyPosition()
	}
	moveTopRightToPos(x, y) {
		this.mvRightToX(x)
		this.mvTopToY(y)
		this.mvSnap()
		this.applyPosition()
	}
	moveBottomRightToPos(x, y) {
		this.mvRightToX(x)
		this.mvBottomToY(y)
		this.mvSnap()
		this.applyPosition()
	}
	
	
	resizeTopLeftToPos(x, y) {
		this.rsLeftToX(x)
		this.rsTopToY(y)
		this.rsSnap(VisualWindow.RESIZE_X_LEFT, VisualWindow.RESIZE_Y_TOP)
		this.applyPosition()
	}
	resizeTopRightToPos(x, y) {
		this.rsRightToX(x)
		this.rsTopToY(y)
		this.rsSnap(VisualWindow.RESIZE_X_RIGHT, VisualWindow.RESIZE_Y_TOP)
		this.applyPosition()
	}
	resizeBottomLeftToPos(x, y) {
		this.rsLeftToX(x)
		this.rsBottomToY(y)
		this.rsSnap(VisualWindow.RESIZE_X_LEFT, VisualWindow.RESIZE_Y_BOTTOM)
		this.applyPosition()
	}
	resizeBottomRightToPos(x, y) {
		this.rsRightToX(x)
		this.rsBottomToY(y)
		this.rsSnap(VisualWindow.RESIZE_X_RIGHT, VisualWindow.RESIZE_Y_BOTTOM)
		this.applyPosition()
	}
	
	snapOn() {
		this.isSnapOn := true
	}
	snapOff() {
		this.isSnapOn := false
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	titleString  := ""
	snapDistance := 0
	isSnapOn     := false
	
	; Constants for which direction we're resizing in, for snapping purposes
	static RESIZE_Y_TOP    := "TOP"
	static RESIZE_Y_BOTTOM := "BOTTOM"
	static RESIZE_X_LEFT   := "LEFT"
	static RESIZE_X_RIGHT  := "RIGHT"
	
	
	mvLeftToX(x) {
		this.leftX  := x
		this.rightX := x + this.width
	}
	mvRightToX(x) {
		this.leftX  := x - this.width
		this.rightX := x
	}
	mvTopToY(y) {
		this.topY    := y
		this.bottomY := y + this.height
	}
	mvBottomToY(y) {
		this.topY    := y - this.height
		this.bottomY := y
	}
	
	mvSnap() {
		if(!this.isSnapOn)
			return
		
		monitorBounds := getMonitorBounds("", this.titleString)
		leftDistance   := abs(this.leftX   - monitorBounds["LEFT"])
		rightDistance  := abs(this.rightX  - monitorBounds["RIGHT"])
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to left or right edge of screen
		if((leftDistance > 0) && (leftDistance <= this.snapDistance))
			this.mvLeftToX(monitorBounds["LEFT"])
		else if((rightDistance > 0) && (rightDistance <= this.snapDistance))
			this.mvRightToX(monitorBounds["RIGHT"])
		
		; Snap to top or bottom edge of screen
		if((topDistance > 0) && (topDistance <= this.snapDistance))
			this.mvTopToY(monitorBounds["TOP"])
		else if((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
			this.mvBottomToY(monitorBounds["BOTTOM"])
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
	rsTopToY(y) {
		this.topY   := y
		this.height := this.bottomY - y
	}
	rsBottomToY(y) {
		this.bottomY := y
		this.height  := y - this.topY
	}
	rsToHeight(height) {
		this.height  := height
		this.bottomY := this.topY + height
	}
	
	rsSnap(directionX, directionY) {
		if(!this.isSnapOn)
			return
		
		monitorBounds := getMonitorBounds("", this.titleString)
		leftDistance   := abs(this.leftX   - monitorBounds["LEFT"])
		rightDistance  := abs(this.rightX  - monitorBounds["RIGHT"])
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to left edge of screen
		if(directionX = VisualWindow.RESIZE_X_LEFT) {
			if((leftDistance > 0) && (leftDistance <= this.snapDistance))
				this.rsLeftToX(monitorBounds["LEFT"])
		; Snap to right edge of screen
		} else if(directionX = VisualWindow.RESIZE_X_RIGHT) {
			if((rightDistance > 0) && (rightDistance <= this.snapDistance))
				this.rsRightToX(monitorBounds["RIGHT"])
		}
		
		; Snap to top edge of screen
		if(directionY = VisualWindow.RESIZE_Y_TOP) {
			if((topDistance > 0) && (topDistance <= this.snapDistance))
				this.rsTopToY(monitorBounds["TOP"])
		; Snap to bottom edge of screen
		} else if(directionY = VisualWindow.RESIZE_Y_BOTTOM) {
			if((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
				this.rsBottomToY(monitorBounds["BOTTOM"])
		}
	}
	
	applyPosition() {
		moveWindowVisual(this.leftX, this.topY, this.width, this.height, this.titleString, this.windowOffsets)
	}
	
}