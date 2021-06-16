; System-level hotkeys and overrides.

; [[Lock/suspend]]
; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
~^!+#s::DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)

; Alternate lock computer hotkeys
+#l::DllCall("LockWorkStation")
#If Config.machineIsHomeDesktop
	$Volume_Mute::DllCall("LockWorkStation")
#If

; Remap different keyboards
#If Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	; Extra buttons on the ergonomic keyboard as left/right clicks (disable them in MS mouse and keyboard)
	Browser_Back::   HotkeyLib.sendCatchableKeys("{LButton}")
	Browser_Forward::HotkeyLib.sendCatchableKeys("{RButton}")
#If Config.machineIsHomeLaptop || Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
#If

; Release all modifier keys, for cases when some might be "stuck" down.
*#Space::HotkeyLib.releaseAllModifiers()

; CapsLock is used by various other hotkeys, so this is the only way to actually use it as CapsLock.
^!CapsLock::SetCapsLockState, On
