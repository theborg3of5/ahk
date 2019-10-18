#If Config.isWindowActive("Explorer")
	; Focus address bar
	^l::Send, !d
		
	; Open "new tab" (to This PC)
	#e::
	^t::
		Run(Explorer.ThisPCFolderUUID)
	return
	
	; Copy current folder/file paths to clipboard
	!c::ClipboardLib.copyFilePathWithHotkey("!c")    ; Current file
	!#c::ClipboardLib.copyFolderPathWithHotkey("!c") ; Current folder
	
	; Hide/show hidden files
	#h::Explorer.toggleHiddenFiles()
#If

class Explorer {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	static ThisPCFolderUUID := "::{20d04fe0-3aea-1069-a2d8-08002b30309d}"
	
	;---------
	; DESCRIPTION:    Toggle whether hidden files are visible in Explorer or not.
	; NOTES:          Inspired by http://www.autohotkey.com/forum/post-342375.html#342375
	;---------
	toggleHiddenFiles() {
		; Get current state and pick the opposite to use now.
		currentState := RegRead(Explorer.ShowHiddenRegKeyName, Explorer.ShowHiddenRegValueName)
		if(currentState = 2) {
			new Toast("Showing hidden files...").showMedium()
			newValue := Explorer.HiddenState_Visible
		} else {
			new Toast("Hiding hidden files...").showMedium()
			newValue := Explorer.HiddenState_Hidden
		}
		
		; Set registry key for whether to show hidden files and refresh to apply.
		RegWrite, REG_DWORD, % Explorer.ShowHiddenRegKeyName, % Explorer.ShowHiddenRegValueName, % newValue
		Send, {F5}
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	static ShowHiddenRegKeyName := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
	static ShowHiddenRegValueName := "Hidden"
	
	; Whether we're currently hiding or showing hidden files.
	static HiddenState_Visible := 1
	static HiddenState_Hidden  := 2
}