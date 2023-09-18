; Google Chrome hotkeys.
#If Config.isWindowActive("Chrome")
	; Block "close all tabs" hotkey
	^+w::return

	; Options hotkey.
	!o::
		HotkeyLib.waitForRelease() ; Presumably needed because the triggering hotkey has alt in it.
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, g  ; Settings
	return
	
	; Extensions hotkey.
	^+e::
		Send, !e       ; Main hamburger menu
		Sleep, 100
		Send, e{Enter} ; Extensions submenu
		Send, {Enter}  ; Manage extensions
	return
	
	; Copy title, stripping off the " - Google Chrome" at the end (and other special handling for specific pages like CodeSearch).
	!c::Chrome.copyTitle()
	!#c::Chrome.copyTitleLink()
	^!c::EpicLib.copyEMC2RecordIDFromText(Chrome.getTitle())
	^!#c::Chrome.copyCodeSearchClientPath()
	
	; Open DLG in EpicStudio
	^+o::EpicStudio.openCurrentDLG()
	
	; Handling for file links
	^RButton::Chrome.copyLinkTarget() ; Copy
	^MButton::Chrome.openLinkTarget() ; Open
	
	; Send page to IE/Edge
	^+s::Config.runProgram("Internet Explorer", Chrome.getURL())
	
	; Extension-specific handling
	!t::Telegram.shareURL(Chrome.getURL()) ; Share to Telegram.
	^!d::Send, !+d ; Deluminate - site-level hotkey (Chrome won't let me bind this directly)
	; LastPass loses all settings when it updates periodically, so I'm overriding the hotkeys here instead.
	!PgDn::!PgUp ; Reverse next/previous site hotkeys
	!PgUp::!PgDn
	!+l::Send, ^!h ; Open vault
	
#If Config.isWindowActive("Chrome") && WinActive("DLG ")
	; Open client SVN log for a DLG.
	!r::Chrome.openClientSVNLog()
	^+m::MBuilder.lintCurrentDLG()
#If
