/* Helper functions for hotkeys.
*/

class HotkeyLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
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
	
	;---------
	; DESCRIPTION:    Send the given media key, with special exceptions for different media players.
	; PARAMETERS:
	;  keyName (I,REQ) - The name of the key in question.
	;---------
	sendMediaKey(keyName) {
		if(!keyName)
			return
		
		; There's some sort of odd race condition with Spotify that double-sends the play/pause hotkey if Spotify is focused - this prevents it, though I'm not sure why.
		Sleep, 100
		
		; Only certain media keys need special handling, let others straight through.
		specialKeysAry := ["Media_Play_Pause", "Media_Prev", "Media_Next"]
		if(!specialKeysAry.contains(keyName)) {
			Send, % "{" keyName "}"
			return
		}
		
		; Youtube - special case that won't respond to media keys natively
		if(Config.isMediaPlayer("Chrome")) {
			if(keyName = "Media_Play_Pause")
				Send, ^.
			else if(keyName = "Media_Prev")
				Send, ^+,
			else if(keyName = "Media_Next")
				Send, ^+.
			
		} else {
			Send, % "{" keyName "}"
		}
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
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
		
		; Special characters for how a hotkey is checked
		if(hotkeyChar = "*")
			return ""
		if(hotkeyChar = "$")
			return ""
		if(hotkeyChar = "~")
			return ""
		if(hotkeyChar = " ")
			return "" ; Space within hotkey - probably around an & or similar.
		
		; Modifier keys
		if(hotkeyChar = "#")
			return "LWin" ; There's no generic "Win", so just pick the left one.
		if(hotkeyChar = "!")
			return "Alt"
		if(hotkeyChar = "^")
			return "Ctrl"
		if(hotkeyChar = "+")
			return "Shift"
		
		; Otherwise, probably a letter or number.
		return hotkeyChar
	}
}
