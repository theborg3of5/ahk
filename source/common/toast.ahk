/* ***
	
	Usage:
		***
		
	Notes:
		***
	
	Example:
		***
*/

class Toast {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(toastText) {
		this.buildGui(toastText)
	}
	
	show(x := -1, y := -1) {
		; Default values (-1) for x and y - bottom-right of monitor
		if(x = -1)
			showX := A_ScreenWidth  - this.width
		if(y = -1)
			showY := A_ScreenHeight - this.height
		
		Gui, % this.guiId ":Default"
		Gui, Show, % "NoActivate" " x" showX " y" showY
	}
	
	hide() { ; GDB TODO call out that this also destroys
		Gui, % this.guiId ":Default"
      Gui, Destroy
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	guiId := ""
	
	backgroundColor := ""
	fontColor := ""
	fontSize := ""
	fontName := ""
	marginX := ""
	marginY := ""
	opacity := ""
	width := ""
	height := ""
	
	buildGui(toastText) {
		; Create Gui
		Gui, New, +AlwaysOnTop -Caption +Toolwindow -Resize -SysMenu -Border +LastFound +HWNDguiWindowHandle
		this.guiId := guiWindowHandle
		
		this.backgroundColor := "000000" ; GDB TODO put these "defaults" somewhere else?
		this.fontColor := "00FF00"
		this.fontSize := 40
		this.fontName := "Consolas"
		this.marginX := 10
		this.marginY := 10
		this.opacity := 230
		
		; Set formatting options
		Gui, Color, % this.backgroundColor
		Gui, Font, % "c" this.fontColor " s" this.fontSize, % this.fontName
		Gui, Margin, % this.marginX, % this.marginY
		WinSet, Transparent, % this.opacity
		
		; Add text
		Gui, Add, Text, , % toastText
		
		; Resize and store off dimensions
		Gui, Show, AutoSize Hide
		WinGetPos, , , w, h
		this.width := w
		this.height := h
	}
	
}