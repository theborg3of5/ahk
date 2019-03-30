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
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "short" toast (shown for 1 second) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showShort(toastText) {
		Toast.showForSeconds(toastText, 1, -1, -1)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "medium" toast (shown for 2 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showMedium(toastText) {
		Toast.showForSeconds(toastText, 2, -1, -1)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "long" toast (shown for 5 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showLong(toastText) {
		Toast.showForSeconds(toastText, 5, -1, -1)
	}
	
	;---------
	; DESCRIPTION:    Static caller to show this toast for a certain number of seconds, then destroy it.
	; PARAMETERS:
	;  toastText  (I,REQ) - The text to show in the toast.
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x     (I,OPT) - The x coordinate to show the toast at.
	;                  Defaults to -1 (against right edge of screen).
	;                  Also supports -2 for horizontally centered.
	;  y     (I,OPT) - The y coordinate to show the toast at. 
	;                  Defaults to -1 (against bottom edge of screen).
	;                  Also supports -2 for vertically centered.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showForSeconds(toastText, numSeconds, x := -1, y := -1) {
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
	;  toastText  (I,REQ) - The text to show in the toast.
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
	;  toastText  (I,REQ) - The text to show in the toast.
	; NOTES:          Will try to maintain the same position (including -1 considerations), but
	;                 toast size will expand to fit text.
	;---------
	setText(toastText) {
		Gui, % this.guiId ":Default"
		this.setLabelText(toastText, this.labelVarName)
		this.move(this.x, this.y)
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is hidden or closed.
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at.
	;              Special values:
	;                -1 - Right-aligned (against right edge of screen)
	;                -2 - Horizontally centered
	;  y (I,OPT) - The y coordinate to show the toast at. 
	;              Special values:
	;                -1 - Bottom-aligned (against bottom edge of screen)
	;                -2 - Vertically centered
	;---------
	showPersistent(x := -1, y := -1) {
		Gui, % this.guiId ":Default"
		this.x := x
		this.y := y
		this.showToast(x, y, this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Show this toast for a certain number of seconds, then hide it.
	; PARAMETERS:
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at. Defaults to -1.
	;                       Special values:
	;                         -1 - Right-aligned (against right edge of screen)
	;                         -2 - Horizontally centered
	;  y          (I,OPT) - The y coordinate to show the toast at. 
	;                       Special values:
	;                         -1 - Bottom-aligned (against bottom edge of screen)
	;                         -2 - Vertically centered
	;---------
	showPersistentForSeconds(numSeconds, x := -1, y := -1) {
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
	;                      Special values:
	;                        -1 - Right-aligned (against right edge of screen)
	;                        -2 - Horizontally centered
	;  y         (I,OPT) - The y coordinate to show the toast at. 
	;                      Special values:
	;                        -1 - Bottom-aligned (against bottom edge of screen)
	;                        -2 - Vertically centered
	;  showProps (I,OPT) - Any additional properties should be included in Gui, Show calls. For
	;                      example, passing "Hide" would keep the gui hidden while we resize and
	;                      move it.
	;---------
	move(x, y, showProps = "") {
		; If x/y not given, default them to -1
		x := ifBlankDefaultTo(x, -1)
		y := ifBlankDefaultTo(y, -1)
		
		; Resize to size of contents
		Gui, Show, AutoSize NoActivate %showProps%
		WinGetPos, , , guiWidth, guiHeight
		
		; -1 for x/y mean right/bottom edges
		if(x = -1)
			x := A_ScreenWidth  - guiWidth
		if(y = -1)
			y := A_ScreenHeight - guiHeight
		
		; -2 for x/y mean horizontally/vertically centered
		if(x = -2)
			x := (A_ScreenWidth  - guiWidth) / 2
		if(y = -2)
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
	;  x     (I,REQ) - The x coordinate to show the toast at.
	;  y     (I,REQ) - The y coordinate to show the toast at.
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