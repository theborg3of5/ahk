; Helper functions for hotkeys.

class HotkeyLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Release all modifier keys. This is useful when certain modifier keys get "stuck" down.
	;---------
	releaseAllModifiers() {
		modifierKeys := ["LWin", "RWin", "LCtrl", "RCtrl", "LAlt", "RAlt", "LShift", "RShift"]
		For _,modifier in modifierKeys {
			if(GetKeyState(modifier))
				Send, {%modifier% Up}
		}
	}
	
	;---------
	; DESCRIPTION:    Wait for the given hotkey to be fully released (all modifiers included).
	; PARAMETERS:
	;  hotkeyString (I,OPT) - The hotkey to wait on. If not set, we'll use A_ThisHotkey to get the
	;                         hotkey that triggered this function.
	;---------
	waitForRelease(hotkeyString := "") {
		if(!hotkeyString)
			hotkeyString := A_ThisHotkey
		
		Loop, Parse, hotkeyString
		{
			keyName := HotkeyLib.getKeyNameFromHotkeyChar(A_LoopField)
			if(keyName)
				KeyWait, % keyName
		}
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Given a character from a hotkey string, figure out the name of the corresponding key.
	; PARAMETERS:
	;  hotkeyChar (I,REQ) - The character to identify.
	; RETURNS:        The name of the hotkey character, suitable for use with Send or KeyWait.
	; NOTES:          This isn't comprehensive - doesn't handle things like UP, for example.
	;---------
	getKeyNameFromHotkeyChar(hotkeyChar) {
		if(!hotkeyChar)
			return ""
		
		Switch hotkeyChar {
			Case "*","$","~": return "" ; Special characters for how a hotkey is checked
			Case " ":         return "" ; Space within hotkey (means nothing) - probably around an & or similar.
			Case "#":         return "LWin" ; There's no generic "Win", so just pick the left one.
			Case "!":         return "Alt"
			Case "^":         return "Ctrl"
			Case "+":         return "Shift"
			Default:          return hotkeyChar ; Otherwise, probably a letter or number.
		}
	}
	; #END#
}
