#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

global mirrorKeys := buildMirrorKeys()


; These keys are optional, but they may help if you are typing on the left-hand side.
CapsLock::Send, {BackSpace}
Space & CapsLock::Send, {Enter}

; If Spacebar didn't modify anything, send a real Space keystroke upon release.
Space::
	Send {Space}
return

; Mirror hotkeys
Space & 1::
Space & 2::
Space & 3::
Space & 4::
Space & 5::
Space & 6::
Space & 7::
Space & 8::
Space & 9::
Space & 0::
Space & q::
Space & w::
Space & e::
Space & r::
Space & t::
Space & y::
Space & u::
Space & i::
Space & o::
Space & p::
Space & a::
Space & s::
Space & d::
Space & f::
Space & g::
Space & h::
Space & j::
Space & k::
Space & l::
Space & `;::
Space & z::
Space & x::
Space & c::
Space & v::
Space & b::
Space & n::
Space & m::
Space & ,::
Space & .::
Space & /::
	mirroredKey := getMirroredKeyFromHotkey(A_ThisHotkey)
	; DEBUG.popup("Hotkey",A_ThisHotkey, "Mirrored key",mirroredKey)
	
	; {Blind} mode lets us use modifiers with whatever was pressed, too.
	Send, {Blind}%mirroredKey%
return


buildMirrorKeys() {
	keysAry := []
	
	; Put a "KEY_" in front of each character so that later on when we're retrieving a value, we can force the key to be a string.
	keysAry["KEY_1"] := "0"
	keysAry["KEY_2"] := "9"
	keysAry["KEY_3"] := "8"
	keysAry["KEY_4"] := "7"
	keysAry["KEY_5"] := "6"
	keysAry["KEY_6"] := "5"
	keysAry["KEY_7"] := "4"
	keysAry["KEY_8"] := "3"
	keysAry["KEY_9"] := "2"
	keysAry["KEY_0"] := "1"
	
	keysAry["KEY_q"] := "p"
	keysAry["KEY_w"] := "o"
	keysAry["KEY_e"] := "i"
	keysAry["KEY_r"] := "u"
	keysAry["KEY_t"] := "y"
	keysAry["KEY_y"] := "t"
	keysAry["KEY_u"] := "r"
	keysAry["KEY_i"] := "e"
	keysAry["KEY_o"] := "w"
	keysAry["KEY_p"] := "q"
	
	keysAry["KEY_a"] := ";"
	keysAry["KEY_s"] := "l"
	keysAry["KEY_d"] := "k"
	keysAry["KEY_f"] := "j"
	keysAry["KEY_g"] := "h"
	keysAry["KEY_h"] := "g"
	keysAry["KEY_j"] := "f"
	keysAry["KEY_k"] := "d"
	keysAry["KEY_l"] := "s"
	keysAry["KEY_;"] := "a"
	
	keysAry["KEY_z"] := "/"
	keysAry["KEY_x"] := "."
	keysAry["KEY_c"] := ","
	keysAry["KEY_v"] := "m"
	keysAry["KEY_b"] := "n"
	keysAry["KEY_n"] := "b"
	keysAry["KEY_m"] := "v"
	keysAry["KEY_,"] := "c"
	keysAry["KEY_."] := "x"
	keysAry["KEY_/"] := "z"
	
	return keysAry
}

getMirroredKeyFromHotkey(hotkeyString) {
	if(!hotkeyString)
		return ""
	
	keyToMirror := "KEY_" hotkeyString.sub(0)
	if(!keyToMirror)
		return ""
	
	; DEBUG.popup("Hotkey",hotkeyString, "Key to mirror",keyToMirror, "Result",mirrorKeys[keyToMirror], "MirrorKeys",mirrorKeys)
	return mirrorKeys[keyToMirror]
}
