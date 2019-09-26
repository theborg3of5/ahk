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
; == Public ====================
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
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "short" toast (shown for 1 second) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showShort(toastText := "") { ; GDB TODO get rid of toastText parameter and corresponding logic once we get all callers transitioned over
		if(toastText != "")
			new Toast(toastText).showForSeconds(1, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
		else
			this.showForSeconds(1, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "medium" toast (shown for 2 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showMedium(toastText := "") {
		if(toastText != "")
			new Toast(toastText).showForSeconds(2, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
		else
			this.showForSeconds(2, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "long" toast (shown for 5 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showLong(toastText := "") {
		if(toastText != "")
			new Toast(toastText).showForSeconds(5, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
		else
			this.showForSeconds(5, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	; GDB TODO
	makePersistent() {
		this.isPersistent := true
		return this ; Allows callers to chain (i.e. t := new Toast("text").makePersistent())
	}
	
	; GDB TODO - public member/property that determines whether we should pause while the toast is visible (we could use sleep or a timer based on it)
	; Do like makePersistent - function that allows chaining
	
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
	showError(problemMessage, errorMessage := "", mitigationMessage := "") { ; GDB TODO figure out what to do about this case - maybe a new child class? The combination logic + style overrides could be functions there.
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
		
		new Toast(toastText, overrides).showForSeconds(2, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Show the toast for a certain number of seconds, then hide or destroy it (based
	;                 on whether it's marked as persistent).
	; PARAMETERS:
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;                       Defaults to previous position (if set), then right edge of screen.
	;  y          (I,OPT) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;                       Defaults to previous position (if set), then bottom edge of screen.
	;---------
	showForSeconds(numSeconds, x := "", y := "") {
		this.showPersistent(x, y)
		
		finishFunc := ObjBindMethod(this, "finishShow")
		SetTimer, % finishFunc, % -numSeconds * 1000
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is hidden or closed.
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;              Defaults to previous position (if set), then right edge of screen.
	;  y (I,OPT) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;              Defaults to previous position (if set), then bottom edge of screen.
	;---------
	show(x := "", y := "") {
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
	; DESCRIPTION:    Change the text for the toast.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; NOTES:          Will try to maintain the same position, but toast size will expand to fit text.
	;---------
	setText(toastText) {
		Gui, % this.guiId ":Default" ; GDB TODO revisit which places have to do this - maybe it makes more sense to just do it around actual Gui calls?
		Toast.setLabelText(toastText, this.labelVarName)
		Toast.move(this.x, this.y, this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Fade the toast out, but don't destroy it (use .close() instead if you're
	;                 finished with the toast).
	;---------
	hide() {
		if(this.isGuiDestroyed) ; Safety check: if the gui has already been destroyed, we're done here.
			return
		
		this.doHide()
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close() {
		if(this.isGuiDestroyed) ; Safety check: if the gui has already been destroyed, we're done here.
			return
		
		this.doClose()
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
	isPersistent   := false ; Whether this is persistent or just single-use.
	
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
		
		return {"GUI_ID":guiId, "LABEL_VAR_NAME":labelVarName} ; GDB TODO just set member variables instead of returning an array
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
	setLabelText(toastText, labelVarName) { ; GDB TODO replace labelVarName parameter with this.labelVarName
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
	; DESCRIPTION:    Fade out the toast gui.
	;---------
	doHide() {
		fadeGuiOut(this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Fade out and destroy the toast gui.
	;---------
	doClose() {
		this.doHide()
		Gui, % this.guiId ":Destroy"
		this.isGuiDestroyed := true
	}
	
	;---------
	; DESCRIPTION:    Fade out the toast, and if it's not persistent, destroy it.
	;---------
	finishShow() {
		if(this.isGuiDestroyed) ; Safety check: if the gui has already been destroyed, we're done here.
			return
		
		if(this.isPersistent)
			this.doHide()
		else
			this.doClose()
	}
}