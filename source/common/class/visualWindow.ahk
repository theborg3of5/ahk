/* Provides a way to interact with windows with AHK at the size/position that they appear to be. --=
	
	In Windows 10, windows are not always the size that they appear for AHK - there is sometimes a wider, invisible offset around them between, making them look smaller (and further right/down) than they appear. This class provides a way to move and resize a window as if it was the size which it appears, plus a few additional features to save on the math required to say, align a window's right edge to the side of the monitor.
	
	Basic operations
		Get actual position
			You can get the actual position of a window after manipulating it with this class using the .getActualPosition() function.
		Moving
			You can place windows at a particular position, either just based on their top-left corner [.move() and .resizeMove(), support special window positions] or based on any corner [.move*ToPos(), support snapping].
		Resizing
			You can resize windows, either from their top-left corner [.resize() and .resizeMove()] or towards any corner [resize*ToPos(), support snapping].
		
	Additional features
		Snapping
			This class can "snap" window edges to the edges of your monitor once they get within a certain distance, either moving or resizing the window a little extra (whichever you were doing when the snap happened).
			Note that this is only supported when you move or resize based on a particular corner [.move*ToPos() or .resize*ToPos()].
			In order for snapping to work, the snapping distance (the maximum distance between the visual window edge and the monitor edge that we snap at) must be specified with the snapDistance parameter at initialization, and snapping must be explicitly turned on [.snapOn()].
			Snapping can be turned on and off on the fly as well [.snapOn() and .snapOff()].
		Special window positions
			This class can move windows to several "special" positions relative to the window's monitor, aligning the window to the edges/corners/centers of the monitor. The options (for X and Y each) are left/top, middle, and right/bottom (see X_* and Y_* constants below).
			Note that this is only supported when you are NOT moving or resizing based on a particular corner [.move() and .resizeMove()].
		
	Example Usage
;		window := new VisualWindow("A") ; Create a new VisualWindow representing the active window ("A")
;		window.move(VisualWindow.X_Centered, VisualWindow.Y_Centered) ; Center window
	
*/ ; =--

class VisualWindow {
	; #PUBLIC#
	
	; [[ Special window position constants ]] --=
	;---------
	; DESCRIPTION:    Against left edge of screen
	;---------
	static X_LeftEdge   := "LEFT_EDGE"
	;---------
	; DESCRIPTION:    Against right edge of screen
	;---------
	static X_RightEdge  := "RIGHT_EDGE"
	;---------
	; DESCRIPTION:    Horizontally centered
	;---------
	static X_Centered   := "CENTERED"
	;---------
	; DESCRIPTION:    Against top edge of screen
	;---------
	static Y_TopEdge    := "TOP_EDGE"
	;---------
	; DESCRIPTION:    Against bottom edge of screen
	;---------
	static Y_BottomEdge := "BOTTOM_EDGE"
	;---------
	; DESCRIPTION:    Vertically centered
	;---------
	static Y_Centered   := "CENTERED"
	; =--
	
	; [[ Window position properties ]] --=
	;---------
	; DESCRIPTION:    The X coordinate of the visual left edge of the window
	;---------
	leftX   := 0
	;---------
	; DESCRIPTION:    The X coordinate of the visual right edge of the window
	;---------
	rightX  := 0
	;---------
	; DESCRIPTION:    The Y coordinate of the visual top edge of the window
	;---------
	topY    := 0
	;---------
	; DESCRIPTION:    The Y coordinate of the visual bottom edge of the window
	;---------
	bottomY := 0
	;---------
	; DESCRIPTION:    The visual width of the window
	;---------
	width   := 0
	;---------
	; DESCRIPTION:    The visual height of the window
	;---------
	height  := 0
	; =--
	
	;---------
	; DESCRIPTION:    Create a new VisualWindow object to interact with a window as it appears.
	; PARAMETERS:
	;  titleString  (I,REQ) - A title string describing the window this object should represent/affect.
	;  snapDistance (I,OPT) - If the window should snap to the edges of the monitor when moved, set
	;                         this to the distance (in pixels) at which the window should snap. Note
	;                         that snapping must still separately be turned on (with .snapOn() function).
	;                         Defaults to 0.
	; RETURNS:        Reference to new VisualWindow instance
	;---------
	__New(titleString, snapDistance := 0) {
		this.titleString := WindowLib.getIdTitleString(titleString) ; Convert title string to ID in case it was active window ("A") or similar
		this.snapDistance := snapDistance
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
	
	;---------
	; DESCRIPTION:    Get the actual position of the window (not the visual position).
	; PARAMETERS:
	;  x      (O,OPT) - X coordinate of window's top-left corner
	;  y      (O,OPT) - Y coordinate of window's top-left corner
	;  width  (O,OPT) - Width of window
	;  height (O,OPT) - Height of window
	;---------
	getActualPosition(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "") {
		x      := this.leftX  - this.windowOffsets["LEFT"]
		y      := this.topY   - this.windowOffsets["TOP"]
		width  := this.width  + this.windowOffsets["LEFT"]   + this.windowOffsets["RIGHT"]
		height := this.height + this.windowOffsets["BOTTOM"] + this.windowOffsets["TOP"]
	}
	
	; [[ General movement/resizing (no snapping) ]] --=
	;---------
	; DESCRIPTION:    Move the window to the specified coordinates (without snapping).
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to move to, or one of the VisualWindow.X_* constants
	;  y (I,OPT) - The x coordinate to move to, or one of the VisualWindow.Y_* constants
	; NOTES:          Does not support snapping.
	;---------
	move(x := "", y := "") {
		this.convertSpecialWindowCoordinates(x, y)
		
		if(x != "")
			this.mvLeftToX(x)
		if(y != "")
			this.mvTopToY(y)
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Resize the window to the specified size (without snapping).
	; PARAMETERS:
	;  width  (I,OPT) - The width to resize to
	;  height (I,OPT) - The height to resize to
	; NOTES:          Does not support snapping.
	;---------
	resize(width := "", height := "") {
		if(width != "")
			this.rsToWidth(width)
		if(height != "")
			this.rsToHeight(height)
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Resize and move the window, all in one operation.
	; PARAMETERS:
	;  width  (I,OPT) - The width to resize to
	;  height (I,OPT) - The height to resize to
	;  x      (I,OPT) - The x coordinate to move to, or one of the VisualWindow.X_* constants
	;  y      (I,OPT) - The x coordinate to move to, or one of the VisualWindow.Y_* constants
	; RETURNS:        
	; SIDE EFFECTS:   
	; NOTES:          Does not support snapping.
	;---------
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
	
	; [[ Movement based on corners (supports snapping) ]] ---
	;---------
	; DESCRIPTION:    Move the top-left corner of the window to the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to move to
	;  y (I,REQ) - The y coordinate to move to
	; NOTES:          Supports snapping
	;---------
	moveTopLeftToPos(x, y) {
		this.mvLeftToX(x)
		this.mvTopToY(y)
		this.mvSnap()
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Move the top-right corner of the window to the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to move to
	;  y (I,REQ) - The y coordinate to move to
	; NOTES:          Supports snapping
	;---------
	moveTopRightToPos(x, y) {
		this.mvRightToX(x)
		this.mvTopToY(y)
		this.mvSnap()
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Move the bottom-left corner of the window to the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to move to
	;  y (I,REQ) - The y coordinate to move to
	; NOTES:          Supports snapping
	;---------
	moveBottomLeftToPos(x, y) {
		this.mvLeftToX(x)
		this.mvBottomToY(y)
		this.mvSnap()
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Move the bottom-right corner of the window to the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to move to
	;  y (I,REQ) - The y coordinate to move to
	; NOTES:          Supports snapping
	;---------
	moveBottomRightToPos(x, y) {
		this.mvRightToX(x)
		this.mvBottomToY(y)
		this.mvSnap()
		
		this.applyPosition()
	}
	
	; [[ Resizing based on corners (supports snapping) ]] ---
	;---------
	; DESCRIPTION:    Resize the window so that the top-left corner is in the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to resize to
	;  y (I,REQ) - The y coordinate to resize to
	; NOTES:          Supports snapping
	;---------
	resizeTopLeftToPos(x, y) {
		this.rsLeftToX(x)
		this.rsTopToY(y)
		this.rsSnap(this.Resize_X_ToLeft, this.Resize_Y_ToTop)
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Resize the window so that the top-right corner is in the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to resize to
	;  y (I,REQ) - The y coordinate to resize to
	; NOTES:          Supports snapping
	;---------
	resizeTopRightToPos(x, y) {
		this.rsRightToX(x)
		this.rsTopToY(y)
		this.rsSnap(this.Resize_X_ToRight, this.Resize_Y_ToTop)
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Resize the window so that the bottom-left corner is in the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to resize to
	;  y (I,REQ) - The y coordinate to resize to
	; NOTES:          Supports snapping
	;---------
	resizeBottomLeftToPos(x, y) {
		this.rsLeftToX(x)
		this.rsBottomToY(y)
		this.rsSnap(this.Resize_X_ToLeft, this.Resize_Y_ToBottom)
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Resize the window so that the bottom-right corner is in the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to resize to
	;  y (I,REQ) - The y coordinate to resize to
	; NOTES:          Supports snapping
	;---------
	resizeBottomRightToPos(x, y) {
		this.rsRightToX(x)
		this.rsBottomToY(y)
		this.rsSnap(this.Resize_X_ToRight, this.Resize_Y_ToBottom)
		
		this.applyPosition()
	}
	; =--
	
	;---------
	; DESCRIPTION:    Turn on snapping - the window will "snap" to the end of the monitor within a
	;                 certain distance.
	; RETURNS:        this
	;---------
	snapOn() {
		this.isSnapOn := true
		return this
	}
	;---------
	; DESCRIPTION:    Turn off snapping - the window will move exactly where directed, not
	;                 "snapping" to monitor edges.
	; RETURNS:        this
	;---------
	snapOff() {
		this.isSnapOn := false
		return this
	}
	
	
	; #PRIVATE#
	
	; Constants for which direction we're resizing in, for snapping purposes
	static Resize_Y_ToTop    := "TOP"
	static Resize_Y_ToBottom := "BOTTOM"
	static Resize_X_ToLeft   := "LEFT"
	static Resize_X_ToRight  := "RIGHT"
	
	titleString   := ""
	snapDistance  := 0
	isSnapOn      := false
	windowOffsets := ""
	
	;---------
	; DESCRIPTION:    Actually move/resize the window to the updated (visual, converted to actual)
	;                 dimensions in this class.
	;---------
	applyPosition() {
		this.getActualPosition(x, y, width, height) ; Add offsets back in
		WinMove, %titleString%, , x, y, width, height
	}
	
	;---------
	; DESCRIPTION:    Turn the given actual position/size into the visual equivalent.
	; PARAMETERS:
	;  x      (I/O,OPT) - X coordinate
	;  y      (I/O,OPT) - Y coordinate
	;  width  (I/O,OPT) - Width of the window
	;  height (I/O,OPT) - Height of the window
	;---------
	convertActualToVisualPosition(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "") {
		x      := x      +  this.windowOffsets["LEFT"]
		y      := y      +  this.windowOffsets["TOP"]
		width  := width  - (this.windowOffsets["LEFT"]   + this.windowOffsets["RIGHT"])
		height := height - (this.windowOffsets["BOTTOM"] + this.windowOffsets["TOP"])
	}
	
	;---------
	; DESCRIPTION:    Figure out what the offsets of the window should be.
	; RETURNS:        Associative array of offsets with "LEFT"/"RIGHT"/"TOP"/"BOTTOM" subscripts.
	;---------
	calculateWindowOffsets() {
		windowOffsets := {}
		
		if(Config.findWindowInfo(this.titleString).edgeType = WindowInfo.EdgeStyle_NoPadding) { ; Specific window has no padding
			offsetWidth  := 0
			offsetHeight := 0
		} else { ; Calculate the default padding based on the window's style
			; Window with no caption style (no titlebar or borders)
			if(!WindowLib.hasCaption(this.titleString)) {
				offsetWidth  := 0
				offsetHeight := 0
			
			; Windows with a caption that are NOT resizable
			} else if(!WindowLib.isSizable(this.titleString)) {
				offsetWidth  := MicrosoftLib.FrameX_CaptionNoSizable- MicrosoftLib.BorderX
				offsetHeight := MicrosoftLib.FrameY_CaptionNoSizable- MicrosoftLib.BorderY
			
			; Windows that have a caption and are resizable
			} else {
				offsetWidth  := MicrosoftLib.FrameX_CaptionSizable- MicrosoftLib.BorderX
				offsetHeight := MicrosoftLib.FrameY_CaptionSizable- MicrosoftLib.BorderY
			}
		}
	
		windowOffsets["LEFT"]   := offsetWidth
		windowOffsets["RIGHT"]  := offsetWidth
		windowOffsets["TOP"]    := 0 ; Assuming the taskbar is on top (no offset), otherwise could use something like https://autohotkey.com/board/topic/91513-function-get-the-taskbar-location-win7/ to figure out where it is.
		windowOffsets["BOTTOM"] := offsetHeight
		
		return windowOffsets
	}
	
	; [[ Moving window based on certain window edges ]] --=
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
	
	; [[ Resizing window based on certain window edges ]] ---
	rsLeftToX(x) {
		this.leftX := x
		this.width := this.rightX - x
	}
	rsRightToX(x) {
		this.rightX := x
		this.width  := x - this.leftX
	}
	rsTopToY(y) {
		this.topY   := y
		this.height := this.bottomY - y
	}
	rsBottomToY(y) {
		this.bottomY := y
		this.height  := y - this.topY
	}
	
	; [[ Resizing window with a specific width/height (towards bottom-right corner) ]] ---
	rsToWidth(width) {
		this.width  := width
		this.rightX := this.leftX + width
	}
	rsToHeight(height) {
		this.height  := height
		this.bottomY := this.topY + height
	}
	
	; [[ Snapping ]] ---
	mvSnap() {
		if(!this.isSnapOn)
			return
		
		monitorBounds := WindowLib.getMonitorWorkArea(this.titleString)
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
	rsSnap(directionX, directionY) {
		if(!this.isSnapOn)
			return
		
		monitorBounds := WindowLib.getMonitorWorkArea(this.titleString)
		leftDistance   := abs(this.leftX   - monitorBounds["LEFT"])
		rightDistance  := abs(this.rightX  - monitorBounds["RIGHT"])
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to left edge of screen
		if(directionX = this.Resize_X_ToLeft) {
			if((leftDistance > 0) && (leftDistance <= this.snapDistance))
				this.rsLeftToX(monitorBounds["LEFT"])
		; Snap to right edge of screen
		} else if(directionX = this.Resize_X_ToRight) {
			if((rightDistance > 0) && (rightDistance <= this.snapDistance))
				this.rsRightToX(monitorBounds["RIGHT"])
		}
		
		; Snap to top edge of screen
		if(directionY = this.Resize_Y_ToTop) {
			if((topDistance > 0) && (topDistance <= this.snapDistance))
				this.rsTopToY(monitorBounds["TOP"])
		; Snap to bottom edge of screen
		} else if(directionY = this.Resize_Y_ToBottom) {
			if((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
				this.rsBottomToY(monitorBounds["BOTTOM"])
		}
	}
	
	; [[ Special window coordinates (for window placement relative to monitor) ]] ---
	convertSpecialWindowCoordinates(ByRef x, ByRef y) {
		monitorBounds := WindowLib.getMonitorWorkArea(this.titleString)
		x := this.convertSpecialWindowX(x, monitorBounds)
		y := this.convertSpecialWindowY(y, monitorBounds)
	}
	convertSpecialWindowX(x, monitorBounds) {
		if(x = VisualWindow.X_LeftEdge)
			return monitorBounds["LEFT"]
		
		monitorWindowDiff := monitorBounds["WIDTH"] - this.width
		if(x = VisualWindow.X_RightEdge)
			return monitorBounds["LEFT"] + monitorWindowDiff
		if(x = VisualWindow.X_Centered)
			return monitorBounds["LEFT"] + (monitorWindowDiff / 2)
		
		return x ; Just return the original value if it wasn't special
	}
	convertSpecialWindowY(y, monitorBounds) {
		if(y = VisualWindow.Y_TopEdge)
			return monitorBounds["TOP"]
		
		monitorWindowDiff := monitorBounds["HEIGHT"] - this.height
		if(y = VisualWindow.Y_BottomEdge)
			return monitorBounds["TOP"] + monitorWindowDiff
		if(y = VisualWindow.Y_Centered)
			return monitorBounds["TOP"] + (monitorWindowDiff / 2)
		
		return y ; Just return the original value if it wasn't special
	}
	; =--
	; #END#
}
