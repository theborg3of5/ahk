#If MainConfig.isWindowActive("Explorer")
	; Focus address bar
	^l::
		Send, !d
	return
	
	; Open "new tab"
	^t::
		Run, % FOLDER_UUID_THISPC
	return
	
	; Copy current file path to clipboard
	!c::copyFilePathWithHotkey("!c")
	; Copy current folder path to clipboard
	!#c::copyFolderPathWithHotkey("^!c")
	
	; Hide/show hidden files. From http://www.autohotkey.com/forum/post-342375.html#342375
	#h::
		explorerToggleHiddenFiles() {
			ValorHidden := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "Hidden")
			
			if(ValorHidden = 2) {
				Toast.showMedium("Showing hidden files...")
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
			} else {
				Toast.showMedium("Hiding hidden files...")
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
			}
			
			Send, {F5}
		}
#If

$#e::
	if(MainConfig.isWindowActive("Explorer"))
		Run(FOLDER_UUID_THISPC) ; Open the "This PC" special folder
	else if(!MainConfig.doesWindowExist("Explorer"))
		Send, #e ; Open a new session if nothing exists
	else
		WinActivate ; Show the existing window
return
