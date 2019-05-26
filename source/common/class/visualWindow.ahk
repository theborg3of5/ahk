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
	
	; Constants for special window positions
	static X_LEFT_EDGE   := "LEFT_EDGE"   ; Against left edge of screen
	static X_RIGHT_EDGE  := "RIGHT_EDGE"  ; Against right edge of screen
	static X_CENTERED    := "CENTERED"    ; Horizontally centered
	static Y_TOP_EDGE    := "TOP_EDGE"    ; Against top edge of screen
	static Y_BOTTOM_EDGE := "BOTTOM_EDGE" ; Against bottom edge of screen
	static Y_CENTERED    := "CENTERED"    ; Vertically centered
	
	
	leftX   := 0 ; The X coordinate of the visual left edge of the window
	rightX  := 0 ; The X coordinate of the visual right edge of the window
	topY    := 0 ; The Y coordinate of the visual top edge of the window
	bottomY := 0 ; The Y coordinate of the visual bottom edge of the window
	width   := 0 ; The visual width of the window
	height  := 0 ; The visual height of the window
	
	
	;---------
	; DESCRIPTION:    Create a new VisualWindow object to interact with a window as it appears.
	; PARAMETERS:
	;  titleString  (I,REQ) - A title string describing the window this object should
	;                         represent/affect.
	;  snapDistance (I,OPT) - If the window should snap to the edges of the monitor when moved, set
	;                         this to the distance (in pixels) at which the window should snap. If
	;                         this is set to a value > 0, snapping will automatically be turned on.
	;                         Defaults to 0, which leaves snapping off.
	; RETURNS:        Reference to new VisualWindow instance
	;---------
	__New(titleString, snapDistance := 0) {
		this.titleString := getIdTitleStringForWindow(titleString) ; Convert title string to ID in case it was active window ("A") or similar
		this.snapDistance := snapDistance
		if(snapDistance > 0)
			this.isSnapOn := true
		this.windowOffsets := this.calculateWindowOffsets()
		
		WinGetPos, x, y, width, height, % this.titleString
		this.convertActualToVisualPosition(x, y, width, height)
		
		; Update various members
		this.leftX   := x
		this.rightX  := x + width
		this.topY    := y
		this.bottomY := y + height
		this.width   := width
		this.height  := height
	}
	
	convertActualToVisualPosition(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "") {
		x      := x      +  this.windowOffsets["LEFT"]
		y      := y      +  this.windowOffsets["TOP"]
		width  := width  - (this.windowOffsets["LEFT"]   + this.windowOffsets["RIGHT"])
		height := height - (this.windowOffsets["BOTTOM"] + this.windowOffsets["TOP"])
	}
	getActualPosition(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "") {
		x      := this.leftX  - this.windowOffsets["LEFT"]
		y      := this.topY   - this.windowOffsets["TOP"]
		width  := this.width  + this.windowOffsets["LEFT"]   + this.windowOffsets["RIGHT"]
		height := this.height + this.windowOffsets["BOTTOM"] + this.windowOffsets["TOP"]
	}
	
	move(x := "", y := "") {
		this.convertSpecialWindowCoordinates(x, y)
		
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
	resizeMove(width := "", height := "", x := "", y := "") {
		; Resizing must happen first so that any special x/y values can be calculated accurately (i.e. center using new width).
		if(width != "")
			this.rsToWidth(width)
		if(height != "")
			this.rsToHeight(height)
		
		this.convertSpecialWindowCoordinates(x, y)
		if(x != "")
			this.mvLeftToX(x)
		if(y != "")
			this.mvTopToY(y)
		
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
	titleString   := ""
	snapDistance  := 0
	isSnapOn      := false
	windowOffsets := ""
	
	; Constants for which direction we're resizing in, for snapping purposes
	static RESIZE_Y_TOP    := "TOP"
	static RESIZE_Y_BOTTOM := "BOTTOM"
	static RESIZE_X_LEFT   := "LEFT"
	static RESIZE_X_RIGHT  := "RIGHT"
	
	
	calculateWindowOffsets() {
		windowOffsets := []
		
		if(MainConfig.findWindowInfo(this.titleString).edgeType = WINDOW_EDGE_STYLE_NoPadding) { ; Specific window has no padding
			offsetWidth  := 0
			offsetHeight := 0
		} else { ; Calculate the default padding based on the window's style
			WinGet, winStyle, Style, A
			
			; Window with no caption style (no titlebar or borders)
			if(!bitFieldHasFlag(winStyle, WS_CAPTION)) {
				offsetWidth  := 0
				offsetHeight := 0
			
			; Windows with a caption that are NOT resizeable
			} else if(!bitFieldHasFlag(winStyle, WS_SIZEBOX)) {
				offsetWidth  := SysGet(SM_CXFIXEDFRAME) - SysGet(SM_CXBORDER)
				offsetHeight := SysGet(SM_CYFIXEDFRAME) - SysGet(SM_CYBORDER)
			
			; Windows that have a caption and are resizeable
			} else {
				offsetWidth  := SysGet(SM_CXSIZEFRAME) - SysGet(SM_CXBORDER)
				offsetHeight := SysGet(SM_CYSIZEFRAME) - SysGet(SM_CYBORDER)
			}
		}
		
		windowOffsets["LEFT"]   := offsetWidth
		windowOffsets["RIGHT"]  := offsetWidth
		windowOffsets["TOP"]    := 0 ; Assuming the taskbar is on top (no offset), otherwise could use something like https://autohotkey.com/board/topic/91513-function-get-the-taskbar-location-win7/ to figure out where it is.
		windowOffsets["BOTTOM"] := offsetHeight
		
		return windowOffsets
	}
	
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
	
	convertSpecialWindowCoordinates(ByRef x, ByRef y) {
		monitorBounds := getMonitorBounds("", this.titleString)
		x := this.convertSpecialWindowX(x, monitorBounds)
		y := this.convertSpecialWindowY(y, monitorBounds)
	}
	convertSpecialWindowX(x, monitorBounds) {
		if(x = VisualWindow.X_LEFT_EDGE)
			return monitorBounds["LEFT"]
		
		monitorWindowDiff := monitorBounds["WIDTH"] - this.width
		if(x = VisualWindow.X_RIGHT_EDGE)
			return monitorBounds["LEFT"] + monitorWindowDiff
		if(x = VisualWindow.X_CENTERED)
			return monitorBounds["LEFT"] + (monitorWindowDiff / 2)
		
		return x ; Just return the original value if it wasn't special
	}
	convertSpecialWindowY(y, monitorBounds) {
		if(y = VisualWindow.Y_TOP_EDGE)
			return monitorBounds["TOP"]
		
		monitorWindowDiff := monitorBounds["HEIGHT"] - this.height
		if(y = VisualWindow.Y_BOTTOM_EDGE)
			return monitorBounds["TOP"] + monitorWindowDiff
		if(y = VisualWindow.Y_CENTERED)
			return monitorBounds["TOP"] + (monitorWindowDiff / 2)
		
		return y ; Just return the original value if it wasn't special
	}
	
	applyPosition() {
		this.getActualPosition(x, y, width, height) ; Add offsets back in
		WinMove, %titleString%, , x, y, width, height
	}
	
}