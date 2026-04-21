; System-level hotkeys and overrides.

;region Lock/suspend
; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
~^!+#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Alternate lock computer hotkeys
+#l::DllCall("LockWorkStation")
#HotIf Config.machineIsHomeDesktop
	$Volume_Mute::DllCall("LockWorkStation")
#HotIf
;endregion Lock/suspend

;region Keyboard mapping
#HotIf Config.machineIsWorkDesktop || Config.machineIsWorkVDI
	Launch_App2::return ; Disable oft-mistakenly-pressed calculator key on work keyboard
#HotIf Config.machineIsHomeLaptop
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
#HotIf
;endregion Keyboard mapping

;region Special hotkey handling
; Release all modifier keys, for cases when some might be "stuck" down.
*#Space::HotkeyLib.releaseAllModifiers()

; CapsLock is used by various other hotkeys, so this is the only way to actually use it as CapsLock.
^!CapsLock::SetCapsLockState("On")

; Disable various Windows hotkeys I don't want.
#=:: ; Magnifier
#-:: {
	return
}
;endregion Special hotkey handling