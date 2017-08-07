{ ; Setup.
	#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
	#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
	SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
	
	#Include <autoInclude>

	; State flags.
	global suspended := 0
	global vimKeysOn := 1
	
	global IDLE_TIME := 5 * 60 * 1000 ; 5 minutes
	
	; Icon setup.
	states                                 := []
	states["suspended", 1]                 := "vimSuspend.ico"
	states["suspended", 0, "vimKeysOn", 0] := "vimPause.ico"
	states["suspended", 0, "vimKeysOn", 1] := "vim.ico"
	setupTrayIcons(states)
	
	global offTitles := getExcludedTitles()

	; Special flags for previous action.
	global justFound := 0
	global justOmnibox := 0
	global justFeedlySearched := 0
	global justOtherKeyPressed := 0
}

; Timer stuff.
SetTimer, vimIdle, %IDLE_TIME%
vimIdle:
	if(!browserActive())
		setVimState(true)
return

getExcludedTitles() {
	titles := Object()
	titles.insert(" - Gmail")
	titles.insert(" - feedly")
	titles.insert(" - Reddit")
	titles.insert("Login") ; Lastpass
	return titles
}

; Chrome or Firefox.
browserActive() {
	return WinActive("ahk_class Chrome_WidgetWin_1") || WinActive("ahk_class MozillaWindowClass")
}

; Sets the various on/off switches.
setVimState(toState, feedly = -1, omni = -1, found = -1, other = -1) {
	global justFeedlySearched, justOmnibox, justFound, justOtherKeyPressed
	
	if(feedly != -1)
		justFeedlySearched := feedly
	if(omni != -1)
		justOmnibox := omni
	if(found != -1)
		justFound := found
	if(other != -1)
		justOtherKeyPressed := other
	
	vimKeysOn := toState
	updateTrayIcon()
}

; Only unpause vimKeys if we came from something else special.
unpauseSpecial() {
	global justFeedlySearched, justOmnibox, justFound
	
	if(justFeedlySearched || justOmnibox || justFound)
		setVimState(true, 0, 0, 0, 0)
}

; Closes the browser tab if the close key matches what was pressed.
closeTab() {
	; DEBUG.popup("Main Close Key", MainConfig.getSetting("VIM_CLOSE_KEY"), "Given Key", A_ThisHotkey)
	if(MainConfig.isValue("VIM_CLOSE_KEY", A_ThisHotkey)) {
		Send, ^w
		setVimState(true)
	}
}

sendToOmniboxAndGo(url) {
	Send, ^l
	Sleep, 100
	SendRaw, %url%
	Send, {Enter}
}

; Run on any page in the browser, regardless of state.
#If browserActive()
	!m::
		setVimState(true)
	return
	
	F6::
	F8::
	F9::
		closeTab()
	return
	
	; Special addition for when j/k turned off because special page.
	RAlt & j::Send, {Down}
	RAlt & k::Send, {Up}
#If

; Run as long as vimkeys are on.
#If vimKeysOn
	; Pause/suspend.
	~^l::
	~^t::
		justOmnibox := 1
	i::
		setVimState(false)
	return
	
	; Next/Previous Tab.
	o::Send, ^{Tab}
	u::Send, ^+{Tab}
#If

; Run as long as we're not on an exclude page.
#If titleContains(offTitles)
	; Unpause for special cases.
	~$Esc::
	~$Enter::
		unpauseSpecial()
	return
#If

; Normal key commands
; Run if vimkeys are on and we're not on an excluded page.
#If vimKeysOn && titleContains(offTitles)
	; Up/Down/Left/Right.
	j::Send, {Down}
	k::Send, {Up}
	
	; Page Up/Down/Top/Bottom.
	`;::Send, {PgDn}
	p::Send, {PgUp}
	[::Send, {Home}
	]::Send, {End}
	
	; Find
	~^f::
		setVimState(false, , , 1)
	return
	
	; Bookmarklet hotkeys.
	RAlt & `;::sendToOmniboxAndGo("d") ; Darken bookmarklet hotkey.
	; RAlt & z::sendToOmniboxAndGo("pz") ; PageZipper.
	RCtrl & Right::
		if(MainConfig.isMachine(HOME_DESKTOP) || MainConfig.isMachine(HOME_ASUS)) ; Limit this to home.
			return
		sendToOmniboxAndGo("+") ; Increment.
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
	~+[:: ; Shift + Symbols (where the unshifted version does something)
	~+]::
	~+`;::
	~+'::
	~+/::
	~+,::
	~+.::
		setVimState(false, , , , 1)
		justOtherKeyPressed := 1 ; GDB TODO doesn't setVimState do exactly this already?
	return
#If

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\..\common\commonHotkeys.ahk
