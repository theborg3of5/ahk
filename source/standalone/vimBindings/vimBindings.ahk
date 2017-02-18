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
	
	global offTitles := Object()
	offTitles.insert(" - Google Inbox")
	offTitles.insert(" - feedly")
	offTitles.insert(" - Reddit")
	offTitles.insert("Login") ; Lastpass

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

; Returns false if the given conditions fail against the page title, etc.
vimActive(vimOn = 1, titlesOn = 1) {
	if(!browserActive())
		return false
	
	if(vimOn && !vimKeysOn)
		return false
		
	if(titlesOn && titleContains(offTitles))
		return false
	
	return true
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

#If browserActive()
	!m::
		setVimState(true)
	return
#If

#If vimActive(0, 0)
{ ; Run on any page in the browser, regardless of state.
	F6::
	F8::
	F9::
		closeTab()
	return
	
	; Special addition for when j/k turned off because special page.
	; ' & j::Send, {Down}
	; ' & k::Send, {Up}
	; ' Up::Send, '
	RAlt & j::Send, {Down}
	RAlt & k::Send, {Up}
}
#If

#If vimActive(1, 0)
{ ; Run as long as vimkeys are on, ignoring page exclusions.
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
}
#If

#If vimActive(0, 1)
{ ; Run as long as we're not on an exclude page.
	; Unpause for special cases.
	~$Esc::
	~$Enter::
		unpauseSpecial()
	return
}
#If

#If vimActive() && ( (MainConfig.isMachine(HOME_ASUS)) || (MainConfig.isMachine(HOME_DESKTOP)) )
{
	RCtrl & Right::sendToOmniboxAndGo("+") ; Increment.
}
#If

#If vimActive()
{ ; Run if we're not on an excluded page and vimkeys are on.
	; Up/Down/Left/Right.
	j::Send, {Down}
	k::Send, {Up}
	; h::Send, {Left}
	; l::Send, {Right}
	
	; Page Up/Down/Top/Bottom.
	`;::Send, {PgDn}
	p::Send, {PgUp}
	[::Send, {Home}
	]::Send, {End}
	
	; Forward, to match backspace for back.
	\::Send, !{Right}
	
	; Find
	/::
		Send, ^f
	~^f::
		setVimState(false, , , 1)
	return

	; Feedly: if gg, pause script until enter or esc.
	~g::
		WinGetTitle, pageTitle, A
		
		if(InStr(pageTitle, " - feedly")) {
			setVimState(false, 1)
		}
	return
	
	; Bookmarklet hotkeys.
	RAlt & `;::sendToOmniboxAndGo("d") ; Darken bookmarklet hotkey.
	; RAlt & z::sendToOmniboxAndGo("pz") ; PageZipper.
	
	; Letters that carry no vim meaning, so are normal typing.
	~a::
	~b::
	~c::
	~d::
	~e::
	~f::
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
	
	; Shifted letters never carry any vim meaning.
	~+a::
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
	
	; Numbers and shifted numbers never carry any vim meaning.
	~0::
	~1::
	~2::
	~3::
	~4::
	~5::
	~6::
	~7::
	~8::
	~9::
	~+0::
	~+1::
	~+2::
	~+3::
	~+4::
	~+5::
	~+6::
	~+7::
	~+8::
	~+9::
	
	; Symbols that don't carry any vim meaning, plus shifted versions.
	~`::
	~-::
	~=::
	~+`::
	~+-::
	~+=::
	
	; Symbols that normally carry vim meaning, but don't when shifted.
	~+[::
	~+]::
	~+`;::
	~+'::
	~+/::
	~+,::
	~+.::
		setVimState(false, , , , 1)
		justOtherKeyPressed := 1
	return
}
#If

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\..\..\common\commonHotkeys.ahk
