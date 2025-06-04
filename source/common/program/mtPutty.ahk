class MTPutty {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Attach all orphaned PuTTY windows to the MTPutty window.
	;---------
	attachOrphanedPuttyWindows() {
		this.focusParentWindow()

		Send, ^+a                               ; Attach PuTTY session (configured in MTPutty)
		WinWaitActive, Attach, , 5              ; Wait up to 5s for the attach window to become active
		Send, {Tab 2}                           ; Tab to window list
		Send, {Home}{Shift Down}{End}{Shift Up} ; Select the whole thing
		Send, {Enter}                           ; Submit
	}

	;---------
	; DESCRIPTION:    Rename the tab to match its corresponding PuTTY window's window title. When you
	;                 attach an orphaned window, it just uses the process ID as the tab title.
	;---------
	fixPuttyTabTitle() {
		this.focusParentWindow()
		Send, {F2}    ; Launch the rename window
		Send, {Enter} ; Accept with blank value (restores default)
		
		; Currently focus stays on the top-level window - the user can hit the ^` hotkey to get back to the
		; tab, but for some reason AHK can't.
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	;---------
	; DESCRIPTION:    Focus the parent (top-level) window of MTPutty. This is the window that contains all the tabs.
	;---------
	focusParentWindow() {
		; The first time this gets focus, it focuses its active child window - focusing it twice gets us to
		; the actual top-level window.
		WindowActions.activateWindowByName("MTPutty")
		WindowActions.activateWindowByName("MTPutty")
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
