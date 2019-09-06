/* Class that shows something like a toast notification.
	
	Usage:
		Create Toast instance
		Show it (.showForSeconds or .show)
		If not showing on a timer, close it when finished (.close)
	
	Example:
		; Show a toast on a 5-second timer
		t := new Toast("5-second timer toast!")
		t.showForSeconds(5)
		; OR, statically:
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
		Toast.showForSeconds(toastText, 1, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "medium" toast (shown for 2 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showMedium(toastText) {
		Toast.showForSeconds(toastText, 2, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "long" toast (shown for 5 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showLong(toastText) {
		Toast.showForSeconds(toastText, 5, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Displays an error toast (dark yellow text, slightly larger) for a short
	;                 duration (2 seconds).
	; PARAMETERS:
	;  problemMessage    (I,REQ) - Text about what the problem is (what happened or weren't we able
	;                              to do?)
	;  errorMessage      (I,OPT) - Technical error text - what happened code-wise?
	;  mitigationMessage (I,OPT) - What we did instead - did we add something to the clipboard since
	;                              we couldn't link it, for example?
	;---------
	showError(problemMessage, errorMessage := "", mitigationMessage := "") {
		toastText := problemMessage
		toastText := toastText.appendPiece(errorMessage,      ":`n")
		toastText := toastText.appendPiece(mitigationMessage, "`n`n")
		
		overrides := {}
		overrides["BACKGROUND_COLOR"] := "000000" ; Black
		overrides["FONT_COLOR"]       := "CC9900" ; Dark yellow/gold
		overrides["FONT_SIZE"]        := 22
		overrides["MARGIN_X"]         := 6
		overrides["MARGIN_Y"]         := 1
		overrides["LABEL_STYLES"]     := "Right"
		
		Toast.showForSeconds(toastText, 2, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge, overrides)
	}
	
	;---------
	; DESCRIPTION:    Static caller to show a toast for a certain number of seconds, then destroy it.
	; PARAMETERS:
	;  toastText      (I,REQ) - The text to show in the toast.
	;  numSeconds     (I,REQ) - The number of seconds to show the toast for.
	;  x              (I,OPT) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;                           Defaults to previous position (if set), then right edge of screen.
	;  y              (I,OPT) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;                           Defaults to previous position (if set), then bottom edge of screen.
	;  styleOverrides (I,OPT) - Any style overrides that you'd like to make. Defaults can be
	;                           found in .getStyles().
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showForSeconds(toastText, numSeconds, x := "RIGHT_EDGE", y := "BOTTOM_EDGE", styleOverrides := "") { ; x := VisualWindow.X_RightEdge, y := VisualWindow.Y_BottomEdge
		idAry := Toast.buildGui(styleOverrides)
		guiId        := idAry["GUI_ID"]
		labelVarName := idAry["LABEL_VAR_NAME"]
		
		Toast.setLabelText(toastText, labelVarName)
		Toast.showToast(x, y, guiId)
		
		closeFunc := ObjBindMethod(Toast, "closeToast", guiId) ; Create a BoundFunc object of the .closeToast function (with guiId passed to it) for when the timer finishes.
		SetTimer, % closeFunc, % -numSeconds * 1000
	}

; ==============================
; == Public (Persistent) =======
; ==============================
	;---------
	; DESCRIPTION:    Create a new Toast object.
	; PARAMETERS:
	;  toastText      (I,OPT) - The text to show in the toast.
	;  styleOverrides (I,OPT) - Any style overrides that you'd like to make. Defaults can be
	;                           found in .getStyles().
	; RETURNS:        A new instance of this class.
	;---------
	__New(toastText := "", styleOverrides := "") {
		idAry := this.buildGui(styleOverrides)
		this.guiId        := idAry["GUI_ID"]
		this.labelVarName := idAry["LABEL_VAR_NAME"]
		
		if(toastText)
			Toast.setLabelText(toastText, this.labelVarName)
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is hidden or closed.
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;              Defaults to previous position (if set), then right edge of screen.
	;  y (I,OPT) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;              Defaults to previous position (if set), then bottom edge of screen.
	;---------
	showPersistent(x := "", y := "") {
		Gui, % this.guiId ":Default"
		
		; Use optional x/y if given.
		if(x != "")
			this.x := x
		if(y != "")
			this.y := y
		
		; Default to bottom-right if nothing given and no previous position.
		if(this.x = "")
			this.x := VisualWindow.X_RightEdge
		if(this.y = "")
			this.y := VisualWindow.Y_BottomEdge
		
		this.showToast(this.x, this.y, this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Show this toast for a certain number of seconds, then hide it.
	; PARAMETERS:
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;                       Defaults to previous position (if set), then right edge of screen.
	;  y          (I,OPT) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;                       Defaults to previous position (if set), then bottom edge of screen.
	;---------
	showPersistentForSeconds(numSeconds, x := "", y := "") {
		Gui, % this.guiId ":Default"
		
		this.showPersistent(x, y)
		
		hideFunc := ObjBindMethod(Toast, "hideToast", this.guiId) ; Create a BoundFunc object of the .closeToast function (with guiId passed to it) for when the timer finishes.
		SetTimer, % hideFunc, % -numSeconds * 1000
	}
	
	;---------
	; DESCRIPTION:    Change the text for the toast, without hiding it.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; NOTES:          Will try to maintain the same position, but toast size will expand to fit text.
	;---------
	setText(toastText) {
		Gui, % this.guiId ":Default"
		Toast.setLabelText(toastText, this.labelVarName)
		Toast.move(this.x, this.y, this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Fade the toast out, but don't destroy it (use .close() instead if you're
	;                 finished with the toast).
	;---------
	hide() {
		; If the gui has already been destroyed, we're done here.
		if(this.isGuiDestroyed)
			return
		
		Gui, % this.guiId ":Default"
		this.hideToast(this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close() {
		; If the gui has already been destroyed, we're done here.
		if(this.isGuiDestroyed)
			return
		
		Gui, % this.guiId ":Default"
		this.closeToast(this.guiId)
		this.isGuiDestroyed := true
	}
	
	
; ==============================
; == Private ===================
; ==============================
	static ToastTitle := "[TOAST]"
	
	styles         := ""
	guiId          := ""
	labelVarName   := ""
	x              := ""
	y              := ""
	isGuiDestroyed := false
	
	;---------
	; DESCRIPTION:    Build the toast gui, applying various properties.
	; PARAMETERS:
	;  styleOverrides (I,OPT) - Any style overrides that you'd like to make. Defaults can be
	;                           found in .getStyles().
	; SIDE EFFECTS:   Saves off a reference to the gui's window handle.
	; RETURNS:        Array of ID information, format:
	;                 	idAry["GUI_ID"]         = Window handle/guiId
	;                 	     ["LABEL_VAR_NAME"] = Name of the global variable connected to the label
	;                 	                          containing the toast text.
	;---------
	buildGui(styleOverrides := "") {
		; Create Gui and save off window handle (which is also guiId)
		Gui, New, +HWNDguiId
		
		; Other gui options
		Gui, +AlwaysOnTop -Caption +LastFound +ToolWindow
		Gui, % "+E" WS_EX_CLICKTHROUGH
		
		; Set formatting options
		styles := Toast.getStyles(styleOverrides)
		Gui, Color, % styles["BACKGROUND_COLOR"]
		Gui, Font, % "c" styles["FONT_COLOR"] " s" styles["FONT_SIZE"], % styles["FONT_NAME"]
		Gui, Margin, % styles["MARGIN_X"], % styles["MARGIN_Y"]
		
		; Add label
		labelVarName := guiId "Text" ; Come up with a unique variable we can use to reference the label (to change its contents if needed).
		setDynamicGlobalVar(labelVarName) ; Since the variable must be global, declare it as such.
		Gui, Add, Text, % "v" labelVarName " " styles["LABEL_STYLES"]
		
		return {"GUI_ID":guiId, "LABEL_VAR_NAME":labelVarName}
	}
	
	;---------
	; DESCRIPTION:    Determine the styles to use for the toast gui, based on hard-coded defaults
	;                 and any given overrides.
	; PARAMETERS:
	;  styleOverrides (I,OPT) - Array of style overrides, see default styles below for supported
	;                           subscripts. Format:
	;                              styleOverrides(<property>) := <value>
	; RETURNS:        Combined array of styles to use for the toast gui.
	;---------
	getStyles(styleOverrides := "") {
		styles := {}
		
		; Default styles
		styles["BACKGROUND_COLOR"] := "2A211C"
		styles["FONT_COLOR"]       := "BDAE9D"
		styles["FONT_SIZE"]        := 20
		styles["FONT_NAME"]        := "Consolas"
		styles["MARGIN_X"]         := 5
		styles["MARGIN_Y"]         := 0
		styles["LABEL_STYLES"]     := ""
		
		; Merge in any overrides
		styles := mergeObjects(styles, styleOverrides)
		
		return styles
	}
	
	;---------
	; DESCRIPTION:    Move the toast gui to the given coordinates and resize it to its contents.
	; PARAMETERS:
	;  x     (I,REQ) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;  y     (I,REQ) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;  guiId (I,REQ) - Window handle for the toast gui.
	;---------
	move(x, y, guiId) {
		; If x/y not given, default them to right/bottom
		if(x = "")
			x := VisualWindow.X_RightEdge
		if(y = "")
			y := VisualWindow.Y_BottomEdge
		origDetectSetting := setDetectHiddenWindows("On")
		
		Gui, +LastFound ; Needed to identify the window on next line
		titleString := getIdTitleStringForWindow("") ; Blank title string input for last found window
		
		isWinHidden := !isWindowVisible(titleString)
		if(isWinHidden)
			Gui, Show, AutoSize NoActivate Hide, % Toast.ToastTitle ; Resize to size of contents, but keep toast hidden (and actually show it further down)
		else
			Gui, Show, AutoSize NoActivate, % Toast.ToastTitle ; Resize to size of contents
		
		window := new VisualWindow(titleString).move(x, y) ; Blank title string for last found window
		
		if(isWinHidden)
			Gui, Show, NoActivate, % Toast.ToastTitle
		
		setDetectHiddenWindows(origDetectSetting)
	}
	
	;---------
	; DESCRIPTION:    Set the text of the toast label and resize it fit that text.
	; PARAMETERS:
	;  toastText    (I,REQ) - The text to show in the toast.
	;  labelVarName (I,REQ) - The name of the global variable connected to the toast label.
	;---------
	setLabelText(toastText, labelVarName) {
		toastText := escapeCharUsingRepeat(toastText, "&")
		
		; Figure out how big the text control needs to be to fit its contents
		getLabelSizeForText(toastText, textWidth, textHeight)
		
		; Update the text and width/height
		GuiControl,     , % labelVarName, % toastText
		GuiControl, Move, % labelVarName, % "w" textWidth " h" textHeight
	}
	
	;---------
	; DESCRIPTION:    Show (fade in) the toast.
	; PARAMETERS:
	;  x     (I,OPT) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;  y     (I,OPT) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;  guiId (I,REQ) - Window handle for the toast gui.
	;---------
	showToast(x, y, guiId) {
		Toast.move(x, y, guiId)
		fadeGuiIn(guiId)
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
		Toast.hideToast(guiId)
      Gui, Destroy
	}
}