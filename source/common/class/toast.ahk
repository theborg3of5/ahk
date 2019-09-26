/* Class that shows something like a toast notification.
	
	Usage:
		Create Toast instance
		Show it (.showForSeconds or .show)
		Hide it if needed (.hide)
		If it's persistent, close it when finished (.close)
	
	Example:
		; Show a toast on a 5-second timer
		t := new Toast("5-second timer toast!")
		t.showForSeconds(5)
		; OR:
		new Toast("5-second timer toast!").showLong()
		
		; Show a toast, then hide it after finishing a longer-running action
		t := new Toast("Running long action").makePersistent() ; Make it persistent so showing it on a timer doesn't destroy it
		t.show()
		... ; Long action happens
		t.setText("Next step")
		... ; Next step happens
		t.hide() ; Toast is hidden but still exists
		...
		t.showForSeconds(3) ; Toast becomes visible again for 3 seconds, then it's hidden automatically
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
		this.buildGui(styleOverrides)
		
		if(toastText)
			this.setLabelText(toastText)
	}
	
	;---------
	; DESCRIPTION:    Mark the toast as persistent
	; RETURNS:        this
	; NOTES:          This means that the toast will be hidden (rather than destroyed) when we
	;                 finish showing it on a timer.
	;---------
	makePersistent() {
		this.isPersistent := true
		return this
	}
	
	;---------
	;---------
	; DESCRIPTION:    Wrapper for .showForSeconds for a "short" toast (shown for 1 second) in
	;                 the bottom-right corner of the screen.
	;---------
	showShort() {
		this.showForSeconds(1, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for .showForSeconds for a "medium" toast (shown for 2 seconds) in
	;                 the bottom-right corner of the screen.
	;---------
	showLong(toastText := "") {
		if(toastText != "")
			new Toast(toastText).showForSeconds(5, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
		else
			this.showForSeconds(5, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	;---------
	; DESCRIPTION:    Mark the toast as persistent
	; DESCRIPTION:    Wrapper for .showForSeconds for a "long" toast (shown for 5 seconds) in
	;                 the bottom-right corner of the screen.
	;---------
	showLong() {
		this.showForSeconds(5, VisualWindow.X_RightEdge, VisualWindow.Y_BottomEdge)
	}
	
	; GDB TODO - public member/property that determines whether we should pause while the toast is visible (we could use sleep or a timer based on it)
	; Do like makePersistent - function that allows chaining
	
	;---------
	; DESCRIPTION:    Displays an error toast (dark yellow text, slightly larger, buttom-right) for
	;                 a medium duration (2 seconds).
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
		
		new Toast(toastText, overrides).showMedium()
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
		this.show(x, y)
		
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
		this.move(x, y)
		fadeGuiIn(this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Change the text for the toast.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; NOTES:          Will try to maintain the same position, but toast size will expand to fit text.
	;---------
	setText(toastText) {
		this.setLabelText(toastText)
		this.move()
	}
	
	;---------
	; DESCRIPTION:    Fade the toast out, but don't destroy it (use .close() instead if you're
	;                 finished with the toast).
	;---------
	hide() {
		if(this.isGuiDestroyed) ; Safety check: if the gui has already been destroyed, we're done here.
			return
		
		fadeGuiOut(this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close() {
		if(this.isGuiDestroyed) ; Safety check: if the gui has already been destroyed, we're done here.
			return
		
		this.hide()
		Gui, % this.guiId ":Destroy"
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
	isGuiDestroyed := false ; To make sure we're not trying to hide/close an already-destroyed toast.
	isPersistent   := false ; Whether this is persistent or just single-use.
	
	;---------
	; DESCRIPTION:    Build the toast gui, applying various properties.
	; PARAMETERS:
	;  styleOverrides (I,OPT) - Any style overrides that you'd like to make. Defaults can be
	;                           found in .getStyles().
	; SIDE EFFECTS:   Updates members for window handle and label global variable name.
	;---------
	buildGui(styleOverrides := "") {
		; Create Gui and save off window handle (which is also winId)
		Gui, New, +HWNDwinId
		this.guiId := winId
		
		; Other gui options
		Gui, +AlwaysOnTop -Caption +LastFound +ToolWindow
		Gui, % "+E" WS_EX_CLICKTHROUGH
		
		; Set formatting options
		styles := this.getStyles(styleOverrides)
		Gui, Color, % styles["BACKGROUND_COLOR"]
		Gui, Font, % "c" styles["FONT_COLOR"] " s" styles["FONT_SIZE"], % styles["FONT_NAME"]
		Gui, Margin, % styles["MARGIN_X"], % styles["MARGIN_Y"]
		
		; Add label
		this.labelVarName := this.guiId "Text" ; Come up with a unique variable we can use to reference the label (to change its contents if needed).
		setDynamicGlobalVar(this.labelVarName) ; Since the variable must be global, declare it as such.
		Gui, Add, Text, % "v" this.labelVarName " " styles["LABEL_STYLES"]
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
	;  x (I,REQ) - The x coordinate to show the toast at (or special value from VisualWindow.X_*).
	;              Defaults to right edge.
	;  y (I,REQ) - The y coordinate to show the toast at (or special value from VisualWindow.Y_*).
	;              Defaults to bottom edge.
	;---------
	move(x := "", y := "") {
		origDetectSetting := setDetectHiddenWindows("On")
		
		; Default to current position, then bottom-right corner
		x := firstNonBlankValue(x, this.x, VisualWindow.X_RightEdge)
		y := firstNonBlankValue(y, this.y, VisualWindow.Y_BottomEdge)
		
		Gui, % this.guiId ":Default"
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
		
		; Store off new position
		this.x := x
		this.y := y
		
		setDetectHiddenWindows(origDetectSetting)
	}
	
	;---------
	; DESCRIPTION:    Set the text of the toast label and resize it fit that text.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	;---------
	setLabelText(toastText) {
		toastText := escapeCharUsingRepeat(toastText, "&")
		
		; Figure out how big the text control needs to be to fit its contents
		getLabelSizeForText(toastText, textWidth, textHeight)
		
		; Update the text and width/height
		GuiControl,     , % this.labelVarName, % toastText
		GuiControl, Move, % this.labelVarName, % "w" textWidth " h" textHeight
	}
	
	;---------
	; DESCRIPTION:    Fade out the toast, and if it's not persistent, destroy it.
	;---------
	finishShow() {
		if(this.isPersistent)
			this.hide()
		else
			this.close()
	}
}