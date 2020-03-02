/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
		Consider going back to a ToolWindow - could add a title at the top (embedded in the top border) using new topBorder option for TextTable
	
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
		objName := this.getObjectName(value)
		builder := new DebugBuilder2()
		if(isFunc(value.Debug_ToString)) { ; If an object has its own debug logic, use that rather than looping.
			value.Debug_ToString(builder)
			tt := builder.tt
		} else {
			if(value.count() = 0)
				return objName
			
			tt := new TextTable()
			
			For subIndex,subVal in value
				tt.addRow(subIndex ":", DebugPopup.buildValueDebugString(subVal))
		}
		
		tt.setBorderType(TextTable.BorderType_Line)
		tt.setTopTitle(objName)
		if(tt.getHeight() >= 50)
			tt.setBottomTitle(objName)
		
		childBlock := tt.generateText()
		return childBlock
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
			return value.Debug_TypeName()
			
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
		
		backgroundColor := "444444"
		fontColor := "00FF00"
		
		paramPairs := this.convertParamsToPaired(params*)
		
		tt := new TextTable().setTopTitle("Debug Info").setBorderType(TextTable.BorderType_BoldLine)
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
		
		
		
		Gui, New, % "+HWNDguiId +Label" this.Prefix_GuiSpecialLabels ; guiId := gui's window handle, DebugPopupGui_* functions instead of Gui*
		this.guiId := guiId
		
		Gui, Margin, 0, 0
		Gui, Color, % backgroundColor
		Gui, Font, % "c" fontColor " s" fontSize, % fontName
		
		editProperties := "ReadOnly -WantReturn -E0x200 -VScroll -Wrap v" this.EditField_VarName " h" editHeight " w" editWidth
		Gui, Add, Edit, % editProperties, % message
		
		
		Gui, Font ; Restore font to default
		
		
		Gui, Add, Button, Hidden Default gDebugPopupGui_Close x0 y0 ; DebugPopupGui_Close call on click/activate
		
		Gui, -MinimizeBox -MaximizeBox -0x400000 ; 0x400000=WS_DLGFRAME +ToolWindow ;+0x800000 ; 0x800000=WS_BORDER ;
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
			scrollUp   := ObjBindMethod(this, "scrollUp",   3)
			scrollDown := ObjBindMethod(this, "scrollDown", 3)
			Hotkey, ~WheelUp,    % scrollUp
			Hotkey, ~WheelDown,  % scrollDown
			
			scrollUpPrecise   := ObjBindMethod(this, "scrollUp",   1)
			scrollDownPrecise := ObjBindMethod(this, "scrollDown", 1)
			Hotkey, ~^WheelUp,   % scrollUpPrecise
			Hotkey, ~^WheelDown, % scrollDownPrecise
		}
		if(needHScroll) {
			scrollLeft  := ObjBindMethod(this, "scrollLeft",  10)
			scrollRight := ObjBindMethod(this, "scrollRight", 10)
			Hotkey, ~+WheelUp,    % scrollLeft
			Hotkey, ~+WheelDown,  % scrollRight
			
			scrollLeftPrecise  := ObjBindMethod(this, "scrollLeft",  1)
			scrollRightPrecise := ObjBindMethod(this, "scrollRight", 1)
			Hotkey, ~+^WheelUp,   % scrollLeftPrecise
			Hotkey, ~+^WheelDown, % scrollRightPrecise
		}
		Hotkey, If
		; Hotkey, IfWinActive
		
		; WinWaitClose
		
		; GDB TODO do we need to disable the hotkeys when we close? (only if they exist, though - either check if the hotkeys exist, or just use needVScroll/needHScroll)
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
	;  - otherFunctions
	scrollUp(numLines := 1) { ; GDB TODO should these specific send-message commands just live in MicrosoftLib?
		Loop, % numLines
			SendMessage, 0x115, 0, , Edit1, % "ahk_id " this.guiId ; WM_VSCROLL, SB_LINEUP
	}
	scrollDown(numLines := 1) { ; GDB TODO can we use something more specific than Edit1?
		Loop, % numLines
			SendMessage, 0x115, 1, , Edit1, % "ahk_id " this.guiId ; WM_VSCROLL, SB_LINEDOWN
	}
	scrollLeft(numLines := 1) {
		Loop, % numLines
			SendMessage, 0x114, 0, , Edit1, % "ahk_id " this.guiId ; WM_HSCROLL, SB_LINELEFT
	}
	scrollRight(numLines := 1) {
		Loop, % numLines
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
		this.tt := new TextTable() ;.setBorderType(TextTable.BorderType_Line) ;.setColumnDivider(" " Chr(0x2502) " ")
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
		this.tt.addRow(label ":", DebugPopup.buildValueDebugString(value))
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