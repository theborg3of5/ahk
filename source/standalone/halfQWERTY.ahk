; Use Space to "mirror" the keyboard - allows you to type with one hand.

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
	; Debug.popup("Hotkey",A_ThisHotkey, "Mirrored key",mirroredKey)
	
	; {Blind} mode lets us use modifiers with whatever was pressed, too.
	Send, {Blind}%mirroredKey%
return


buildMirrorKeys() {
	keys := {}
	
	; Put a "KEY_" in front of each character so that later on when we're retrieving a value, we can force the key to be a string.
	keys["KEY_1"] := "0"
	keys["KEY_2"] := "9"
	keys["KEY_3"] := "8"
	keys["KEY_4"] := "7"
	keys["KEY_5"] := "6"
	keys["KEY_6"] := "5"
	keys["KEY_7"] := "4"
	keys["KEY_8"] := "3"
	keys["KEY_9"] := "2"
	keys["KEY_0"] := "1"
	
	keys["KEY_q"] := "p"
	keys["KEY_w"] := "o"
	keys["KEY_e"] := "i"
	keys["KEY_r"] := "u"
	keys["KEY_t"] := "y"
	keys["KEY_y"] := "t"
	keys["KEY_u"] := "r"
	keys["KEY_i"] := "e"
	keys["KEY_o"] := "w"
	keys["KEY_p"] := "q"
	
	keys["KEY_a"] := ";"
	keys["KEY_s"] := "l"
	keys["KEY_d"] := "k"
	keys["KEY_f"] := "j"
	keys["KEY_g"] := "h"
	keys["KEY_h"] := "g"
	keys["KEY_j"] := "f"
	keys["KEY_k"] := "d"
	keys["KEY_l"] := "s"
	keys["KEY_;"] := "a"
	
	keys["KEY_z"] := "/"
	keys["KEY_x"] := "."
	keys["KEY_c"] := ","
	keys["KEY_v"] := "m"
	keys["KEY_b"] := "n"
	keys["KEY_n"] := "b"
	keys["KEY_m"] := "v"
	keys["KEY_,"] := "c"
	keys["KEY_."] := "x"
	keys["KEY_/"] := "z"
	
	return keys
}

getMirroredKeyFromHotkey(hotkeyString) {
	if(!hotkeyString)
		return ""
	
	keyToMirror := "KEY_" hotkeyString.sub(0)
	if(!keyToMirror)
		return ""
	
	; Debug.popup("Hotkey",hotkeyString, "Key to mirror",keyToMirror, "Result",mirrorKeys[keyToMirror], "MirrorKeys",mirrorKeys)
	return mirrorKeys[keyToMirror]
}
