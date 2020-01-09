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
		if(!WindowLib.isVisible(this.F12DevToolsTitleString)) ; Apparently a non-visible window with this string can exist so we can't just check WinExist.
			firstTimeOpening := true
		
		Send, {F12} ; Open or switch to F12 Dev Tools
		WinWaitActive, % this.F12DevToolsTitleString
		
		if(firstTimeOpening)
			Sleep, 1000 ; Give it a few seconds to finish loading before we send stuff to it
		
		; Make sure we're not focused on the toolbar - it doesn't accept hotkeys.
		if(ControlGetFocus("A") = this.ClassNN_F12DevToolsToolbar)
			Send, ^2 ; Focus Console tab
			Sleep, 100
			Send, ^1 ; Focus back to Dom Explorer tab - this should focus what's inside.
		
		Send, ^b ; Element picker hotkey
	}
	
	
	; #PRIVATE#
	static F12DevToolsTitleString := "ahk_class F12FrameWindow ahk_exe IEXPLORE.EXE"
	static ClassNN_F12DevToolsToolbar := "Internet Explorer_Server8"
	
	
	; #END#
}
