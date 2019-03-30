#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#Include <includeCommon>
setCommonHotkeysType(HOTKEY_TYPE_Standalone)
setUpTrayIcons("timer.ico", "", "AHK: Timer")

/*
	Desired functionality:
		Input
			Command line: "5h2m33s"-style format
			If nothing on command line (or we couldn't parse to some time >0), selector of choices
				Selector of choices - no good reason to hard-code, just make it a .tls file
					Extra field for just overriding the time with "5h2m33s"-style format
						Column for that field will be how we specify choices, in same format
		Show time (then fade out) on startup
		Show with a hotkey
			Fade in-out (like toast)
			Hide after timer (like a toast - in fact, probably using Toast) 
			Hide immediately on Esc? (only if toast is visible - could be tricky?)
			Make sure text is larger than toast defaults (and maybe retain the green color scheme and additional transparency?)
			Allow holding down show hotkey to keep timer visible
		Pause/resume?
		Add a label (newline'd above remaining time)
		Exit on !+x
			With confirmation (probably a popup instead of hacking around the toast)
		Play sound, center toast, and stop hiding toast on completion
	Other stuff to do/check
		Find attribution for timer icon or replace it, document attribution
		Find attribution for completion sound (from Windows I think?) or replace it, document attribution
			Maybe also find a new completion sound?
*/

; Input from command line
durationString = %1%
if(durationString != "")
	dur := New Duration(durationString)

; If we didn't get something valid from the command line, give the user a list of options
if(!dur || dur.isZero) {
	s := new Selector("timer.tls")
	dur := New Duration(s.selectGui("DURATION_STRING"))
}

if(dur.isZero)
	ExitApp

DEBUG.popup("durationString",durationString, "dur",dur, "dur.hours",dur.hours, "dur.minutes",dur.minutes, "dur.seconds",dur.seconds, "dur.displayTime",dur.displayTime)

t := new Toast(dur.displayTime)
t.show()

Loop, 5 {
	Sleep, 1000
	dur.subTime(1)
	t.setText(dur.displayTime)
}
; DEBUG.popup("dur.isZero",dur.isZero)



Sleep, 5000

ExitApp




freezeDisplay := 0
reallyExit := 0
flashTimerNextTick := true

; Colors and transparency values.
transShown := 230
transHidden := 0
timeColor = 00FF00
backgroundColor = 000000

; The GUI's width changes during execution.
guiWidth := 255
guiMargin := 13
tmpWidth := guiWidth - (guiMargin * 2)

; Initial digit widths for h, m, s. Include colons on h/m.
hDigits := 3
mDigits := 3
sDigits := 2


; Read in command line arguments, figure out how much time we've got left.
if(%0%) {
   commandTime = %1%
} else {
	commandTime := "5m"
}

timeLeft := 0
am_pm := ""
h := 0
m := 0
s := 0

cPos := InStr(commandTime, "`:")
pPos := InStr(commandTime, "p")
aPos := InStr(commandTime, "a")

; We've been given a time - do the math to figure out how much time.
if(cPos > -1 || pPos > -1 || aPos > -1){
	; Grab the am/pm off the end if it's there.
	lastChar := substr(commandTime, 0)
	if(lastChar = "m"){
		am_pm := substr(commandTime, -1, 1)
		commandTime := substr(commandTime, 1, -2)
	} else if(lastChar = "a" || lastChar = "p") {
		am_pm := lastChar
		commandTime := substr(commandTime, 1, -1)
	}
	
	if(cPos > -1){
		; Time has a colon. At this time, we only support a single colon, no seconds on destination.
		hs := substr(commandTime, 1, cPos)
		commandTime := substr(commandTime, 1, -(cPos + 1))
		
		; Assuming minutes are two digits in length if this is a colon'd time.
		ms := substr(commandTime, 1, 2)
		commandTime := substr(commandTime, 1, -2)
	} else {
		; Time is in the form 1p or 1PM for 1:00 PM - the hour should be all that's left.
		hs := commandTime
	}
	
	; We're represening our hours in 24 hour time here.
	if(am_pm = "p" && hs != 12) {
		hs += 12
	}
	
	; Ensure we have two digits for everything for the form needed for EnvSub.
	if(strlen(hs) = 0)
		hs := "00"
	if(strlen(ms) = 0)
		ms := "00"
	; if(strlen(ss) = 0)
		ss := "00"
	if(strlen(hs) = 1)
		hs := "0" . hs
	if(strlen(ms) = 1)
		ms := "0" . ms
	; if(strlen(ss) = 1)
		; ss := "0" . ss
	
	; Subtract the given time from the current one.
	targetTime := A_year A_mon A_mday hs ms ss
	timeLeft := targetTime
	EnvSub, timeLeft, %A_now%, Seconds
	
} else {
	; Hours.
	hPos := InStr(commandTime, "h")
	hs := substr(commandTime, 1, hPos)
	timeLeft += hs * 60 * 60
	commandTime := Substr(commandTime, 1, -(hPos + 1))
	
	; Minutes.
	mPos := InStr(commandTime, "m")
	ms := substr(commandTime, 1, mPos)
	timeLeft += ms * 60
	commandTime := Substr(commandTime, 1, -(mPos + 1))
	
	; Seconds.
	sPos := InStr(commandTime, "s")
	ss := substr(commandTime, 1, sPos)
	timeLeft += ss
}

; MsgBox, % "From command line: `n`nTotal seconds left: " timeLeft "`nHours: " h "`nMinutes: " m "`nSeconds: " s



; Set up the GUI.
SysGet, MonArea, MonitorWorkArea

showX := MonAreaRight - guiWidth
showY := MonAreaBottom - 75

; Get current window, to bring back to the top once we show this.
prevWin := WinGetTitle("A")

; Flesh out the window.
Gui, Color, %backgroundColor%
Gui, +Toolwindow -Resize -SysMenu -Border -Caption +AlwaysOnTop +LastFound
guiID := WinGet("ID")
WinSet, Transparent, %transHidden%

Gui, Font, c%timeColor% s40, Consolas
Gui, Add, Text, x%guiMargin% y10 w%tmpWidth% h50 vTimerText, 00:00:00

; Show it. (and hide it)
Gui, Show, W%guiWidth% H75 X%showX% Y%showY%

; Activate previous window.
WinActivate %prevWin%



; Main timing loop.
while(timeLeft > 0) {
	; Don't update if we're considering exiting, keep the message visible.
	if(!paused) {
		; Update timer text.
		if(freezeDisplay != 1) {
			; Pull hours/mins/secs out of our seconds count.
			seconds := timeLeft

			hours := seconds // 60 // 60
			seconds := seconds - (hours * 60 * 60)

			minutes := seconds // 60
			seconds := seconds - (minutes * 60)

			; MsgBox, %hours%:%minutes%:%seconds%
			
			displayTime := ""
			
			; Hours.
			if(hours = 0) {
				; Don't add an hours portion at all.
				hDigits := 0
			} else {
				if(hours < 10) {
					hDigits := 2 ; Including colon here and below.
				} else {
					hDigits := strlen(hours) + 1
				}
				
				; Pop the hours portion into place.
				displayTime := displayTime . hours . ":"
			}
			
			; Minutes.
			if(minutes = 0) {
				; If there's no hours either, don't show anything but seconds.
				if(hours = 0) {
					mDigits := 0
				} else {
					mDigits := 3
					displayTime := displayTime . "00:"
				}
			} else if(minutes < 10) {
				; 1-digit minute values. Keep extra 0 if (and only if) hours exist.
				if(hours = 0) {
					mDigits := 2
					displayTime := displayTime . minutes . ":"
				} else {
					mDigits := 3
					displayTime := displayTime . "0" . minutes . ":"
				}
			} else {
				; 2-digit minute values.
				mDigits := 3
				displayTime := displayTime . minutes . ":"
			}
			
			; Seconds.
			if(seconds < 10) {
				; 1-digit second values. Keep extra 0 if (and only if) minutes exist.
				if(minutes = 0 && hours = 0) {
					sDigits := 1
					displayTime := displayTime . seconds
				} else {
					sDigits := 2
					displayTime := displayTime . "0" . seconds
				}
			} else {
				; 2-digit second values.
				sDigits := 2
				displayTime := displayTime . seconds
			}
			
			; set guiWidth based on digit widths.
			totalDigits := hDigits + mDigits + sDigits
			
			;MsgBox, %hDigits% %mDigits% %sDigits% %totalDigits%
			;MsgBox, %hours% %minutes% %seconds%
			
			tmpWidth := totalDigits * 29
			guiWidth := tmpWidth + (guiMargin * 2)
			
			showX := MonAreaRight - guiWidth
			showY := MonAreaBottom - 75
			
			Gui, Show, NoActivate W%guiWidth% H75 X%showX% Y%showY%
			
			GuiControl, Text, TimerText, %displayTime%
			GuiControl, Move, TimerText, x%guiMargin% y10 w%tmpWidth% h50
			
			; For at-beginning show of time.
			if(flashTimerNextTick) {
				flashTimerNextTick := false
				showHideTimer()
			}
		}
		
		; Actually tick our time down a notch.
		timeLeft--
	}
	
	; Wait a second.
	Sleep, 1000
}


; Finished, play a sound and hold it!
reallyExit := 1
	
GuiControl, Text, TimerText, Timer Finished
GuiControl, Move, TimerText, x%guiMargin% y10 w500 h50

showX := MonAreaRight - 430
showY := MonAreaBottom - 75
Gui, Show, NoActivate W430 H75 X%showX% Y%showY%

WinSet, Transparent, %transShown%, ahk_id %guiID%

Loop, 3 {
	SoundPlay, timer.wav
	Sleep, 2500
}

Gui, Show, W430 H75 center
Pause

ExitApp



; ------------------------------------------------------------------------------------------ ;

; Show time left hotkeys.
~^!Space::showHideTimer()

; Pause/resume hotkey.
^browser_forward::
	paused := !paused
	showHideTimer()
return

showHideTimer() {
	global freezeDisplay
	
	showTimer()
	
	; Keep timer visible while hotkeys are still held down
	while(GetKeyState("browser_back","P") || GetKeyState("browser_forward","P")) {
		Sleep, 1
	}
	
	if(!freezeDisplay)
		SetTimer, hideTimer, -2000
}

hideTimer:
	; global transShown, transHidden, guiID
	
	; MsgBox, test
	
	if(freezeDisplay) {
		return
	}
	
	steps := (transShown - transHidden) // 10
	trans := transShown
	; MsgBox, % steps
	Loop, %steps% {
		trans -= 10
		WinSet, Transparent, %trans%, ahk_id %guiID%
		Sleep, 10
	}
	WinSet, Transparent, %transHidden%, ahk_id %guiID%
	; shown = 0
	
	; MsgBox, hidden?
return

showTimer() {
	global transShown, transHidden, guiID
	
	steps := (transShown - transHidden) // 20
	trans := transHidden
	Loop, %steps% {
		trans += 20
		WinSet, Transparent, %trans%, ahk_id %guiID%
		sleep, 20
    }
   WinSet, Transparent, %transShown%, ahk_id %guiID%
   ; shown = 1
}

;Shift+Alt+X = Exit + warning, in case closing other scripts and this one unintentionally.
; ~+!x::
	; if(reallyExit = 0) {
		; GuiControl, Text, TimerText, Close Timer?
		; GuiControl, Move, TimerText, x%guiMargin% y10 w350 h50
	
		; Gui, Show, W370 H75 center
		; WinSet, Transparent, 255, ahk_id %guiID%
		
		; reallyExit := 1
		; freezeDisplay := 1
	; } else {
		; ExitApp
	; }
; return

; #IfWinActive, ahk_class AutoHotkeyGUI
	; Esc::
		; reallyExit := 0
		; freezeDisplay := 0
		
		; SetTimer, hideTimer, -2050
	; return
; #IfWinActive 


#Include <commonHotkeys>