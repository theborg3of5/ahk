/* A dynamically-sized, scrollable, copyable popup of information in a monospace font.
      The popup does not use scrollbars, but still responds to mouse wheel events:
         * Wheel                - scroll vertically
         * Ctrl + Wheel         - scroll vertically one line at a time
         * Shift + Wheel        - scroll horizontally
         * Ctrl + Shift + Wheel - scroll horizontally one character at a time
      It will resize itself to its contents up to 90% of the current screen's size, at which point it will scroll.
   
   Example Usage
;		tt := new TextTable()
;		tt.addRow("val1", "val2", "val3")
;		tt.addRow("value4", "value5", "value6")
;     new TextPopup(tt) ; Results in a popup with this text: val1    val2    val3  
;		                                                       value4  value5  value6
*/

class TextPopup {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Build and show a new popup, where the content comes from a TextTable.
	; PARAMETERS:
	;  table (I,REQ) - A TextTable instance containing the content to show in the popup. We'll use it to show the desired
	;                  content + determine the popup size.
	;---------
	__New(table) {
		; Tell the table to have a nice thick outer border
		table.setBorderType(TextTable.BorderType_BoldLine)
		
		; Set up and show popup
		editSizes := this.calculateEditDimensions(table)
		this.guiId := this.createPopup(editSizes, table)
	}
	
	;---------
	; DESCRIPTION:    Show the popup and pause until it closes.
	;---------
	show() {
		Gui, % this.guiId ":Show"
		
		; Wait for it to close (pausing the current script until that happens)
		WinWaitClose, % "ahk_id " this.guiId
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	;  - Constants
	static Prefix_GuiSpecialLabels := "TextPopupGui_" ; Used to have the gui call TextPopupGui_* functions instead of just Gui* ones
	static Edit_ControlId := "Edit1"
	
	static BackgroundColor       := "444444"
	static FontColor             := "00FF00"
	static FontName              := "Consolas"
	static FontSize              := 12 ; In points
	static Edit_LineHeight       := 19 ; How many px tall each line is in the edit control
	static Edit_CharWidth        := 9  ; How many px wide each character is in the edit control
	static Edit_TotalMarginWidth := 8  ; How much extra space the edit control needs to cut off at character edges
	
	guiId        := "" ; Gui's window handle
	editFieldVar := "" ; Unique ID for edit field, based on this.guiId
	
	;---------
	; DESCRIPTION:    Calculate the width and height of the edit field based on the content of the given TextTable.
	; PARAMETERS:
	;  table (I,REQ) - The TextTable that will provide our content.
	; RETURNS:        The size that the edit field should be, sized so that we don't cut off in the middle of a character or line.
	;                    ["WIDTH"]
	;                    ["HEIGHT"]
	;---------
	calculateEditDimensions(table) {
		; Use a maxiumum of 90% of available height/width so we're not right up against the edges
		workArea := MonitorLib.getWorkAreaForWindow("A")
		availableWidth  := workArea["WIDTH"]  * 0.9
		availableHeight := workArea["HEIGHT"] * 0.9
		
		; For width, there's a margin involved - take it out before we call calcMaxSize (as that works on units, characters here) and add it back on afterwards.
		availableWidth -= this.Edit_TotalMarginWidth
		
		; Calculate edit control height/width and whether we need to scroll
		editHeight := this.calcMaxSize(availableHeight, this.Edit_LineHeight, table.getHeight())
		editWidth  := this.calcMaxSize(availableWidth,  this.Edit_CharWidth,  table.getWidth()) + this.Edit_TotalMarginWidth ; Add margin back on
		
		return {"WIDTH":editWidth, "HEIGHT":editHeight}
	}
	
	;---------
	; DESCRIPTION:    Calculate the max size (in units - typically lines or characters) given a space to fit into and the size of each unit.
	; PARAMETERS:
	;  available (I,REQ) - The total available space that we have to fit into.
	;  pieceSize (I,REQ) - The size of the unit we need to work with.
	;  numPieces (I,REQ) - How many pieces there are total in the content.
	; RETURNS:        The numeric size that's the largest we can get without cutting off a unit in the middle.
	;---------
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
	
	;---------
	; DESCRIPTION:    Generate the gui.
	; PARAMETERS:
	;  editSizes (I,REQ) - The width/height that the edit field needs to be.
	;  table     (I,REQ) - The TextTable of content we want to show in the popup.
	; RETURNS:        The guiId of the new popup (not yet shown)
	;---------
	createPopup(editSizes, table) {
		; Create gui and save off window handle
		Gui, New, +HWNDguiId ; guiId := window handle
		
		; Other gui options
		Gui, % "+Label" this.Prefix_GuiSpecialLabels ; TextPopupGui_* functions instead of Gui*
		Gui, -Caption +Border ; No titlebar/menu, but still have a border
		
		; Apply margins and colors
		Gui, Margin, 0, 0
		Gui, Color, % this.BackgroundColor
		Gui, Font, % "c" this.FontColor " s" this.FontSize, % this.FontName
		
		; Initialize edit field variable
		this.editFieldVar := guiId "TextEdit"
		GuiLib.createDynamicGlobal(this.editFieldVar)
		
		; Create and focus edit control (holds everything we display)
		content := table.getText()
		editProperties := "ReadOnly -WantReturn -E" MicrosoftLib.ExStyle_SunkenBorder ; Read-only, don't consume {Enter} keystroke, no thick border
		editProperties .= " -VScroll -HScroll -Wrap w" editSizes["WIDTH"] " h" editSizes["HEIGHT"] ; No scrollbars, no wrapping, specific width/height
		editProperties .= " v" this.editFieldVar
		Gui, Add, Edit, % editProperties, % content
		GuiControl, Focus, % this.editFieldVar
		
		; Add hidden button to respond to {Enter} keystroke (because it's Default)
		Gui, Add, Button, Hidden Default x0 y0 gTextPopupGui_Close ; TextPopupGui_Close call on activate
		
		; Add hotkeys
		this.addContentHotkeys(guiId, content)
		this.addScrollHotkeys()
		
		return guiId
	}
	
	;---------
	; DESCRIPTION:    Add hotkeys that deal with the entire content of the popup (copy or send over to Notepad++) so the
	;                 user doesn't have to select-all themselves.
	; PARAMETERS:
	;  guiId   (I,REQ) - The GUI ID of the popup, to use to limit where the hotkey triggers.
	;  content (I,REQ) - The full content to use when these hotkeys are triggered.
	;---------
	addContentHotkeys(guiId, content) {
		Hotkey, IfWinActive, % "ahk_id " guiId
		
		; Copy to clipboard
		hotkeyFunction := ObjBindMethod(ClipboardLib, "setAndToast", content, "popup content") ; ClipboardLib.setAndToast
		Hotkey, !c, % hotkeyFunction
		
		; Send to temp file and open in Notepad++
		hotkeyFunction := ObjBindMethod(NotepadPlusPlus, "openTempText", content) ; NotepadPlusPlus.openTempText
		Hotkey, !v, % hotkeyFunction
		
		Hotkey, IfWinActive
	}
	
	;---------
	; DESCRIPTION:    Add scrolling hotkeys to the edit field - since we're hiding scrollbars, scrolling won't work without these.
	;---------
	addScrollHotkeys() {
		; Note: using a BoundFunc this way causes a small memory leak - the BoundFunc object is never released until the script exits. That said, it's insignificant enough that it shouldn't matter much in practice.
		mouseIsOverEditField := ObjBindMethod(this, "mouseIsOverEditField")
		Hotkey, If, % mouseIsOverEditField
		
		; Each direction (up/down/left/right) has 2 hotkeys that go with it - the ones here and the
		; same with Ctrl added, which does a "precise" scroll (1 line/character).
		this.addScrollHotkeySet("WheelUp"   , "scrollUp")
		this.addScrollHotkeySet("WheelDown" , "scrollDown")
		this.addScrollHotkeySet("+WheelUp"  , "scrollLeft")
		this.addScrollHotkeySet("+WheelDown", "scrollRight")
		
		Hotkey, If
	}
	
	;---------
	; DESCRIPTION:    Check whether the mouse is currently over the edit field in this popup. Used for hotkeys.
	; RETURNS:        true/false
	;---------
	mouseIsOverEditField() {
		MouseGetPos("", "", windowUnderMouse, varNameUnderMouse)
		if(windowUnderMouse != this.guiId)
			return false
		
		controlUnderMouse := GuiControlGet(this.guiId ":Name", varNameUnderMouse)
		return (controlUnderMouse = this.editFieldVar)
	}
	
	;---------
	; DESCRIPTION:    Add one set of hotkeys - a normal scroll that moves the default number of
	;                 lines/characters, and a "precise" version that adds Ctrl and scrolls 1
	;                 line/character at a time.
	; PARAMETERS:
	;  hotkeyString (I,REQ) - The hotkey that should trigger this scroll behavior (and that adding
	;                         Ctrl to will scroll "precisely").
	;  methodName   (I,REQ) - The name of the function to trigger when this hotkey is pressed. The
	;                         function should take 1 parameter for how many units to scroll.
	;---------
	addScrollHotkeySet(hotkeyString, methodName) {
		; Basic scrolling hotkey (uses the default scroll amount from the named method)
		scrollMethod := ObjBindMethod(this, methodName)
		Hotkey, % hotkeyString, % scrollMethod
		
		; Precise scrolling hotkey - 1 character or line at a time.
		scrollMethodPrecise := ObjBindMethod(this, methodName, 1)
		Hotkey, % "^" hotkeyString, % scrollMethodPrecise
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
	;endregion ------------------------------ PRIVATE ------------------------------
}


; Close label triggered by the hidden, default button in TextPopup.
TextPopupGui_Close() {
	Gui, Destroy
}
