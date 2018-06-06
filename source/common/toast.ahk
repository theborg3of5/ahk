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
	
	__New(text) {
		; GDB TODO store off parameters in class variables
		
		this.buildGui()
	}
	
	show() {
		Gui, Show, W%guiWidth% H75 X%showX% Y%showY%
		
		GUI, %GUI_handle%: Show, % (this.activate?"":"NoActivate ") "autosize x" this.x " y" this.y, % "Toast" this.id
		
	}
	
	hide() { ; GDB TODO call out that this also destroys
		
      GUI, %GUI_handle%: Destroy
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	; GDB TODO: font, font size, font color, background color, gui handle/ID, transparency, text, margin?
	
	buildGui() {
		; Create Gui
		Gui, +Toolwindow -Resize -SysMenu -Border -Caption +AlwaysOnTop +LastFound
		Gui, %GUI_handle%: New, -Caption +ToolWindow +AlwaysOnTop +hwndHWND
		GUI, %GUI_handle%:+LastFoundExist
		; GDB TODO save off ID?
		guiID := WinGet("ID")
		GUI_handle:="Toast_GUI" this.id
		
		; Color
		Gui, Color, %backgroundColor%
		Gui, %GUI_handle%: Color, % this.bgColor
		
		; Margin?
		Gui, %GUI_handle%:Margin, % this.marginX, % this.marginY
		
		; Font
		Gui, %GUI_handle%: Font, norm s%s% c%c% %o%, %f%
		Gui, Font, c%timeColor% s40, Consolas
		
		; Transparency
		WinSet, Transparent, %transHidden%
		WinSet, Transparent, %transShown%, ahk_id %guiID%
		WinSet, Trans, % this.trans
		
		; Add text
		Gui, Add, Text, x%guiMargin% y10 w%tmpWidth% h50 vTimerText, 00:00:00
		Gui, %GUI_handle%: Add, Text,, %t%
		
	}
	
}