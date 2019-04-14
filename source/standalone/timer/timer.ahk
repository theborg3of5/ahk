#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)
setUpTrayIcons("hourglass.ico", "", "AHK: Timer")

global toastObj
global durationObj
global timerLabelText

; Get any inputs from command line
argsAry := getScriptArgs()
durationString := argsAry[1]
labelText      := argsAry[2]

if(!getTimerInfo(durationString, labelText))
	ExitApp

; DEBUG.popup("durationString",durationString, "durationObj",durationObj, "durationObj.hours",durationObj.hours, "durationObj.minutes",durationObj.minutes, "durationObj.seconds",durationObj.seconds, "durationObj.displayTime",durationObj.displayTime)

; Set up Toast and show initial time
toastObj := buildTimerToast()
toastObj.showPersistent(WINPOS_X_Right, WINPOS_Y_Top)

; Start ticking once per second
SetTimer, decrementTimer, 1000
setScriptConfirmQuit() ; Confirm before exiting on !+x.

; Hide Toast after 3 seconds
Sleep, 3000 ; Sleep instead of timers so we can block temp-show hotkey until we're hiding
toastObj.hide()

return


; Show timer for 3 seconds, then hide it again
~^!Space::
	toastObj.showPersistent()
	waitForHotkeyRelease()
	Sleep, 3000
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
	s := new Selector("timer.tls")
	infoAry := s.selectGui()
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
	displayText  := getTimerDisplayText()
	overridesAry := getToastStyleOverrides("Right") ; Right-aligned (for displaying time)
	return new Toast(displayText, overridesAry)
}

;---------
; DESCRIPTION:    Get the text to display in the toast display, taking into account any labels and
;                 the time.
; RETURNS:        <label if set + newline><time>
;---------
getTimerDisplayText() {
	displayText := ""
	
	if(timerLabelText != "")
		displayText .= timerLabelText ":`n"
	displayText .= durationObj.displayTime
	
	return displayText
}

;---------
; DESCRIPTION:    Get the style overrides to be used with toast.
; PARAMETERS:
;  labelAlignment (I,OPT) - The alignment of the text in the resulting toast. Defaults to left-aligned.
; RETURNS:        Style overrides array for use with Toast class.
;---------
getToastStyleOverrides(labelAlignment) {
	overridesAry := []
	
	overridesAry["BACKGROUND_COLOR"] := "000000" ; Black
	overridesAry["FONT_COLOR"]       := "00FF00" ; Green
	overridesAry["FONT_SIZE"]        := 40
	overridesAry["MARGIN_X"]         := 15
	overridesAry["MARGIN_Y"]         := 5
	overridesAry["LABEL_STYLES"]     := labelAlignment
	
	return overridesAry
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
	
	setScriptConfirmQuit(false) ; Stop requiring confirmation to exit
	
	; Play a sound to call out that time is up.
	finishedSoundFile := "C:\Windows\media\Windows Hardware Fail.wav"
	if(FileExist(finishedSoundFile))
		SoundPlay, % finishedSoundFile
		
	; Show a persistent "finished" toast in the middle of the screen.
	displayText := "Timer Finished"
	if(timerLabelText != "")
		displayText .= ":`n" timerLabelText
	finishedToast := new Toast(displayText, getToastStyleOverrides("Center"))
	finishedToast.showPersistent(WINPOS_X_Center, WINPOS_Y_Center)
}


#Include <commonHotkeys>
