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
		Not auto-applying
			*
		
	Example Usage
		*
*/

class VisualWindow {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	leftX        := 0
	rightX       := 0
	topY         := 0
	bottomY      := 0
	width        := 0
	height       := 0
	
	
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
	
	snapOn() {
		this.isSnapOn := true
	}
	snapOff() {
		this.isSnapOn := false
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