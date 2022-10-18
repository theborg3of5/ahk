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

; [[Keyboard mapping]]
#If Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	; Extra buttons on the ergonomic keyboard as left/right clicks (disable them in MS mouse and keyboard)
	Browser_Back::   HotkeyLib.sendCatchableKeys("{LButton}")
	Browser_Forward::HotkeyLib.sendCatchableKeys("{RButton}")
#If Config.machineIsHomeLaptop || Config.machineIsWorkLaptop || Config.machineIsWorkVDI
	AppsKey::RWin ; No right windows key on these machines, so use the AppsKey (right-click key) instead.
#If

; [[Special hotkey handling]]
; Release all modifier keys, for cases when some might be "stuck" down.
*#Space::HotkeyLib.releaseAllModifiers()

; CapsLock is used by various other hotkeys, so this is the only way to actually use it as CapsLock.
^!CapsLock::SetCapsLockState, On

; Disable various Windows hotkeys I don't want.
#=:: ; Magnifier
#-::
	return

; GDB TODO remove
^+!0::testFunc()
testFunc() {
	titleString := "A"
	
	exe   := WinGet("ProcessPath", titleString) ; Use full process path so win_exe values can match on full path if needed.
	class := WinGetClass(titleString)
	title := WinGetTitle(titleString)

	bestMatch := ""
	For _,winInfo in Config.windows {
		if(!winInfo.windowMatchesPieces(exe, class, title))
			Continue
		
		; If we already found another match, don't replace it unless the new match has a better (lower) priority
		if((bestMatch != "") && bestMatch.priority < winInfo.priority)
			Continue
		
		; This is the best match we've found so far
		bestMatch := winInfo
	}
	
	info := bestMatch.clone() ; Handles "" fine ("".clone() = "")
	
	debugString := "titleString=" titleString
	debugString .= "`n" "exe" "=" exe "`t`t`t|`t`t`t" "bestMatch.exe" "=" bestMatch.exe
	debugString .= "`n" "class" "=" class "`t`t`t|`t`t`t" "bestMatch.class" "=" bestMatch.class
	debugString .= "`n" "title" "=" title "`t`t`t|`t`t`t" "bestMatch.title" "=" bestMatch.title
	debugString .= "`n" "bestMatch.name" "=" bestMatch.name
	debugString .= "`n" "(Config.windows)[""Telegram""].name" "=" (Config.windows)["Telegram"].name
	
	MsgBox, % debugString
}
