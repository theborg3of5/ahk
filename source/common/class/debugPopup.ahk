/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Consider adding something (row of dashes/underscores that's the full width, maybe?) to the bottom (and maybe pipes or similar to the right margin?) if it's tall enough to need scrolling.
	
*/ ; =--

class DebugPopup {
	; #PUBLIC#
	
	;  - Constants
	static Prefix_GuiSpecialLabels := "DebugPopupGui_" ; Used to have the gui call DebugPopupGui_* functions instead of just Gui* ones
	static EditField_VarName := "DebugEdit"
	;  - staticMembers
	
	;  - nonStaticMembers
	guiId       := ""
	
	
	mouseIsOverEditField() {
		MouseGetPos("", "", windowUnderMouse, varNameUnderMouse)
		GuiControlGet, mouseName, % this.guiId ":Name", % varNameUnderMouse
		
		return (windowUnderMouse = this.guiId && mouseName = this.EditField_VarName)
	}
	
	
	buildValueDebugString(value) { ; GDB TODO these should move back into Debug when we're ready
		; Base case - not a complex object, just return the value to show.
		if(!isObject(value))
			return value
		
		; For objects, compile child values
		builder := new DebugBuilder2()
		if(isFunc(value.Debug_ToString)) { ; If an object has its own debug logic, use that rather than looping.
			value.Debug_ToString(builder)
		} else {
			For subIndex,subVal in value
				builder.addLine(subIndex, subVal)
		}
		childBlock := builder.toString()
		if(childBlock != "") ; Child block should be indented, all together
			childBlock := StringLib.indentBlock(childBlock, 2)
		
		; Final value is the name followed by the (indented) block of children on the next line.
		objName := this.getObjectName(value)
		return objName.appendLine(childBlock)
	}
	
	convertParamsToPaired(params*) {
		pairedParams := []
		
		Loop, % params.MaxIndex() // 2 {
			key   := params[A_Index * 2 - 1]
			value := params[A_Index * 2]
			pairedParams.Push({"LABEL":key, "VALUE":value})
		}
		
		return pairedParams
	}

	getObjectName(value) {
		; If an object has its own name specified, use it.
		if(isFunc(value.Debug_TypeName))
			return value.Debug_TypeName() " {}"
			
		; For other objects, just use a generic "Array"/"Object" label and add the number of elements.
		if(value.isArray)
			return "Array (" value.count() ")"
		return "Object (" value.count() ")"
	}
	
	
; Edit width = 9*numChars + 13
	
	;  - properties
	;  - __New()/Init()
	__New(params*) { ; GDB TODO take it variadic parameters and turn them into a dataTable for TextTable
		
		
		global DebugEdit := 5 ; GDB TODO do this nicer, probably with a unique, incrementing value like SelectorGui does
		
		; GDB TODO move all of these to constants
		fontSize := 12 ; 12pt
		fontName := "Consolas"
		editLineHeight := 19 ; For size 12 Consolas
		charWidth := 9
		
		editTotalMarginWidth := 8 ; How much extra space the edit control needs to cut off at character edges
		
		backgroundColor := "2A211C"
		fontColor := "BDAE9D"
		
		
		
		paramPairs := this.convertParamsToPaired(params*)
		
		tt := new TextTable()
		For _,row in paramPairs {
			tt.addRow(row["LABEL"] ":", this.buildValueDebugString(row["VALUE"]))
		}
		
		message := tt.generateText()
		lineWidth := tt.getWidth()
		numLines := message.countMatches("`n") + 1
		
		
		
		
		
		workArea := WindowLib.getMonitorWorkArea()
		
		needVScroll := false
		needHScroll := false
		
		; 90% of available height/width so we're not right up against the edges
		availableHeight := workArea["HEIGHT"] * 0.9
		availableWidth  := workArea["WIDTH"]  * 0.9
		
		possibleHeight := (editLineHeight * numLines)
		if(possibleHeight > availableHeight) {
			numLinesToShow := availableHeight // editLineHeight
			needVScroll := true
		} else {
			numLinesToShow := numLines
		}
		editHeight := (editLineHeight * numLinesToShow)
		
		; GDB TODO this whole block seems like a good function - "find max possible size based on max + margin + increments)
		possibleWidth := (lineWidth * charWidth) + editTotalMarginWidth
		if(possibleWidth > availableWidth) {
			numCharsToShow := (availableWidth - editTotalMarginWidth) // charWidth
			needHScroll := true
		} else {
			numCharsToShow := lineWidth
		}
		editWidth := (numCharsToShow * charWidth) + editTotalMarginWidth
		
		; Debug.popup("numCharsToShow",numCharsToShow, "numCharsToShow*charWidth",numCharsToShow*charWidth, "editLeftPaddingBuiltIn",editLeftPaddingBuiltIn, "needHScroll",needHScroll, "editWidth",editWidth, "fullWidth",fullWidth)
		
		
		if(needVScroll) {
			numDashes := lineWidth - 2
			edgeText := "+" StringLib.duplicate("-", lineWidth - 2)
			if(!needHScroll)
				edgeText .= "+"
			
			message := edgeText "`n" message "`n" edgeText
		}
		if(needHScroll) {
			newMessage := ""
			Loop, Parse, message, "`n"
			{
				if(A_Index = 1 || A_Index = (message.countMatches("`n") + 1))
					line := "+" A_LoopField "+"
				else
					line := "|" A_LoopField "|"
				
				newMessage := newMessage.appendLine(line)
			}
			message := newMessage
		}
		
		
		
		Gui, New, % "+HWNDguiId +Label" this.Prefix_GuiSpecialLabels ; guiId := gui's window handle, DebugPopupGui_* functions instead of Gui*
		this.guiId := guiId
		
		Gui, Margin, 5, 5
		Gui, Color, % backgroundColor
		Gui, Font, % "c" fontColor " s" fontSize, % fontName
		
		editProperties := "ReadOnly -WantReturn -E0x200 -VScroll -Wrap v" this.EditField_VarName " h" editHeight " w" editWidth
		Gui, Add, Edit, % editProperties, % message
		
		if(needHScroll) {
			; To vertically center, we need to add enough newlines to shift the arrows down.
			numTopNewlines := (numLinesToShow - 2) // 2 ; 2 for arrows themselves, half for just top
			arrowsText := StringLib.getNewlines(numTopNewLines) Chr(0x25C0) "`n" Chr(0x25B6) ; ◀ `n ▶ (Extra for Notepad++: ●)
			Gui, Add, Text, x+1 hp Center +BackgroundTrans h%editHeight%, % arrowsText ; GDB TODO 0 to named variable?
		}
		
		if(needVScroll) {
			arrowsText := Chr(0x25B2) " " Chr(0x25BC) ; ▲ ▼
			Gui, Add, Text, xm y+0 Center +BackgroundTrans w%editWidth%, % arrowsText ; GDB TODO 0 to named variable?
		}
		
		
		
		Gui, Font ; Restore font to default
		
		
		Gui, Add, Button, Hidden Default gDebugPopupGui_Close x0 y0 ; DebugPopupGui_Close call on click/activate
		
		Gui, -MinimizeBox -MaximizeBox  ;+0x800000 ; 0x800000=WS_BORDER ; -0x400000 ; 0x400000=WS_DLGFRAME +ToolWindow
		GuiControl, Focus, % this.EditField_VarName
		
		; guiWidth := editWidth + 10
		; Gui, Show, % "w" guiWidth, Debug Info
		Gui, Show, , Debug Info
		
		Gui, +LastFound
		
		; WinGetPos, , , winWidth, winHeight
		; Debug.popup("numLines",numLines, "winWidth",winWidth, "winHeight",winHeight, "workArea",workArea)
		
		
		mouseIsOverEditField := ObjBindMethod(this, "mouseIsOverEditField")
		Hotkey, If, % mouseIsOverEditField
		; Hotkey, IfWinActive, % "ahk_id " guiId
		if(needVScroll) {
			scrollUp    := ObjBindMethod(this, "scrollUp")
			scrollDown  := ObjBindMethod(this, "scrollDown")
			Hotkey, ~WheelUp,   % scrollUp
			Hotkey, ~WheelDown, % scrollDown
		}
		if(needHScroll) {
			scrollLeft  := ObjBindMethod(this, "scrollLeft")
			scrollRight := ObjBindMethod(this, "scrollRight")
			Hotkey, ~+WheelUp,   % scrollLeft
			Hotkey, ~+WheelDown, % scrollRight
		}
		Hotkey, If
		; Hotkey, IfWinActive
		
		; WinWaitClose
		
		; GDB TODO do we need to disable the hotkeys when we close? (only if they exist, though - either check if the hotkeys exist, or just use needVScroll/needHScroll)
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
	;  - otherFunctions
	scrollUp() { ; GDB TODO should these specific send-message commands just live in MicrosoftLib?
		SendMessage, 0x115, 0, , Edit1, % "ahk_id " this.guiId ; WM_VSCROLL, SB_LINEUP
	}
	scrollDown() { ; GDB TODO can we use something more specific than Edit1?
		SendMessage, 0x115, 1, , Edit1, % "ahk_id " this.guiId ; WM_VSCROLL, SB_LINEDOWN
	}
	scrollLeft() {
		SendMessage, 0x114, 0, , Edit1, % "ahk_id " this.guiId ; WM_HSCROLL, SB_LINELEFT
	}
	scrollRight() {
		SendMessage, 0x114, 1, , Edit1, % "ahk_id " this.guiId ; WM_HSCROLL, SB_LINERIGHT
	}
	
	
	; #INTERNAL#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #PRIVATE#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	; #END#
}

DebugPopupGui_Close() {
	Gui, Destroy
}




class DebugBuilder2 {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Create a new DebugBuilder instance.
	; PARAMETERS:
	;  numTabs (I,OPT) - How many levels of indentation the string should start at. Added lines will
	;                    be at this level + 1.
	; RETURNS:        Reference to new DebugBuilder object
	;---------
	__New() {
		this.tt := new TextTable().setColumnDivider(" | ")
	}
	
	;---------
	; DESCRIPTION:    Add a properly-indented line* with the given label and value to the output
	;                 string.
	; PARAMETERS:
	;  label (I,REQ) - The label to show for the given value
	;  value (I,REQ) - The value to evaluate and show. Will be treated according to the logic
	;                  described in the DEBUG class (see that class documentation for details).
	; NOTES:          A "line" may actually contain multiple newlines, but anything below the
	;                 initial line will be indented 1 level deeper.
	;---------
	addLine(label, value) {
		this.tt.addRow(label, DebugPopup.buildValueDebugString(value))
		; newLine := Debug.buildDebugStringForPair(label, value, this.numTabs)
		; this.outString := this.outString.appendLine(newLine)
	}
	
	;---------
	; DESCRIPTION:    Retrieve the debug string built by this class.
	; RETURNS:        The string built by this class, in full.
	;---------
	toString() {
		return this.tt.generateText()
	}
	
	
	; #PRIVATE#
	
	tt   := ""  ; How indented our base level of text should be.
	; outString := "" ; Built-up string to eventually return.
	; #END#
}