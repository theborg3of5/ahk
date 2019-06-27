; Google Chrome hotkeys.
#If MainConfig.isWindowActive("Internet Explorer")
	; Get URL, close tab, and open the URL in your default web browser.
	^+o::InternetExplorer.moveURLToDefaultBrowser()
#If

class InternetExplorer {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	moveURLToDefaultBrowser(){
		url := ControlGetText("Edit1", "A") ; Get URL from URL bar control
		if(!url) {
			DEBUG.toast("No URL found in Internet Explorer")
			return
		}
		
		WinClose   ; Close the window
		Run, % url ; Open in default browser
	}
}