/* Class that shows something like a toast notification.
	
	Usage:
		Create Toast instance
		Show it (.showForTime or .show)
		If not showing on a timer, close it when finished (.close)
	
	Example:
		; Show a toast on a 5-second timer
		t := new Toast("5-second timer toast!")
		t.showForTime(5)
		
		; Show a toast, then hide it after finishing a longer-running action
		t := new Toast("heyo!")
		t.show()
		... ; longer-running action
		t.close()
*/

class Toast {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Create a new Toast object.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; RETURNS:        A new instance of this class.
	;---------
	__New(toastText) {
		if(!toastText)
			return
		
		this.buildGui(toastText)
	}
	
	;---------
	; DESCRIPTION:    Show this toast for a certain number of seconds, then destroy it.
	; PARAMETERS:
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at. Defaults to -1 (against right
	;                       edge of screen).
	;  y          (I,OPT) - The y coordinate to show the toast at. Defaults to -1 (against bottom
	;                       edge of screen).
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showForTime(numSeconds, x := -1, y := -1) {
		if(!numSeconds)
			return
		
		this.show(x, y)
		
		closeFunc := ObjBindMethod(this, "close") ; Create a BoundFunc object to call from the timer (that will still allow us to use 'this' keyword)
		SetTimer, % closeFunc, % -numSeconds * 1000
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is closed using .close().
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at. Defaults to -1 (against right edge of
	;              screen).
	;  y (I,OPT) - The y coordinate to show the toast at. Defaults to -1 (against bottom edge of
	;              screen).
	;---------
	show(x := -1, y := -1) {
		; Default values (-1) for x and y - bottom-right of monitor
		if(x = -1)
			showX := A_ScreenWidth  - this.width
		if(y = -1)
			showY := A_ScreenHeight - this.height
		
		this.makeGuiTheDefault()
		Gui, Show, % "Hide x" showX " y" showY
		
		fadeGuiIn(this.guiId, this.maxOpacity, , "NoActivate") ; Also actually shows the gui
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close() {
		fadeGuiOut(this.guiId, this.maxOpacity)
		
		this.makeGuiTheDefault()
      Gui, Destroy
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	backgroundColor := "2A211C"
	fontColor       := "BDAE9D"
	fontSize        := 20
	fontName        := "Consolas"
	marginX         := 5
	marginY         := 0
	maxOpacity      := 255
	
	guiId  := ""
	width  := ""
	height := ""
	
	;---------
	; DESCRIPTION:    Make this toast's gui the default for all Gui, * commands.
	;---------
	makeGuiTheDefault() {
		Gui, % this.guiId ":Default"
	}
	
	;---------
	; DESCRIPTION:    Build the toast gui, applying various formatting and adding the text.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   Saves off a reference to the gui's window handle.
	;---------
	buildGui(toastText) {
		; Create Gui and save off handle
		Gui, New, +HWNDguiWindowHandle
		this.guiId := guiWindowHandle
		
		; Other gui options
		Gui, +AlwaysOnTop -Caption +LastFound +Toolwindow
		Gui, % "+E" WS_EX_CLICKTHROUGH
		
		; Set formatting options
		Gui, Color, % this.backgroundColor
		Gui, Font, % "c" this.fontColor " s" this.fontSize, % this.fontName
		Gui, Margin, % this.marginX, % this.marginY
		
		; Add text
		Gui, Add, Text, , % toastText
		
		; Resize to text size and store off dimensions
		Gui, Show, AutoSize Hide
		WinGetPos, , , w, h
		this.width := w
		this.height := h
	}
}