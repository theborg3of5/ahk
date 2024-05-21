; Google Chrome hotkeys.
#If Config.isWindowActive("Chrome")
	; Block "close all tabs" hotkey
	^+w::return
	
	; Extensions hotkey.
	^+e::
		Send, !e       ; Main hamburger menu
		Sleep, 100
		Send, e{Enter} ; Extensions submenu
		Send, {Enter}  ; Manage extensions
	return
	
	; Handling for file links
	^RButton::Chrome.copyLinkTarget() ; Copy
	^MButton::Chrome.openLinkTarget() ; Open
	
	; Send page to IE/Edge
	^+s::Config.runProgram("Internet Explorer", Chrome.getURL())
	
	^!d::Send, !+d ; Deluminate - site-level hotkey (Chrome won't let me bind this directly)
	
	; LastPass loses all settings when it updates periodically, so I'm overriding the hotkeys here instead.
	!PgDn::!PgUp ; Reverse next/previous site hotkeys
	!PgUp::!PgDn
	!+l::Run("https://lastpass.com/vault/") ; Just launch this directly, instead of relying on the extension being able to run on the current page.
	
; Chrome hotkeys that do not apply in Hyperspace.
#If Config.isWindowActive("Chrome") && !Config.isWindowActive("Chrome Hyperspace")
	; Options hotkey.
	!o::
		HotkeyLib.waitForRelease() ; Presumably needed because the triggering hotkey has alt in it.
		Send, !e ; Main hamburger menu.
		Sleep, 100
		Send, g  ; Settings
	return
	
	; Copy title, stripping off the " - Google Chrome" at the end (and other special handling for specific pages like CodeSearch).
	!c::Chrome.copyTitle()
	!#c::Chrome.copyTitleLink()
	^!c::EpicLib.copyEMC2RecordIDFromText(Chrome.getTitle())
	^!#c::Chrome.copyCodeSearchClientPath()

	!t::Telegram.shareURL(Chrome.getURL()) ; Share to Telegram.

; Chrome hotkeys that only apply on a DLG.
#If Config.isWindowActive("Chrome") && WinActive("DLG ")
	^+o::EpicStudio.openCurrentDLG() ; Open DLG in EpicStudio
	!r::Chrome.openClientSVNLog()    ; Open client SVN log for a DLG.
	^+m::MBuilder.lintCurrentDLG()
#If
