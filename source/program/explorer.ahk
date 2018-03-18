$#e::
	if(WinActive("ahk_class CabinetWClass"))
		Run, ::{20d04fe0-3aea-1069-a2d8-08002b30309d} ; Open the "This PC" special folder
	else if(!WinExist("ahk_class CabinetWClass"))
		Send, #e ; Open a new session if nothing exists
	else
		WinActivate ; Show the existing window
return

#IfWinActive, ahk_class CabinetWClass
	^l::
		Send, !d
	return
	
	^t::
		Run, ::{20d04fe0-3aea-1069-a2d8-08002b30309d} ; Open the "This PC" special folder
	return
#IfWinActive

#IfWinActive, ahk_exe explorer.exe
	; Hide/show hidden files. From http://www.autohotkey.com/forum/post-342375.html#342375
	#h::
		toggleHiddenFiles() {
			ValorHidden := RegRead("HKEY_CURRENT_USER", "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", "Hidden")
			
			if(ValorHidden = 2) {
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
			} else {
				RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
			}
			
			Send, {F5}
		}
#IfWinActive
