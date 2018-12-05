; Google Chrome hotkeys.
#IfWinActive, ahk_exe iexplore.exe
	; Get URL, close tab, and open the URL in your default web browser.
	^+o::
		moveURLToDefaultBrowser(){
			Send, ^l ; Focus URL bar, also selects text
			url := getSelectedText()
			if(!url) {
				DEBUG.toast("No URL found in Internet Explorer")
				return
			}
			
			Send, ^w   ; Close the tab
			Run, % url ; Open in default browser
		}
#IfWinActive
