#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Vim Bindings for Chrome/Firefox")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub)

global vimKeysOn := 1
states := {}
states["A_IsSuspended", 1]                 := "vimSuspend.ico"
states["A_IsSuspended", 0, "vimKeysOn", 0] := "vimPause.ico"
states["A_IsSuspended", 0, "vimKeysOn", 1] := "vim.ico"
ScriptTrayInfo.setStateIcons(states)

global offTitles := getExcludedTitles()
global autoPaused := false ; Says whether we just temporarily paused vimKeys automatically (like for ^l)


; After a certain time not having browser focused, reset vimKeys to on.
IDLE_TIME := 5 * 60 * 1000 ; 5 minutes
SetTimer, vimIdle, %IDLE_TIME%
vimIdle:
	if(!browserActive())
		turnVimKeysOn()
return

; Run on any page in the browser, regardless of state.
#If browserActive()
	!m::
		turnVimKeysOn()
	return
	
	F6::
	F8::
	F9::
		Send, ^w
		turnVimKeysOn()
	return
	
	; Special addition for when j/k turned off because special page.
	RAlt & j::Send, {Down}
	RAlt & k::Send, {Up}
#If

; Run as long as vimkeys are on.
#If browserActive() && areVimKeysOn()
	; Pause/suspend.
	i::
		turnVimOffManual()
	return
	
	; Next/Previous Tab.
	o::Send, ^{Tab}
	u::Send, ^+{Tab}
	
	; Auto-pause (so we'll switch back on enter/escape)
	~^l::
	~^t::
	~^f::
		turnVimOffAuto()
	return
	
	; Keys that turn vimkeys off, because you're probably typing something else.
	~a:: ; Letters
	~b::
	~c::
	~d::
	~e::
	~f::
	~g::
	~h::
	~l::
	~m::
	~n::
	~q::
	~r::
	~s::
	~t::
	~v::
	~w::
	~x::
	~y::
	~z::
	~0:: ; Numbers
	~1::
	~2::
	~3::
	~4::
	~5::
	~6::
	~7::
	~8::
	~9::
	~`:: ; Symbols
	~-::
	~=::
	~,::
	~.::
	~+a:: ; Shift + Letters
	~+b::
	~+c::
	~+d::
	~+e::
	~+f::
	~+g::
	~+h::
	~+i::
	~+j::
	~+k::
	~+l::
	~+m::
	~+n::
	~+o::
	~+p::
	~+q::
	~+r::
	~+s::
	~+t::
	~+u::
	~+v::
	~+w::
	~+x::
	~+y::
	~+z::
	~+0:: ; Shift + Numbers
	~+1::
	~+2::
	~+3::
	~+4::
	~+5::
	~+6::
	~+7::
	~+8::
	~+9::
	~+`:: ; Shift + Symbols
	~+-::
	~+=::
	~+,::
	~+.::
	~+[:: ; Shift + Symbols (where the unshifted version does something)
	~+]::
	~+`;::
	~+'::
	~+/::
		turnVimOffManual()
	return
#If

; Run as long as we're not on an exclude page.
#If browserActive() && !isPageWithExcludeTitle()
	; Unpause for special cases.
	~$Esc::
	~$Enter::
		if(autoPaused)
			turnVimKeysOn()
	return
#If

; Normal key commands
; Run if vimkeys are on and we're not on an excluded page.
#If browserActive() && areVimKeysOn() && !isPageWithExcludeTitle()
	; Up/Down/Left/Right.
	j::Send, {Down}
	k::Send, {Up}
	
	; Page Up/Down/Top/Bottom.
	`;::Send, {PgDn}
	p::Send, {PgUp}
	[::Send, {Home}
	]::Send, {End}
	
	; Bookmarklet hotkeys.
	RAlt & `;::sendToOmniboxAndGo("d") ; Darken bookmarklet hotkey.
#If


getExcludedTitles() {
	titlesAry := []
	titlesAry.push(" - Gmail")
	titlesAry.push(" - Feedly")
	titlesAry.push(" - Reddit")
	titlesAry.push("Google Calendar - ")
	return titlesAry
}


; Chrome or Firefox.
browserActive() {
	return Config.isWindowActive("Chrome") || WinActive("ahk_class MozillaWindowClass")
}
areVimKeysOn() {
	return vimKeysOn
}
isPageWithExcludeTitle() {
	return WinGetActiveTitle().containsAnyOf(offTitles)
}

turnVimKeysOn() {
	setVimKeysState(true)
}
turnVimOffManual() {
	global autoPaused
	autoPaused := false
	setVimKeysState(false)
}
turnVimOffAuto() {
	global autoPaused
	autoPaused := true
	setVimKeysState(false)
}

setVimKeysState(toState) {
	vimKeysOn := toState
	ScriptTrayInfo.updateTrayIcon()
}

sendToOmniboxAndGo(url) {
	Send, ^l
	Sleep, 100
	SendRaw, %url%
	Send, {Enter}
}
