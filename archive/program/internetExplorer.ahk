; Internet Explorer hotkeys.
#If Config.isWindowActive("Internet Explorer")
	; Get URL, close tab, and open the URL in your default web browser.
	^+o::InternetExplorer.moveURLToDefaultBrowser()
	^+c::InternetExplorer.pickF12Element()
	
	; Handling for file links
	^RButton::InternetExplorer.copyLinkTarget() ; Copy
	^MButton::InternetExplorer.openLinkTarget() ; Open
#If
