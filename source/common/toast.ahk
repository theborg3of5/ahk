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
	; DESCRIPTION:    Static caller to show this toast for a certain number of seconds, then destroy it.
	; PARAMETERS:
	;  toastText  (I,REQ) - The text to show in the toast.
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at. Defaults to -1 (against right
	;                       edge of screen).
	;  y          (I,OPT) - The y coordinate to show the toast at. Defaults to -1 (against bottom
	;                       edge of screen).
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showForTime(toastText, numSeconds, x := -1, y := -1) {
		if(!toastText || !numSeconds)
			return
		
		guiId := Toast.buildGui(toastText)
		Toast.show(x, y, guiId)
		
		closeFunc := ObjBindMethod(Toast, "close", guiId) ; Create a BoundFunc object of the Toast.close function (with guiId passed to it) for when the timer finishes.
		SetTimer, % closeFunc, % -numSeconds * 1000
	}
	
	;---------
	; DESCRIPTION:    Create a new Toast object.
	; PARAMETERS:
	;  toastText (I,REQ) - The text that will be shown in the toast.
	; RETURNS:        A new instance of this class.
	;---------
	__New(toastText) {
		if(!toastText)
			return
		
		this.guiId := Toast.buildGui(toastText)
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is closed using .close().
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at. Defaults to -1 (against right edge of
	;              screen).
	;  y (I,OPT) - The y coordinate to show the toast at. Defaults to -1 (against bottom edge of
	;              screen).
	; GDB TODO add guiId parameter here and elsewhere
	;---------
	show(x := -1, y := -1, guiId := "") {
		if(!guiId)
			guiId := this.guiId
		Gui, % guiId ":Default"
		
		; Resize to size of contents
		Gui, Show, AutoSize Hide
		WinGetPos, , , width, height
		
		; Default values (-1) for x and y - bottom-right of monitor
		if(x = -1)
			showX := A_ScreenWidth  - width
		if(y = -1)
			showY := A_ScreenHeight - height
		
		Gui, Show, % "Hide x" showX " y" showY
		
		fadeGuiIn(guiId, "NoActivate", Toast.maxOpacity) ; Also actually shows the gui
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close(guiId := "") {
		if(!guiId)
			guiId := this.guiId
		Gui, % guiId ":Default"
		
		fadeGuiOut(guiId)
      Gui, Destroy
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
	
	guiId := ""
	
	
	;---------
	; DESCRIPTION:    Build the toast gui, applying various formatting and adding the text.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   Saves off a reference to the gui's window handle.
	; RETURNS:        ID of gui (also the window handle)
	;---------
	buildGui(toastText) {
		; Create Gui and save off window handle (which is also guiId)
		Gui, New, +HWNDguiId
		
		; Other gui options
		Gui, +AlwaysOnTop -Caption +LastFound +Toolwindow
		Gui, % "+E" WS_EX_CLICKTHROUGH
		
		; Set formatting options
		Gui, Color, % Toast.backgroundColor
		Gui, Font, % "c" Toast.fontColor " s" Toast.fontSize, % Toast.fontName
		Gui, Margin, % Toast.marginX, % Toast.marginY
		
		; Add text
		Gui, Add, Text, , % toastText
		
		return guiId
	}
}