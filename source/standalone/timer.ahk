; Shows a persistent timer that counts down, fades out of view, and shows on hotkey.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Timer", "hourglass.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
CommonHotkeys.noSuspendOn()

global toastObj
global durationObj
global timerLabelText

; Get any inputs from command line
durationString := A_Args.RemoveAt(1)
Loop, % A_Args.Length() {
	labelText := labelText.appendPiece(" ", A_Args[A_Index])
}

if(!getTimerInfo(durationString, labelText))
	ExitApp

; Debug.popup("durationString",durationString, "durationObj",durationObj, "durationObj.hours",durationObj.hours, "durationObj.minutes",durationObj.minutes, "durationObj.seconds",durationObj.seconds, "durationObj.displayTime",durationObj.displayTime)

; Set up Toast and show initial time
toastObj := buildTimerToast()
toastObj.show(VisualWindow.X_RightEdge "-10", VisualWindow.Y_TopEdge "+10")

; Start ticking once per second
SetTimer, decrementTimer, 1000

; Confirm before exiting with common close hotkey (!+x)
CommonHotkeys.confirmExitOn("Stop the timer and exit?")

; Block until toast hides (3 seconds), so temp-show hotkey can't fire until it's hidden
toastObj.blockingOn().showForSeconds(3).blockingOff()
return


; Show timer for 3 seconds, then hide it again
~^!Space::
	toastObj.show()
	HotkeyLib.waitForRelease()
	Sleep, 3000 ; Use sleep instead of toastObj.showForSeconds() so toast doesn't hide until the hotkey is released.
	toastObj.hide()
return

;---------
; DESCRIPTION:    Gather the info we need to start the timer.
; PARAMETERS:
;  durationString (I,REQ) - String valid for creating a new Duration object.
;  labelText      (I,OPT) - Label to show with the timer.
; RETURNS:        true if we got the info we needed, false otherwise.
; SIDE EFFECTS:   Sets globals durationObj and timerLabelText
;---------
getTimerInfo(durationString, labelText) {
	; First try using the duration string we were given.
	dur := New Duration(durationString)
	if(!dur.isZero) {
		durationObj    := dur
		timerLabelText := labelText
		return true
	}
	
	; If that wasn't sucessful, prompt the user (with a Selector popup) for the duration (and optionally the label).
	s := new Selector().setTitle("Timer duration").addOverrideFields({ 1:"DURATION_STRING", 2:"LABEL" })
	s.addChoice(new SelectorChoice({ NAME:"5 minutes" , ABBREV:"5m"  , DURATION_STRING:"5m"   }))
	s.addChoice(new SelectorChoice({ NAME:"10 minutes", ABBREV:"10m" , DURATION_STRING:"10m"  }))
	s.addChoice(new SelectorChoice({ NAME:"15 minutes", ABBREV:"15m" , DURATION_STRING:"15m"  }))
	s.addChoice(new SelectorChoice({ NAME:"20 minutes", ABBREV:"20m" , DURATION_STRING:"20m"  }))
	s.addChoice(new SelectorChoice({ NAME:"30 minutes", ABBREV:"30m" , DURATION_STRING:"30m"  }))
	s.addChoice(new SelectorChoice({ NAME:"45 minutes", ABBREV:"45m" , DURATION_STRING:"45m"  }))
	s.addChoice(new SelectorChoice({ NAME:"1 hour"    , ABBREV:"1h"  , DURATION_STRING:"1h"   }))
	s.addChoice(new SelectorChoice({ NAME:"1.5 hours" , ABBREV:"1.5h", DURATION_STRING:"1.5h" }))
	
	infoAry := s.prompt()
	if(!infoAry)
		return false
	durationString := infoAry["DURATION_STRING"]
	labelText      := infoAry["LABEL"]
	
	; Try again with user input.
	dur := New Duration(durationString)
	if(!dur.isZero) {
		durationObj    := dur
		timerLabelText := labelText
		return true
	}
		
	return false
}

;---------
; DESCRIPTION:    Build the toast that will show the time.
; RETURNS:        New Toast object to show the time in.
;---------
buildTimerToast() {
	displayText := getTimerDisplayText()
	overrides := getToastStyleOverrides("Right") ; Right-aligned (for displaying time)
	return new Toast(displayText, overrides).persistentOn()
}

;---------
; DESCRIPTION:    Get the text to display in the toast display, taking into account any labels and
;                 the time.
; RETURNS:        <label if set + newline><time>
;---------
getTimerDisplayText() {
	displayText := ""
	
	displayText .= durationObj.displayTime
	if(timerLabelText != "")
		displayText := displayText.appendLine("[" timerLabelText "]")
	
	return displayText
}

;---------
; DESCRIPTION:    Get the style overrides to be used with toast.
; PARAMETERS:
;  labelAlignment (I,OPT) - The alignment of the text in the resulting toast. Defaults to left-aligned.
; RETURNS:        Style overrides for use with Toast class.
;---------
getToastStyleOverrides(labelAlignment) {
	overrides := {}
	
	overrides["BACKGROUND_COLOR"] := "000000" ; Black
	overrides["FONT_COLOR"]       := "00FF00" ; Green
	overrides["FONT_SIZE"]        := 40
	overrides["MARGIN_X"]         := 15
	overrides["MARGIN_Y"]         := 5
	overrides["TEXT_ALIGN"]       := labelAlignment
	
	return overrides
}

;---------
; DESCRIPTION:    Take 1 second away from the timer and update the toast accordingly.
; SIDE EFFECTS:   When the timer is finished this will trigger its completion logic.
;---------
decrementTimer() {
	durationObj.subTime(1)
	toastObj.setText(getTimerDisplayText())
	
	if(durationObj.isZero)
		finishTimer()
}

;---------
; DESCRIPTION:    Finish the timer: play a sound and display a centered toast.
; SIDE EFFECTS:   Destroys timer toast, stops requiring confirmation to exit with !+x hotkey.
;---------
finishTimer() {
	SetTimer, , Off ; Stop ticking
	toastObj.close()
	
	; Stop requiring confirmation to exit
	CommonHotkeys.confirmExitOff()
	
	; Play a sound to call out that time is up.
	finishedSoundFile := Config.replacePathTags("<WINDOWS>\media\Windows Hardware Fail.wav")
	if(FileExist(finishedSoundFile))
		SoundPlay, % finishedSoundFile
		
	; Show a persistent "finished" toast in the middle of the screen.
	displayText := "Timer Finished"
	if(timerLabelText != "")
		displayText .= ":`n" timerLabelText
	finishedToast := new Toast(displayText, getToastStyleOverrides("Center"))
	finishedToast.show(VisualWindow.X_Centered, VisualWindow.Y_Centered)
}
