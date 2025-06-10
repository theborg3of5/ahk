/* Provides a way to interact with windows with AHK at the size/position that they appear to be.
	
	In Windows 10, windows are not always the size that they appear for AHK - there is sometimes a wider, invisible border offset around them between, making them look smaller (and further right/down) than they appear. This class provides a way to move and resize a window as if it was the size which it appears, plus a few additional features to save on the math required to say, align a window's right edge to the side of the monitor.
	
	Basic operations
		Get actual position
			You can get the actual position of a window after manipulating it with this class using the .calcActualPosition() function.
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
			The "special" positions may also be used relative to a specific window - just pass the titleString for that window to .move().
		
	Example Usage
;		window := new VisualWindow("A") ; Create a new VisualWindow representing the active window ("A")
;		window.move(VisualWindow.X_Centered, VisualWindow.Y_Centered) ; Center window
	
*/

class VisualWindow {
	;region ------------------------------ PUBLIC ------------------------------
	;region Special window position constants
	static X_LeftEdge   := "LEFT_EDGE"   ; Against left edge of screen
	static X_RightEdge  := "RIGHT_EDGE"  ; Against right edge of screen
	static X_Centered   := "CENTERED"    ; Horizontally centered
	static Y_TopEdge    := "TOP_EDGE"    ; Against top edge of screen
	static Y_BottomEdge := "BOTTOM_EDGE" ; Against bottom edge of screen
	static Y_Centered   := "CENTERED"    ; Vertically centered
	;endregion Special window position constants

	;region Special window size constants
	static Size_Maximize := "MAX" ; Maximize the window (using this for either width or height will override the other).
	;endregion Special window size constants
	
	;region Window position properties
	leftX   := 0 ; The X coordinate of the visual left edge of the window
	rightX  := 0 ; The X coordinate of the visual right edge of the window
	topY    := 0 ; The Y coordinate of the visual top edge of the window
	bottomY := 0 ; The Y coordinate of the visual bottom edge of the window
	width   := 0 ; The visual width of the window
	height  := 0 ; The visual height of the window
	;endregion Window position properties
	
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
		this.borderOffsets := this.calculateBorderOffsets()
		
		this.updateToCurrentPosition()
	}
	
	;---------
	; DESCRIPTION:    Get the actual position of the window (not the visual position).
	; PARAMETERS:
	;  x      (O,OPT) - X coordinate of window's top-left corner
	;  y      (O,OPT) - Y coordinate of window's top-left corner
	;  width  (O,OPT) - Width of window
	;  height (O,OPT) - Height of window
	;---------
	calcActualPosition(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "") {
		x      := this.leftX  - this.borderOffsets["LEFT"]
		y      := this.topY   - this.borderOffsets["TOP"]
		width  := this.width  + this.borderOffsets["LEFT"]   + this.borderOffsets["RIGHT"]
		height := this.height + this.borderOffsets["BOTTOM"] + this.borderOffsets["TOP"]
	}
	
	;region General movement/resizing (no snapping)
	;---------
	; DESCRIPTION:    Move the window to the specified coordinates (without snapping).
	; PARAMETERS:
	;  x      (I,OPT) - The x coordinate to move to, or one of the VisualWindow.X_* constants
	;  y      (I,OPT) - The x coordinate to move to, or one of the VisualWindow.Y_* constants
	;  bounds (I,OPT) - If specified, x and y will be treated as relative to these bounds. If not, special values from
	;                   VisualWindow.X_* or .Y_* will be calculated relative to the window's current monitor.
	; NOTES:          Does not support snapping.
	;---------
	move(x := "", y := "", bounds := "") {
		this.prepWindow()
		
		this.convertSpecialWindowPositions(x, y, bounds)
		if (x != "")
			this.mvLeftToX(x)
		if (y != "")
			this.mvTopToY(y)
		
		this.applyPosition()
	}
	;---------
	; DESCRIPTION:    Resize the window to the specified size (without snapping).
	; PARAMETERS:
	;  width  (I,OPT) - The width to resize to
	;  height (I,OPT) - The height to resize to
	;  bounds (I,OPT) - If specified, width and height will be treated as relative to these bounds.
	;                   If not, this will be filled with bounds from the window's current monitor
	;                   and any relative values will be calculated relative to that.
	; NOTES:          Does not support snapping.
	;---------
	resize(width := "", height := "", bounds := "") {
		this.prepWindow()
		
		shouldMax := this.convertSpecialWindowSizes(width, height, bounds)
		if (width != "")
			this.rsToWidth(width)
		if (height != "")
			this.rsToHeight(height)
		
		this.applyPosition(shouldMax)
	}
	;---------
	; DESCRIPTION:    Resize and move the window, all in one operation.
	; PARAMETERS:
	;  width  (I,OPT) - The width to resize to
	;  height (I,OPT) - The height to resize to
	;  x      (I,OPT) - The x coordinate to move to, or one of the VisualWindow.X_* constants
	;  y      (I,OPT) - The x coordinate to move to, or one of the VisualWindow.Y_* constants
	;  bounds (I,OPT) - If specified, width and height will be treated as relative to these bounds.
	;                   If not, this will be filled with bounds from the window's current monitor
	;                   and any relative values will be calculated relative to that.
	; NOTES:          Does not support snapping.
	;---------
	resizeMove(width := "", height := "", x := "", y := "", bounds := "") {
		this.prepWindow()
		
		; Resize should happen first as convertSpecialWindowPositions() uses updated (numeric) size in its calculations.
		shouldMax := this.convertSpecialWindowSizes(width, height, bounds)
		if (width != "")
			this.rsToWidth(width)
		if (height != "")
			this.rsToHeight(height)
		
		this.convertSpecialWindowPositions(x, y, bounds)
		if (x != "")
			this.mvLeftToX(x)
		if (y != "")
			this.mvTopToY(y)
		
		this.applyPosition(shouldMax)
	}
	;endregion General movement/resizing (no snapping)
	
	;region Movement based on corners (supports snapping)
	;---------
	; DESCRIPTION:    Move the top-left corner of the window to the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to move to
	;  y (I,REQ) - The y coordinate to move to
	; NOTES:          Supports snapping
	;---------
	moveTopLeftToPos(x, y) {
		this.prepWindow()
		
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
		this.prepWindow()
		
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
		this.prepWindow()
		
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
		this.prepWindow()
		
		this.mvRightToX(x)
		this.mvBottomToY(y)
		this.mvSnap()
		
		this.applyPosition()
	}
	;endregion Movement based on corners (supports snapping)
	
	;region Resizing based on corners (supports snapping)
	;---------
	; DESCRIPTION:    Resize the window so that the top-left corner is in the given coordinate.
	; PARAMETERS:
	;  x (I,REQ) - The x coordinate to resize to
	;  y (I,REQ) - The y coordinate to resize to
	; NOTES:          Supports snapping
	;---------
	resizeTopLeftToPos(x, y) {
		this.prepWindow()
		
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
		this.prepWindow()
		
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
		this.prepWindow()
		
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
		this.prepWindow()
		
		this.rsRightToX(x)
		this.rsBottomToY(y)
		this.rsSnap(this.Resize_X_ToRight, this.Resize_Y_ToBottom)
		
		this.applyPosition()
	}
	;endregion Resizing based on corners (supports snapping)
	
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
	
	;---------
	; DESCRIPTION:    Get the visual dimensions of the window as a bounds array.
	; RETURNS:        An associative array of bounding info:
	;                   bounds["LEFT"]   - X coordinate of the left edge
	;                   bounds["RIGHT"]  - X coordinate of the right edge
	;                   bounds["TOP"]    - Y coordinate of the top edge
	;                   bounds["BOTTOM"] - Y coordinate of the bottom edge
	;                   bounds["WIDTH"]  - Window width
	;                   bounds["HEIGHT"] - Window height
	; NOTES:          These are the VISUAL dimensions, not the actual (according to Windows) ones.
	;                 See .calcActualPosition() for the actual ones.
	;---------
	getBounds() {
		bounds := {}
		bounds["LEFT"]   := this.leftX
		bounds["RIGHT"]  := this.rightX
		bounds["TOP"]    := this.topY
		bounds["BOTTOM"] := this.bottomY
		bounds["WIDTH"]  := this.width
		bounds["HEIGHT"] := this.height
		
		return bounds
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; Constants for which direction we're resizing in, for snapping purposes
	static Resize_Y_ToTop    := "TOP"
	static Resize_Y_ToBottom := "BOTTOM"
	static Resize_X_ToLeft   := "LEFT"
	static Resize_X_ToRight  := "RIGHT"
	
	titleString   := ""
	snapDistance  := 0
	isSnapOn      := false
	borderOffsets := ""
	
	;---------
	; DESCRIPTION:    Figure out what the offsets of the window should be.
	; RETURNS:        Associative array of offsets with "LEFT"/"RIGHT"/"TOP"/"BOTTOM" subscripts.
	;---------
	calculateBorderOffsets() {
		borderOffsets := {}
		
		if (Config.findWindowInfo(this.titleString).edgeType = WindowInfo.EdgeStyle_NoPadding) { ; Specific window has no padding
			offsetWidth  := 0
			offsetHeight := 0
		} else { ; Calculate the default padding based on the window's style
			; Window with no caption style (no titlebar or borders)
			if (!WindowLib.hasCaption(this.titleString)) {
				offsetWidth  := 0
				offsetHeight := 0
			
			; Windows with a caption that are NOT resizable
			} else if (!WindowLib.isSizable(this.titleString)) {
				offsetWidth  := MicrosoftLib.FrameX_CaptionNoSizable- MicrosoftLib.BorderX
				offsetHeight := MicrosoftLib.FrameY_CaptionNoSizable- MicrosoftLib.BorderY
			
			; Windows that have a caption and are resizable
			} else {
				offsetWidth  := MicrosoftLib.FrameX_CaptionSizable- MicrosoftLib.BorderX
				offsetHeight := MicrosoftLib.FrameY_CaptionSizable- MicrosoftLib.BorderY
			}
		}
	
		borderOffsets["LEFT"]   := offsetWidth
		borderOffsets["RIGHT"]  := offsetWidth
		borderOffsets["TOP"]    := 0 ; Offset never seems to apply to the top for some reason
		borderOffsets["BOTTOM"] := offsetHeight
		
		return borderOffsets
	}
	
	;---------
	; DESCRIPTION:    Update this class' position/size members to match the current (visual) position and size of the window.
	;---------
	updateToCurrentPosition() {
		WinGetPos, x, y, width, height, % this.titleString
		this.convertActualToVisualPosition(x, y, width, height)
		
		; Update various members with result
		this.leftX   := x
		this.rightX  := x + width
		this.topY    := y
		this.bottomY := y + height
		this.width   := width
		this.height  := height
	}
	
	;---------
	; DESCRIPTION:    Turn the given actual position/size into the visual equivalent.
	; PARAMETERS:
	;  x      (IO,OPT) - X coordinate
	;  y      (IO,OPT) - Y coordinate
	;  width  (IO,OPT) - Width of the window
	;  height (IO,OPT) - Height of the window
	;---------
	convertActualToVisualPosition(ByRef x := "", ByRef y := "", ByRef width := "", ByRef height := "") {
		x      := x      +  this.borderOffsets["LEFT"]
		y      := y      +  this.borderOffsets["TOP"]
		width  := width  - (this.borderOffsets["LEFT"]   + this.borderOffsets["RIGHT"])
		height := height - (this.borderOffsets["BOTTOM"] + this.borderOffsets["TOP"])
	}
	
	;---------
	; DESCRIPTION:    Prepare a window to be moved or resized, by restoring it and updating our measurements if needed.
	;---------
	prepWindow() {
		; Restore minimized and maximized windows so we can move/resize them properly.
		if (WindowLib.isMinimized(this.titleString) || WindowLib.isMaximized(this.titleString)) {
			WinRestore, % this.titleString
			this.updateToCurrentPosition()
		}
	}
	
	;---------
	; DESCRIPTION:    Actually move/resize the window to the updated (visual, converted to actual)
	;                 dimensions in this class.
	; PARAMETERS:
	;  doMaximize (I,OPT) - true to maximize the window after we move it.
	;---------
	applyPosition(doMaximize := false) {
		this.calcActualPosition(x, y, width, height) ; Add offsets back in
		WinMove, % this.titleString, , x, y, width, height
		
		if (doMaximize)
			WinMaximize, % this.titleString
	}
	
	
	;region Moving window so specific window edges are somewhere
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
	;endregion Moving window so specific window edges are somewhere
	
	;region Resizing window so specific window edges are somewhere
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
	;endregion Resizing window so specific window edges are somewhere
	
	;region Resizing window to a specific width/height (towards bottom-right corner)
	rsToWidth(width) {
		this.width  := width
		this.rightX := this.leftX + width
	}
	rsToHeight(height) {
		this.height  := height
		this.bottomY := this.topY + height
	}
	;endregion Resizing window to a specific width/height (towards bottom-right corner)
	
	;region Snapping
	mvSnap() {
		if (!this.isSnapOn)
			return
		
		monitorBounds := MonitorLib.getWorkAreaForWindow(this.titleString) ; Should always be the monitor we're currently on, since we're snapping to the edges of that monitor
		leftDistance   := abs(this.leftX   - monitorBounds["LEFT"])
		rightDistance  := abs(this.rightX  - monitorBounds["RIGHT"])
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to left or right edge of screen
		if ((leftDistance > 0) && (leftDistance <= this.snapDistance))
			this.mvLeftToX(monitorBounds["LEFT"])
		else if ((rightDistance > 0) && (rightDistance <= this.snapDistance))
			this.mvRightToX(monitorBounds["RIGHT"])
		
		; Snap to top or bottom edge of screen
		if ((topDistance > 0) && (topDistance <= this.snapDistance))
			this.mvTopToY(monitorBounds["TOP"])
		else if ((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
			this.mvBottomToY(monitorBounds["BOTTOM"])
	}
	rsSnap(directionX, directionY) {
		if (!this.isSnapOn)
			return
		
		monitorBounds := MonitorLib.getWorkAreaForWindow(this.titleString) ; Should always be the monitor we're currently on, since we're snapping to the edges of that monitor
		leftDistance   := abs(this.leftX   - monitorBounds["LEFT"])
		rightDistance  := abs(this.rightX  - monitorBounds["RIGHT"])
		topDistance    := abs(this.topY    - monitorBounds["TOP"])
		bottomDistance := abs(this.bottomY - monitorBounds["BOTTOM"])
		
		; Snap to left edge of screen
		if (directionX = this.Resize_X_ToLeft) {
			if ((leftDistance > 0) && (leftDistance <= this.snapDistance))
				this.rsLeftToX(monitorBounds["LEFT"])
		; Snap to right edge of screen
		} else if (directionX = this.Resize_X_ToRight) {
			if ((rightDistance > 0) && (rightDistance <= this.snapDistance))
				this.rsRightToX(monitorBounds["RIGHT"])
		}
		
		; Snap to top edge of screen
		if (directionY = this.Resize_Y_ToTop) {
			if ((topDistance > 0) && (topDistance <= this.snapDistance))
				this.rsTopToY(monitorBounds["TOP"])
		; Snap to bottom edge of screen
		} else if (directionY = this.Resize_Y_ToBottom) {
			if ((bottomDistance > 0) && (bottomDistance <= this.snapDistance))
				this.rsBottomToY(monitorBounds["BOTTOM"])
		}
	}
	;endregion Snapping
	
	;region Special window sizes/positions (for window placement relative to monitor)
	;---------
	; DESCRIPTION:    Convert the given strings into proper width/height values, supporting various
	;                 special values (VisualWindow.Size_* and percentages).
	; PARAMETERS:
	;  width  (IO,REQ) - Width string. Will be replaced with the new (numeric or blank) width.
	;  height (IO,REQ) - Height string. Will be replaced with the new (numeric or blank) height.
	;  bounds  (I,OPT) - If specified, width and height will be treated as relative to these bounds.
	;                    If not, this will be filled with bounds from the window's current monitor
	;                    and any relative values will be calculated relative to that.
	; RETURNS:        true/false - should we maximize this window?
	;---------
	convertSpecialWindowSizes(ByRef width, ByRef height, bounds := "") {
		; Maximize was already checked before this function and will be applied later, so we can skip the resize.
		if (width = this.Size_Maximize || height = this.Size_Maximize) {
			width := ""
			height := ""
			return true
		}
		
		; Default to the bounds of the monitor that the window is currently on for use with special values below.
		if (!bounds)
			bounds := MonitorLib.getWorkAreaForWindow(this.titleString)
		
		; Handle percentages
		if (width.endsWith("%"))
			width := bounds["WIDTH"] * ( width.removeFromEnd("%") / 100 )
		if (height.endsWith("%"))
			height := bounds["HEIGHT"] * ( height.removeFromEnd("%") / 100 )
		
		return false ; Not maximizing, that was handled at the top.
	}
	
	;---------
	; DESCRIPTION:    Convert the given strings into proper coordinates, supporting various special
	;                 values (VisualWindow.X_*/Y_*) and a +/- offset on the end.
	; PARAMETERS:
	;  x     (IO,REQ) - X string. Will be replaced with the new X coordinate.
	;  y     (IO,REQ) - Y string. Will be replaced with the new Y coordinate.
	;  bounds (I,OPT) - If specified, x and y will be treated as relative to these bounds. If not, special values from
	;                   VisualWindow.X_* or .Y_* will be calculated relative to the window's current monitor.
	; NOTES:          Supported formats (as X examples, Y is the same format but different constants):
	;                   5                                           => 5 (normal coordinate)
	;                   "LEFT_EDGE"    (VisualWindow.X_LeftEdge)    => {left edge of the monitor}
	;                   "RIGHT_EDGE+5" (VisualWindow.X_RightEdge+5) => {x so the right edge of the window is 5px from the right edge of the monitor}
	;---------
	convertSpecialWindowPositions(ByRef x, ByRef y, bounds := "") {
		; If our bounds will take us to another monitor, make sure x and y aren't blank (as that will make us
		; skip moving the window entirely).
		if (!MonitorLib.isWindowOnMonitor(this.titleString, bounds["MONITOR_INDEX"])) {
			if (x = "" && y = "") {
				x := this.X_Centered
				y := this.Y_Centered
			}
		}
		
		x := this.convertSpecialWindowX(x, bounds)
		y := this.convertSpecialWindowY(y, bounds)
	}
	convertSpecialWindowX(x, bounds) {
		; Respect blank values as "don't change this coordinate"
		if (x = "")
			return ""
		
		specialValues := [ this.X_LeftEdge, this.X_RightEdge, this.X_Centered ]
		if (!x.startsWithAnyOf(specialValues, match)) {
			if (bounds)
				x += bounds["LEFT"] ; If we were GIVEN specific bounds, numeric values are relative to them
			return x
		}
		
		; Default to the bounds of the monitor that the window is currently on for use with special values below.
		if (!bounds)
			bounds := MonitorLib.getWorkAreaForWindow(this.titleString)
		
		; Convert the special value.
		monitorWindowDiff := bounds["WIDTH"] - this.width
		Switch match {
			Case this.X_LeftEdge:  newX := bounds["LEFT"]
			Case this.X_RightEdge: newX := bounds["LEFT"] +  monitorWindowDiff
			Case this.X_Centered:  newX := bounds["LEFT"] + (monitorWindowDiff / 2)
		}
		
		; If there's an offset on the end, add that on.
		offset := x.removeFromStart(match).removeFromStart("+") ; Strip off +, but leave - (as a negative sign)
		if (offSet != "")
			newX += offset
		
		; Debug.popup("x",x, "specialValues",specialValues, "bounds",bounds, "match",match, "offset",offset, "newX",newX, "this",this)
		return newX
	}
	convertSpecialWindowY(y, bounds) {
		; Respect blank values as "don't change this coordinate"
		if (y = "")
			return ""
		
		specialValues := [ this.Y_TopEdge, this.Y_BottomEdge, this.Y_Centered]
		if (!y.startsWithAnyOf(specialValues, match)) {
			if (bounds)
				y += bounds["TOP"] ; If we were GIVEN specific bounds, numeric values are relative to them
			return y
		}
		
		; Default to the bounds of the monitor that the window is currently on for use with special values below.
		if (!bounds)
			bounds := MonitorLib.getWorkAreaForWindow(this.titleString)
		
		; Convert the special value.
		monitorWindowDiff := bounds["HEIGHT"] - this.height
		Switch match {
			Case this.Y_TopEdge:    newY := bounds["TOP"]
			Case this.Y_BottomEdge: newY := bounds["TOP"] +  monitorWindowDiff
			Case this.Y_Centered:   newY := bounds["TOP"] + (monitorWindowDiff / 2)
		}
		
		; If there's an offset on the end, add that on.
		offset := y.removeFromStart(match).removeFromStart("+") ; Strip off +, but leave - (as a negative sign)
		if (offSet != "")
			newY += offset
		
		; Debug.popup("y",y, "specialValues",specialValues, "bounds",bounds, "match",match, "offset",offset, "newY",newY, "this",this)
		return newY
	}
	;endregion Special window sizes/positions (for window placement relative to monitor)
	;endregion ------------------------------ PRIVATE ------------------------------
}
