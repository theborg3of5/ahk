/* A wrapper class around Toast for use in progress displays, which displays one "step" per line and completes them as you add more. =--
	
	Example Usage
;		progToast := new ProgressToast("Optional title")
;		progToast.nextStep("Step 1")
;		progToast.nextStep("Step 2", "Complete!") ; Finish this step's line in the toast with the text "Complete!" instead of the usual "done"
;		progToast.nextStep("Step 3")
;		progToast.endStep("failed") ; Finish Step 3 with a custom message because it errored out
;		progToast.finish("Totally finished!") ; End the toast with a final line of text
	
*/ ; --=

class ProgressToast extends Toast {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Create a new progress toast.
	; PARAMETERS:
	;  title (I,OPT) - Title to show at the top of the toast with a : on the end.
	;---------
	__New(title := "") {
		if(title != "")
			title .= ":"
		
		base.__New(title)
	}
	
	;---------
	; DESCRIPTION:    Display a step with a ... on the end. If there's already a step in progress, finish it using the
	;                 last specified done text.
	; PARAMETERS:
	;  stepText (I,REQ) - The text to show for the new step. Will be added to a new line in the toast.
	;  doneText (I,OPT) - We'll complete this step by adding this text to the end of the line. Defaults to "done".
	; SIDE EFFECTS:   Shows the toast if this is the first step, and finishes the previous step if one is in progress.
	;---------
	nextStep(stepText, doneText := "done") {
		this.finishInProgressStep()
		this.currStepDoneText := doneText
		
		if(!this.isVisible)
			this.addFirstStepAndShow(stepText "...")
		else
			this.addLine(stepText "...")
	}
	
	;---------
	; DESCRIPTION:    Finish the current step with a custom message. Useful if a step errored out and you don't want to
	;                 show a normal doneText.
	; PARAMETERS:
	;  endText (I,REQ) - The custom text to finish the step with (goes after the ellipsis).
	;---------
	endStep(endText) {
		this.currStepDoneText := endText
		this.finishInProgressStep()
	}
	
	;---------
	; DESCRIPTION:    Finish this progress display and fade the toast out shortly after.
	; PARAMETERS:
	;  finishText (I,OPT) - The text to display as the final line in the toast, to say that we're finished. Defaults to "Finished!".
	; SIDE EFFECTS:   Hides the toast after a medium timeout.
	; NOTES:          If you're finishing just before ending a script, you can call .blockingOn() any time before this to
	;                 make the toast-fade out use Sleep instead of a timer, to ensure the script waits until the toast is
	;                 done showing before exiting.
	;---------
	finish(finishText := "Finished!") {
		this.finishInProgressStep()
		
		this.addLine(finishText)
		this.showForSeconds(2)
	}
	
	
	; #PRIVATE#
	
	isVisible := false ; Whether we've shown the toast yet.
	currStepDoneText := "" ; The text to use to finish the currently-running step.
	
	;---------
	; DESCRIPTION:    Add the first step to the toast and make the toast visible.
	; PARAMETERS:
	;  stepText (I,REQ) - The text of the step to add.
	;---------
	addFirstStepAndShow(stepText) {
		title := this.getCurrentText() ; If there's already text, it must be the title
		this.setLabelText(title.appendLine(stepText)) ; Doesn't move or show the toast, unlike .setText()
		
		this.show(VisualWindow.X_LeftEdge, VisualWindow.Y_BottomEdge)
		this.isVisible := true
	}
	
	;---------
	; DESCRIPTION:    If there is a step in progress, finish it by adding the proper text to the end of that line.
	;---------
	finishInProgressStep() {
		; No step in progress
		if(!this.getCurrentText().endsWith("..."))
			return
		
		doneText := this.currStepDoneText.removeFromEnd("...") ; Make sure the done text doesn't end with our separator, otherwise we could keep finishing it forever
		this.appendText(doneText)
	}
	; #END#
}
