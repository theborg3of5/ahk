/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
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
	
	;  - properties
	;  - __New()/Init()
	__New(dataTable) { ; GDB TODO take it variadic parameters and turn them into a dataTable for TextTable
		
		
		global DebugEdit := 5 ; GDB TODO do this nicer, probably with a unique, incrementing value like SelectorGui does
		
		; GDB TODO move all of these to constants
		fontSize := 12 ; 12pt
		fontName := "Consolas"
		editLineHeight := 19 ; For size 12 Consolas
		charWidth := 9
		
		editTotalMarginWidth := 8 ; How much extra space the edit control needs to cut off at character edges
		
		backgroundColor := "2A211C"
		fontColor := "BDAE9D"
		
		
		; tt := new TextTable(dataTable).setColumnPadding(4)
		; message := tt.generateText()
		; lineWidth := tt.getWidth()
		
		; message := "
			; ( LTrim0
; Alpha:    alpha
; Beta:     beta
; Cee:      cee
; Delta:    Selector {}
            ; [DeltaOne  ] delta1                          
            ; [DeltaTwo  ] delta2                          
            ; [DeltaThree] TableList {}
                            ; [DeltaThreeAlpha] delta3alpha
                            ; [DeltaThreeBeta ] delta3beta
; Epsilon:  Array (3)
            ; [1 ] epsilon1
            ; [2 ] episolon2
            ; [3 ] epsilon3
            ; [10] episolon10
; )"

		message := "
			( LTrim0
Alpha:    alpha
Beta:     beta
Cee:      cee
Delta:    Selector {}
            DeltaOne   | delta1                          
            DeltaTwo   | delta2                          
            DeltaThree | TableList {}
                            DeltaThreeAlpha | delta3alpha
                            DeltaThreeBeta  | delta3beta
Epsilon:  Array (3)
            1  | epsilon1
            2  | episolon2
            3  | epsilon3
            10 | episolon10
)"

		; message := "
			; ( LTrim0
; Alpha:    alpha
; Beta:     beta
; Cee:      cee
; Delta:    Selector {}
            ; DeltaOne   = delta1                          
            ; DeltaTwo   = delta2                          
            ; DeltaThree = TableList {}
                            ; DeltaThreeAlpha = delta3alpha
                            ; DeltaThreeBeta  = delta3beta
; Epsilon:  Array (3)
            ; 1  = epsilon1
            ; 2  = episolon2
            ; 3  = epsilon3
            ; 10 = episolon10
; )"

		; message := "
			; ( LTrim0
; Alpha:    alpha
; Beta:     beta
; Cee:      cee
; Delta:    {Selector}
           ; - [DeltaOne]    delta1
           ; - [DeltaTwo]    delta2
           ; - [DeltaThree]  {TableList}
                            ; - [DeltaThreeAlpha] delta3alpha
                            ; - [DeltaThreeBeta]  delta3beta
; Epsilon:  Array (3)
           ; - [1]   epsilon1
           ; - [2]   episolon2
           ; - [3]   epsilon3
           ; - [10]  episolon10
; )"

		; message := "
			; ( LTrim0
; Alpha:    alpha
; Beta:     beta
; Cee:      cee
; Delta:    {Selector}
           ; - DeltaOne:   delta1
           ; - DeltaTwo:   delta2
           ; - DeltaThree: {TableList}
                          ; - DeltaThreeAlpha: delta3alpha
                          ; - DeltaThreeBeta:  delta3beta
; Epsilon:  Array (3)
           ; - 1:  epsilon1
           ; - 2:  episolon2
           ; - 3:  epsilon3
           ; - 10: episolon10
; )"

		; message := "
			; ( LTrim0
; Alpha:    alpha
; Beta:     beta
; Cee:      cee
; Delta:    {Selector}
            ; DeltaOne:   delta1
            ; DeltaTwo:   delta2
            ; DeltaThree: {TableList}
                          ; DeltaThreeAlpha: delta3alpha
                          ; DeltaThreeBeta:  delta3beta
; Epsilon:  Array (3)
            ; 1:  epsilon1
            ; 2:  episolon2
            ; 3:  epsilon3
            ; 10: episolon10
; )"

		lineWidth := 58
		
		
		
		; Debug.popup("message",message, "tt.getWidth()",tt.getWidth())
		
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
		
		Gui, -MinimizeBox -MaximizeBox +ToolWindow
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
