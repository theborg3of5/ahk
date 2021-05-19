; Fix the display setting to be my preferred "Window - Large" setting for all VDIs, as it seems to completely forget this on the regular.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

pt := new ProgressToast("Fix VDI display settings")

; Make sure to wait until the settings window is active (contains "Display settings" text)
pt.nextStep("Waiting for settings window to be active")
WinWaitActive, VMware Horizon Client ahk_exe vmware-view.exe, Display settings
Sleep, 1000 ; Give it a second to fully load up its contents

; Note the name of the last entry so we stop there.
pt.nextStep("Finding last entry to stop at")
ControlFocus, ListBox1, A
Send, {End}
finalName := getCurrentName()
pt.endStep(finalName)

; Start with the first VDI entry (Conference Room for the moment)
pt.nextStep("Finding first VDI entry (Esc to stop)")
Send, {Home}
Loop {
	Sleep, 250 ; Fields take a bit to load up sometimes.
	
	if(getCurrentName() = "Conference Room")
		Break
	
	Send, {Down}
}

; Loop down through all entries and update the display setting.
pt.nextStep("Fixing VDI entries (Esc to stop)")
Loop {
	Sleep, 250 ; Fields take a bit to load up sometimes.
	
	Control, ChooseString, Window - Large, ComboBox1, A
	
	if(getCurrentName() = finalName)
		Break
	
	Send, {Down}
}

pt.blockingOn().finish()
ExitApp

Esc::ExitApp

getCurrentName() {
	text := WinGetText("A").afterString("VMware Blast (default)") ; Always comes after this line
	
	; Comes just before one of these
	text := text.beforeString("Customize remote desktop settings:")
	text := text.beforeString("&Preferred protocol:")
	text := text.beforeString("Scaling:")
	
	; Remove leading/trailing newlines
	return text.clean()
}
