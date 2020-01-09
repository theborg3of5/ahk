; Google Chrome hotkeys.
#If Config.isWindowActive("Internet Explorer")
	; Get URL, close tab, and open the URL in your default web browser.
	^+o::InternetExplorer.moveURLToDefaultBrowser()
	^+c::InternetExplorer.pickF12Element()
#If

class InternetExplorer {
	; #INTERNAL#
	
	moveURLToDefaultBrowser(){
		url := ControlGetText("Edit1", "A") ; Get URL from URL bar control
		if(!url) {
			Debug.toast("No URL found in Internet Explorer")
			return
		}
		
		WinClose   ; Close the window
		Run, % url ; Open in default browser
	}
	
	pickF12Element() {
		f12DevToolsTitleString := "ahk_class F12FrameWindow ahk_exe IEXPLORE.EXE"
		
		if(!WindowLib.isVisible(f12DevToolsTitleString)) ; Apparently a non-visible window with this string can exist so we can't just check WinExist.
			firstTimeOpening := true
		
		Send, {F12} ; Open or switch to F12 Dev Tools
		WinWaitActive, % f12DevToolsTitleString
		
		if(firstTimeOpening) {
			Sleep, 1000 ; Give it a second to finish loading before we send stuff to it
			Send, {Tab} ; Get off the stuff in the titlebar that doesn't accept hotkeys.
		}
		
		Send, ^b ; Element picker hotkey
	}
	; #END#
}
