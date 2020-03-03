/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

; Edit width = 9*numChars + 13

class DebugPopup {
	; #PUBLIC#
	
	;  - Constants
	static Prefix_GuiSpecialLabels := "DebugPopupGui_" ; Used to have the gui call DebugPopupGui_* functions instead of just Gui* ones
	;  - staticMembers
	
	;  - nonStaticMembers
	guiId := ""
	editFieldVar := ""
	
	
	
	
	;  - properties
	;  - __New()/Init()
	__New(params*) {
		
		
		
		
		table := new DebugTable("Debug Info").thickBorderOn()
		table.addPairs(params*)
		
		message   := table.getText()
		lineWidth := table.getWidth()
		numLines  := table.getHeight()
		
		
		; Use a maxiumum of 90% of available height/width so we're not right up against the edges
		workArea := WindowLib.getMonitorWorkArea()
		availableHeight := workArea["HEIGHT"] * 0.9
		availableWidth  := workArea["WIDTH"]  * 0.9
		
		; Calculate edit control height/width and whether we need to scroll
		editHeight := this.calcMaxSize(availableHeight, this.Edit_LineHeight, numLines, needVScroll)
		; For width, there's a margin involved - take it out before we call calcMaxSize (as that works on units, characters here) and add it back on afterwards.
		availableWidth -= this.Edit_TotalMarginWidth
		editWidth := this.calcMaxSize(availableWidth, this.Edit_CharWidth, lineWidth, needHScroll) + this.Edit_TotalMarginWidth
		
		mouseIsOverEditField := ObjBindMethod(this, "mouseIsOverEditField")
		Hotkey, If, % mouseIsOverEditField
		if(needVScroll) {
			scrollUp   := ObjBindMethod(this, "scrollUp")
			scrollDown := ObjBindMethod(this, "scrollDown")
			Hotkey, ~WheelUp,    % scrollUp
			Hotkey, ~WheelDown,  % scrollDown
			
			scrollUpPrecise   := ObjBindMethod(this, "scrollUp",   1)
			scrollDownPrecise := ObjBindMethod(this, "scrollDown", 1)
			Hotkey, ~^WheelUp,   % scrollUpPrecise
			Hotkey, ~^WheelDown, % scrollDownPrecise
		}
		if(needHScroll) {
			scrollLeft  := ObjBindMethod(this, "scrollLeft")
			scrollRight := ObjBindMethod(this, "scrollRight")
			Hotkey, ~+WheelUp,    % scrollLeft
			Hotkey, ~+WheelDown,  % scrollRight
			
			scrollLeftPrecise  := ObjBindMethod(this, "scrollLeft",  1)
			scrollRightPrecise := ObjBindMethod(this, "scrollRight", 1)
			Hotkey, ~+^WheelUp,   % scrollLeftPrecise
			Hotkey, ~+^WheelDown, % scrollRightPrecise
		}
		Hotkey, If
		
		
		
		Gui, New, % "+HWNDguiId +Label" this.Prefix_GuiSpecialLabels ; guiId := gui's window handle, DebugPopupGui_* functions instead of Gui*
		this.guiId := guiId
		
		this.editFieldVar := this.guiId "DebugEdit"
		GuiLib.createDynamicGlobal(this.editFieldVar)
		
		Gui, Margin, 0, 0
		Gui, Color, % this.BackgroundColor
		Gui, Font, % "c" this.FontColor " s" this.FontSize, % this.FontName
		
		editProperties := "ReadOnly -WantReturn -VScroll -Wrap -E" MicrosoftLib.ExStyle_SunkenBorder
		Gui, Add, Edit, % editProperties " h" editHeight " w" editWidth " v" this.editFieldVar, % message
		
		Gui, Add, Button, Hidden Default x0 y0 gDebugPopupGui_Close ; DebugPopupGui_Close call on activate (with {Enter} since it's Default)
		
		Gui, % "-MinimizeBox -MaximizeBox -" MicrosoftLib.Style_CaptionHead
		GuiControl, Focus, % this.editFieldVar
		
		Gui, Show, , % "Debug Info"
		
		
		
		; WinWaitClose
		
		; GDB TODO do we need to disable the hotkeys when we close? (only if they exist, though - either check if the hotkeys exist, or just use needVScroll/needHScroll)
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
	;  - otherFunctions
	
	
	; #INTERNAL#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #PRIVATE#
	
	;  - Constants
	static BackgroundColor       := "444444"
	static FontColor             := "00FF00"
	static FontName              := "Consolas"
	static FontSize              := 12 ; points
	static Edit_LineHeight       := 19 ; How many px tall each line is in the edit control
	static Edit_CharWidth        := 9  ; How many px wide each character is in the edit control
	static Edit_TotalMarginWidth := 8  ; How much extra space the edit control needs to cut off at character edges
	
	static Edit_ControlId := "Edit1"
	
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	mouseIsOverEditField() {
		MouseGetPos("", "", windowUnderMouse, varNameUnderMouse)
		GuiControlGet, mouseName, % this.guiId ":Name", % varNameUnderMouse
		
		return (windowUnderMouse = this.guiId) && (mouseName = this.editFieldVar)
	}
	
	
	
	
	calcMaxSizeBeforeScroll(available, pieceSize, numPieces) {
		; The size this would be if we didn't scroll
		possibleSize := (pieceSize * numPieces)
		
		; If it already fits within the available space, no problem.
		if(possibleSize <= available)
			return numPieces * pieceSize
		
		; Otherwise we'll need to only show some of the space (and scroll).
		numPiecesToShow := available // pieceSize
		return numPiecesToShow * pieceSize
	}
	
	calcMaxSize(available, pieceSize, numPieces, ByRef needScroll) {
		needScroll := false
		
		; The size this would be if we didn't scroll
		possibleSize := numPieces * pieceSize
		
		; If it already fits within the available space, no problem.
		if(possibleSize <= available)
			return possibleSize
		
		; Otherwise we'll need to show a smaller size and scroll.
		needScroll := true
		numPiecesToShow := available // pieceSize
		return numPiecesToShow * pieceSize
	}
	
	;---------
	; DESCRIPTION:    Send scroll messages to this gui.
	; PARAMETERS:
	;  scrollType      (I,REQ) - The type of scrolling from MicrosoftLib.Message_*Scroll
	;  scrollDirection (I,REQ) - The direction to scroll from MicrosoftLib.ScrollBar_*
	;  count           (I,REQ) - How many messages to send (roughly how many lines/characters to scroll)
	;---------
	sendScrollMessages(scrollType, scrollDirection, count) {
		controlId := this.Edit_ControlId
		titleString := "ahk_id " this.guiId
		
		Loop, % count
			SendMessage, % scrollType, % scrollDirection, , % controlId, % titleString
	}
	
	; Scroll in specific directions
	scrollUp(count := 3) {
		this.sendScrollMessages(MicrosoftLib.Message_VertScroll,  MicrosoftLib.ScrollBar_Up,    count)
	}
	scrollDown(count := 3) {
		this.sendScrollMessages(MicrosoftLib.Message_VertScroll,  MicrosoftLib.ScrollBar_Down,  count)
	}
	scrollLeft(count := 10) {
		this.sendScrollMessages(MicrosoftLib.Message_HorizScroll, MicrosoftLib.ScrollBar_Left,  count)
	}
	scrollRight(count := 10) {
		this.sendScrollMessages(MicrosoftLib.Message_HorizScroll, MicrosoftLib.ScrollBar_Right, count)
	}
	; #END#
}

; Close label triggered by the hidden, default button in DebugPopup.
DebugPopupGui_Close() {
	Gui, Destroy
}
