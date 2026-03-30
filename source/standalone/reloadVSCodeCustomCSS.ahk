; Helper to reload custom CSS/JS in VSCode.

#Include <includeCommon>

global mouseClicked := false

; Force this script to run as admin so it can interact with VSCode (which also has to be running as admin)
pt := new ProgressToast("Reloading VSCode custom CSS/JS").blockingOn()
pt.nextStep("Making sure this script is running as admin")
RunLib.forceCurrScriptAdmin()

; If there are other VSCode instances open, it won't properly run as admin (causing the command to fail)
pt.nextStep("Waiting for all VSCode instances to exit")
WinWaitClose, ahk_exe Code.exe

; Run new instance (as admin, because this script is admin)
;  --no-sandbox is required because running as admin (with my setup at least) causes error 18:
;   https://stackoverflow.com/questions/76470339/visual-studio-code-1-79-1-launch-in-admin-mode-fails-with-code-18
pt.nextStep("Running VSCode as admin")
Run("C:\Program Files\Microsoft VS Code\Code.exe --no-sandbox --new-window --profile=EpicCode")
WinWaitActive, % "EpicCode - Visual Studio Code" ; Using this full title helps us make sure it's loaded up before continuing

pt.nextStep("Submitting ""Reload Custom CSS and JS"" command (via command palette)")
Sleep, 1000 ; Waiting for the right title above _should_ be enough, but a little wiggle room helps ensure it.
Send, ^+p ; Open command palette
ClipboardLib.send("extension.updateCustomCSS") ; "Reload Custom CSS and JS" command ID
Send, {Enter}

pt.nextStep("Waiting for restart prompt notification (press Enter or click when it appears)")
moveMouseToBottomRightOffset(100, 60)
waitForUserButton(pt)

pt.nextStep("Waiting for ""corrupted"" notification (press Enter or click when it appears)")
moveMouseToBottomRightOffset(60, 100) ; Gear icon
waitForUserButton(pt)
moveMouseToBottomRightOffset(100, 70) ; Ignore option
waitForUserButton(pt)

pt.nextStep("Exiting VSCode")
WinClose, ahk_exe Code.exe
WinWaitClose, ahk_exe Code.exe

pt.finish()
ExitApp

; Notice when the mouse is clicked without blocking it, for when we're waiting for enter or click.
~LButton::
	mouseClicked := true
return

; Wait for the user to click a button (or press Enter, which will also click it)
waitForUserButton(pt) {
	mouseClicked := false ; So we can tell when the user clicks while we're waiting
	
	; Wait for Enter or click
	Loop {
		; Wait for Enter (check every 0.5s)
		KeyWait, Enter, D T0.5
		if (ErrorLevel = 0)
			Break
		
		; Also check if the user clicked
		if (mouseClicked)
			Break
	}

	; If VSCode was closed, bail out early
	if (!WinExist("ahk_exe Code.exe")) {
		pt.finish("Quitting early, VSCode is gone")
		ExitApp
	}

	; If VSCode got unfocused, prompt and wait
	if (!WinActive("ahk_exe Code.exe")) {
		pt.nextStep("VSCode focus lost, refocus to continue")
		WinWaitActive, ahk_exe Code.exe
		Click ; Always click in this case, because if the user clicked it wasn't on the right window
		return
	}
	
	; Click if the user didn't already (clicking is a pass-through)
	if (!mouseClicked)
		Click
}

; Move the mouse to the given distances from the bottom-right corner of the window.
moveMouseToBottomRightOffset(x, y) {
	WinGetPos, , , width, height, ahk_exe Code.exe
	
	; Position of the button (will probably have to adjust over time)
	desiredX := width - x
	desiredY := height - y
	
	ts := new TempSettings().coordMode("Mouse", "Window")
	MouseMove, % desiredX, % desiredY
	ts.restore()
}