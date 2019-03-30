/* Class that shows something like a toast notification.
	
	Usage:
		Create Toast instance
		Show it (.showForSeconds or .show)
		If not showing on a timer, close it when finished (.close)
	
	Example:
		; Show a toast on a 5-second timer
		t := new Toast("5-second timer toast!")
		t.showForSeconds(5)
		; (OR)
		Toast.showMedium("5-second timer toast!")
		
		; Show a toast, then hide it after finishing a longer-running action
		t := new Toast("Running long action")
		t.showPersistent()
		... ; Long action happens
		t.setText("Next step")
		... ; Next step happens
		t.hide() ; Toast is hidden but still exists
		...
		t.showPersistent() ; Toast becomes visible again
		...
		t.close() ; Toast is destroyed
*/

class Toast {
	
	; ==============================
	; == Public (Static) ===========
	; ==============================
	
	static X_ALIGN_LEFT   :=  0 ; Left-aligned (against left edge of screen)
	static X_ALIGN_RIGHT  := -1 ; Right-aligned (against right edge of screen)
	static X_ALIGN_CENTER := -2 ; Horizontally centered
	static Y_ALIGN_TOP    :=  0 ; Top-aligned (against top edge of screen)
	static Y_ALIGN_BOTTOM := -1 ; Bottom-aligned (against bottom edge of screen)
	static Y_ALIGN_CENTER := -2 ; Vertically centered
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "short" toast (shown for 1 second) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showShort(toastText) {
		Toast.showForSeconds(toastText, 1, Toast.X_ALIGN_RIGHT, Toast.Y_ALIGN_BOTTOM)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "medium" toast (shown for 2 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showMedium(toastText) {
		Toast.showForSeconds(toastText, 2, Toast.X_ALIGN_RIGHT, Toast.Y_ALIGN_BOTTOM)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "long" toast (shown for 5 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showLong(toastText) {
		Toast.showForSeconds(toastText, 5, Toast.X_ALIGN_RIGHT, Toast.Y_ALIGN_BOTTOM)
	}
	
	;---------
	; DESCRIPTION:    Static caller to show this toast for a certain number of seconds, then destroy it.
	; PARAMETERS:
	;  toastText  (I,REQ) - The text to show in the toast.
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at. Defaults to right edge of screen.
	;                       Special values are available in Toast.X_ALIGN_*.
	;  y          (I,OPT) - The y coordinate to show the toast at. Defaults to bottom edge of screen.
	;                       Special values are available in Toast.Y_ALIGN_*.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showForSeconds(toastText, numSeconds, x := -1, y := -1) { ; x := Toast.X_ALIGN_RIGHT, y := Toast.Y_ALIGN_BOTTOM
		idAry := this.buildGui()
		guiId        := idAry["GUI_ID"]
		labelVarName := idAry["LABEL_VAR_NAME"]
		
		this.setLabelText(toastText, labelVarName)
		this.showToast(x, y, guiId)
		
		closeFunc := ObjBindMethod(Toast, "closeToast", guiId) ; Create a BoundFunc object of the .closeToast function (with guiId passed to it) for when the timer finishes.
		SetTimer, % closeFunc, % -numSeconds * 1000
	}
	
	; ==============================
	; == Public (Persistent) =======
	; ==============================
	
	;---------
	; DESCRIPTION:    Create a new Toast object.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; RETURNS:        A new instance of this class.
	;---------
	__New(toastText := "") {
		idAry := this.buildGui()
		this.guiId        := idAry["GUI_ID"]
		this.labelVarName := idAry["LABEL_VAR_NAME"]
		
		if(toastText)
			this.setLabelText(toastText, this.labelVarName)
	}
	
	;---------
	; DESCRIPTION:    Change the text for the toast, without hiding it.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; NOTES:          Will try to maintain the same position, but toast size will expand to fit text.
	;---------
	setText(toastText) {
		Gui, % this.guiId ":Default"
		this.setLabelText(toastText, this.labelVarName)
		this.move(this.x, this.y)
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is hidden or closed.
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at. Defaults to right edge of screen.
	;              Special values are available in Toast.X_ALIGN_*.
	;  y (I,OPT) - The y coordinate to show the toast at. Defaults to bottom edge of screen.
	;              Special values are available in Toast.Y_ALIGN_*.
	;---------
	showPersistent(x := -1, y := -1) { ; x := Toast.X_ALIGN_RIGHT, y := Toast.Y_ALIGN_BOTTOM
		Gui, % this.guiId ":Default"
		this.x := x
		this.y := y
		this.showToast(x, y, this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Show this toast for a certain number of seconds, then hide it.
	; PARAMETERS:
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at. Defaults to right edge of screen.
	;                       Special values are available in Toast.X_ALIGN_*.
	;  y          (I,OPT) - The y coordinate to show the toast at. Defaults to bottom edge of screen.
	;                       Special values are available in Toast.Y_ALIGN_*.
	;---------
	showPersistentForSeconds(numSeconds, x := -1, y := -1) { ; x := Toast.X_ALIGN_RIGHT, y := Toast.Y_ALIGN_BOTTOM
		this.x := x
		this.y := y
		
		this.showToast(x, y, this.guiId)
		
		hideFunc := ObjBindMethod(Toast, "hideToast", this.guiId) ; Create a BoundFunc object of the .closeToast function (with guiId passed to it) for when the timer finishes.
		SetTimer, % hideFunc, % -numSeconds * 1000
	}
	
	;---------
	; DESCRIPTION:    Fade the toast out, but don't destroy it (use .close() instead if you're
	;                 finished with the toast).
	;---------
	hide() {
		Gui, % this.guiId ":Default"
		this.hideToast(this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close() {
		Gui, % this.guiId ":Default"
		this.closeToast(this.guiId)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static backgroundColor := "2A211C"
	static fontColor       := "BDAE9D"
	static fontSize        := 20
	static fontName        := "Consolas"
	static marginX         := 5
	static marginY         := 0
	static maxOpacity      := 255
	
	static widthLabelNum := 0
	
	guiId        := ""
	labelVarName := ""
	x            := ""
	y            := ""
	
	
	;---------
	; DESCRIPTION:    Build the toast gui, applying various properties.
	; SIDE EFFECTS:   Saves off a reference to the gui's window handle.
	; RETURNS:        Array of ID information, format:
	;                 	idAry["GUI_ID"]         = Window handle/guiId
	;                 	     ["LABEL_VAR_NAME"] = Name of the global variable connected to the label
	;                 	                          containing the toast text.
	;---------
	buildGui() {
		; Create Gui and save off window handle (which is also guiId)
		Gui, New, +HWNDguiId
		
		; Other gui options
		Gui, +AlwaysOnTop -Caption +LastFound +Toolwindow
		Gui, % "+E" WS_EX_CLICKTHROUGH
		
		; Set formatting options
		Gui, Color, % Toast.backgroundColor
		Gui, Font, % "c" Toast.fontColor " s" Toast.fontSize, % Toast.fontName
		Gui, Margin, % Toast.marginX, % Toast.marginY
		
		; Add label
		labelVarName := guiId "Text" ; Come up with a unique variable we can use to reference the label (to change its contents if needed).
		setDynamicGlobalVar(labelVarName) ; Since the variable must be global, declare it as such.
		Gui, Add, Text, % "v" labelVarName
		
		return {"GUI_ID":guiId, "LABEL_VAR_NAME":labelVarName}
	}
	
	;---------
	; DESCRIPTION:    Move the toast gui to the given coordinates and resize it to its contents.
	; PARAMETERS:
	;  x         (I,OPT) - The x coordinate to show the toast at.
	;                      Special values are available in Toast.X_ALIGN_*.
	;  y         (I,OPT) - The y coordinate to show the toast at.
	;                      Special values are available in Toast.Y_ALIGN_*.
	;  showProps (I,OPT) - Any additional properties should be included in Gui, Show calls. For
	;                      example, passing "Hide" would keep the gui hidden while we resize and
	;                      move it.
	;---------
	move(x, y, showProps = "") {
		; DEBUG.popup("move", "", "x",x, "y",y, "showProps",showProps)
		
		; If x/y not given, default them to right/bottom
		x := ifBlankDefaultTo(x, Toast.X_ALIGN_RIGHT)
		y := ifBlankDefaultTo(y, Toast.Y_ALIGN_BOTTOM)
		
		; Resize to size of contents
		Gui, Show, AutoSize NoActivate %showProps%
		Gui, +LastFound ; Needed for WinGetPos
		WinGetPos, , , guiWidth, guiHeight
		
		; DEBUG.popup("move",3, "x",x, "y",y, "guiWidth",guiWidth, "guiHeight",guiHeight)
		
		if(x = Toast.X_ALIGN_RIGHT)
			x := A_ScreenWidth  - guiWidth
		if(y = Toast.Y_ALIGN_BOTTOM)
			y := A_ScreenHeight - guiHeight
		
		if(x = Toast.X_ALIGN_CENTER)
			x := (A_ScreenWidth  - guiWidth) / 2
		if(y = Toast.Y_ALIGN_CENTER)
			y := (A_ScreenHeight - guiHeight) / 2
		
		Gui, Show, % "x" x " y" y " NoActivate " showProps
	}
	
	;---------
	; DESCRIPTION:    Set the text of the toast label and resize it fit that text.
	; PARAMETERS:
	;  toastText    (I,REQ) - The text to show in the toast.
	;  labelVarName (I,REQ) - The name of the global variable connected to the toast label.
	;---------
	setLabelText(toastText, labelVarName) {
		; Figure out how wide the text control needs to be to fit its contents
		Toast.widthLabelNum++
		getLabelSizeForText(toastText, "WidthLabel" Toast.widthLabelNum, textWidth, textHeight)
		
		; Update the text and width
		GuiControl,     , % labelVarName, % toastText
		GuiControl, Move, % labelVarName, % "w" textWidth " h" textHeight
	}
	
	;---------
	; DESCRIPTION:    Show (fade in) the toast.
	; PARAMETERS:
	;  x     (I,OPT) - The x coordinate to show the toast at.
	;                  Special values are available in Toast.X_ALIGN_*.
	;  y     (I,OPT) - The y coordinate to show the toast at.
	;                  Special values are available in Toast.Y_ALIGN_*.
	;  guiId (I,REQ) - Window handle for the toast gui.
	;---------
	showToast(x, y, guiId) {
		this.move(x, y, "Hide") ; Don't show the gui until we transition it in below
		fadeGuiIn(guiId, "NoActivate", Toast.maxOpacity) ; Also actually shows the gui
	}
	
	;---------
	; DESCRIPTION:    Fade out the toast gui, but don't destroy it.
	; PARAMETERS:
	;  guiId (I,REQ) - Gui ID (window handle) of the toast gui.
	;---------
	hideToast(guiId) {
		fadeGuiOut(guiId)
	}
	
	;---------
	; DESCRIPTION:    Fade out and destroy the toast gui.
	; PARAMETERS:
	;  guiId (I,REQ) - Gui ID (window handle) of the toast gui.
	;---------
	closeToast(guiId) {
		this.hideToast(guiId)
      Gui, Destroy
	}
}