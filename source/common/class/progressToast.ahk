/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Could left-align it so "Done" additions don't make things jump
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

/*
	t := new Toast("Extracting data from scripts...").show()
	
	t.appendText("Done")


	t.addLine("Updating auto-complete file (both versions)...")

	t.appendText("Done")


	t.addLine("Updating syntax highlighting file...")

	t.appendText("Done (requires restart)")

	t.addLine("Complete!").blockingOn().showMedium()
*/

class ProgressToast extends Toast {
	; #PUBLIC#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - properties
	;  - __New()/Init()
	__New(title := "") { ; GDB TODO figure out what to do with this
		if(title != "")
			title .= ":"
		
		base.__New(title)
	}
	
	;  - otherFunctions
	
	startStep(stepText, doneText := "Done") {
		this.finishInProgressStep()
		this.stepDoneText := doneText
		
		if(!this.isVisible)
			this.addFirstStepAndShow(stepText "...")
		else
			this.addLine(stepText "...")
	}
	
	
	finish() {
		this.finishInProgressStep()
		
		this.addLine("Finished!")
		; this.blockingOn() ; GDB TODO would it make more sense to leave this up to the caller, either as a chained call (.blockingOn().finish()) or a parameter?
		this.showMedium()
	}
	
	
	; #PRIVATE#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	isVisible := false
	stepDoneText := ""
	
	;  - functions
	
		; Special case for the first step: set the text directly before we show the toast, so it can fade in
		; nicely and in the right size/position.
	addFirstStepAndShow(stepText) {
		title := this.getCurrentText() ; If there's already text, it must be the title
		this.setLabelText(title.appendLine(stepText)) ; Doesn't move or show the text
		
		this.show(VisualWindow.X_LeftEdge, VisualWindow.Y_BottomEdge)
		this.isVisible := true
	}
	
	finishInProgressStep() {
		; No step in progress
		if(!this.getCurrentText().endsWith("..."))
			return
		
		doneText := this.stepDoneText.removeFromEnd("...") ; Make sure the done text doesn't end with our separator, otherwise we could keep finishing it forever
		this.appendText(doneText)
	}
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "GDB TODO"
	}
	
	Debug_ToString(ByRef table) {
		table.addLine("GDB TODO", this.GDBTODO)
	}
	; #END#
}
