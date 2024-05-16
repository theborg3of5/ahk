class SoundSwitch {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Toggle both the playback and recording devices using SoundSwitch.
	; SIDE EFFECTS:   If remote desktop is currently active, this will briefly activate the windows taskbar on the local
	;                 machine before going back.
	;---------
	toggleDevices() {
		; Remote desktop eats most hotkeys (including those we want to send to SoundSwitch), so we need to activate something else first if it's active.
		if(Config.isWindowActive("Remote Desktop")) {
			origIdString := WindowLib.getIdTitleString("A")
			WinActivate, ahk_class Shell_TrayWnd ; Windows taskbar - unobtrusive to activate, but gets us out of remote desktop for sending keys
		}
		
		; Make the switch using hotkeys configured in SoundSwitch.
		Send, % this.Hotkey_SwitchPlaybackDevice
		Sleep, 500
		Send, % this.Hotkey_SwitchRecordingDevice
		
		; If we had to activate something earlier, go back.
		if(origIdString)
			WinActivate, % origIdString
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; Hotkeys configured in SoundSwitch
	static Hotkey_SwitchPlaybackDevice  := "^{F12}"
	static Hotkey_SwitchRecordingDevice := "^+{F12}"
	;endregion ------------------------------ PRIVATE ------------------------------
}
