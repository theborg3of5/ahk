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
	;  - properties
	;  - __New()/Init()
	__New(params*) {
		; Build the table of info
		table := new DebugTable("Debug Info").thickBorderOn()
		table.addPairs(params*)
		
		; Set up and show popup
		editSizes := this.calculatePopupDimensions(table)
		this.createAndShowPopup(editSizes, table)
	}
	;  - otherFunctions
	
	
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
	guiId        := "" ; Gui's window handle
	editFieldVar := "" ; Unique ID for edit field, based on this.guiId
	;  - functions
	
	calculatePopupDimensions(table) {
		; Use a maxiumum of 90% of available height/width so we're not right up against the edges
		workArea := WindowLib.getMonitorWorkArea()
		availableWidth  := workArea["WIDTH"]  * 0.9
		availableHeight := workArea["HEIGHT"] * 0.9
		
		; For width, there's a margin involved - take it out before we call calcMaxSize (as that works on units, characters here) and add it back on afterwards.
		availableWidth -= this.Edit_TotalMarginWidth
		
		; Calculate edit control height/width and whether we need to scroll
		editHeight := this.calcMaxSize(availableHeight, this.Edit_LineHeight, table.getHeight())
		editWidth  := this.calcMaxSize(availableWidth,  this.Edit_CharWidth,  table.getWidth()) + this.Edit_TotalMarginWidth ; Add margin back on
		
		return {"WIDTH":editWidth, "HEIGHT":editHeight}
	}
	
	calcMaxSize(available, pieceSize, numPieces) {
		; The size this would be if we didn't scroll
		possibleSize := numPieces * pieceSize
		
		; If it already fits within the available space, no problem.
		if(possibleSize <= available)
			return possibleSize
		
		; Otherwise we'll need to show a smaller size and scroll.
		numPiecesToShow := available // pieceSize
		return numPiecesToShow * pieceSize
	}
	
	mouseIsOverEditField() {
		MouseGetPos("", "", windowUnderMouse, varNameUnderMouse)
		if(windowUnderMouse != this.guiId)
			return false
		
		controlUnderMouse := GuiControlGet(this.guiId ":Name", varNameUnderMouse)
		return (controlUnderMouse = this.editFieldVar)
	}
	
	createAndShowPopup(editSizes, table) {
		; Create gui
		guiProperties .= "+Label" this.Prefix_GuiSpecialLabels ; DebugPopupGui_* functions instead of Gui*
		guiProperties .= " -" MicrosoftLib.Style_CaptionHead   ; No title bar
		Gui, New, % guiProperties, % "Debug Info"
		
		; Store off window ID, initialize edit field variable
		Gui, +HWNDguiId
		this.guiId := guiId
		this.editFieldVar := this.guiId "DebugEdit"
		GuiLib.createDynamicGlobal(this.editFieldVar)
		
		; Apply margins and colors
		Gui, Margin, 0, 0
		Gui, Color, % this.BackgroundColor
		Gui, Font, % "c" this.FontColor " s" this.FontSize, % this.FontName
		
		; Create and focus edit control (holds everything we display)
		editProperties := "ReadOnly -WantReturn -E" MicrosoftLib.ExStyle_SunkenBorder ; Read-only, don't consume {Enter} keystroke, no thick border
		editProperties .= " -VScroll -HScroll -Wrap w" editSizes["WIDTH"] " h" editSizes["HEIGHT"] ; No scrollbars, no wrapping, specific width/height
		editProperties .= " v" this.editFieldVar
		Gui, Add, Edit, % editProperties, % table.getText()
		GuiControl, Focus, % this.editFieldVar
		
		; Add hidden button to respond to {Enter} keystroke (because it's Default)
		Gui, Add, Button, Hidden Default x0 y0 gDebugPopupGui_Close ; DebugPopupGui_Close call on activate
		
		; Show the resulting popup and add scrolling hotkeys
		Gui, Show
		this.addScrollHotkeys()
	}
	
	addScrollHotkeys() {
		; Note: using a BoundFunc this way causes a small memory leak - the BoundFunc object is never released until the script exits. That said, it's insignificant enough that it shouldn't matter in practice, especially for a debug popup.
		mouseIsOverEditField := ObjBindMethod(this, "mouseIsOverEditField")
		Hotkey, If, % mouseIsOverEditField
		
		scrollUp   := ObjBindMethod(this, "scrollUp")
		scrollDown := ObjBindMethod(this, "scrollDown")
		Hotkey, WheelUp,    % scrollUp
		Hotkey, WheelDown,  % scrollDown
		scrollUpPrecise   := ObjBindMethod(this, "scrollUp",   1) ; GDB TODO would it be overkill to functionalize these two scroll hotkey blocks? Probably pass in WheelUp/+WheelUp + "scrollUp","scrollDown"/"scrollLeft","scrollRight"
		scrollDownPrecise := ObjBindMethod(this, "scrollDown", 1)
		Hotkey, ^WheelUp,   % scrollUpPrecise
		Hotkey, ^WheelDown, % scrollDownPrecise
		
		scrollLeft  := ObjBindMethod(this, "scrollLeft")
		scrollRight := ObjBindMethod(this, "scrollRight")
		Hotkey, +WheelUp,    % scrollLeft
		Hotkey, +WheelDown,  % scrollRight
		scrollLeftPrecise  := ObjBindMethod(this, "scrollLeft",  1)
		scrollRightPrecise := ObjBindMethod(this, "scrollRight", 1)
		Hotkey, +^WheelUp,   % scrollLeftPrecise
		Hotkey, +^WheelDown, % scrollRightPrecise
		
		Hotkey, If
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
	
	; Scroll in specific directions - by default, 3 lines up/down and 10 characters left/right.
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
