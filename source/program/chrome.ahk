﻿; Google Chrome hotkeys.
#If Config.isWindowActive("Chrome")
	; Options hotkey.
	!o::
		HotkeyLib.waitForRelease() ; Presumably needed because the triggering hotkey has alt in it.
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, s  ; Settings
	return
	
	; Extensions hotkey.
	^+e::
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, l  ; More tools
		Send, e  ; Extensions
	return
	
	; Copy title, stripping off the " - Google Chrome" at the end (and other special handling for specific pages like CodeSearch).
	!c::Chrome.copyTitle()
	!#c::Chrome.copyTitleLink()
	^!#c::Chrome.copyCodeSearchClientPath()
	
	; Open DLG in EpicStudio
	^+o::Chrome.openCurrentDLGInEpicStudio()
	
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
#If
