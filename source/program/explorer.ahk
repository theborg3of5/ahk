; Since win+e is ceded to FreeCommander, give explorer something different.
!#e::
	Send, #e
return
~$#e::
	; Don't close if this is the first tab to open.
	if(!WinExist("ahk_class CabinetWClass"))
		return
	
	if(!WinActive("ahk_class CabinetWClass")) { ; Explorer gets focused, but close the tab.
		WinWaitActive, ahk_class CabinetWClass
		Send, ^w
	}
return

#IfWinActive, ahk_class CabinetWClass
	; Firefox-like ctrl+l shortcut
	^l::
		Send, !d
	return
#IfWinActive

#IfWinActive, ahk_exe explorer.exe
	; Hide/show hidden files. From http://www.autohotkey.com/forum/post-342375.html#342375
	#h::
		RegRead, ValorHidden, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden
		
		if(ValorHidden = 2) {
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 1
		} else {
			RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced, Hidden, 2
		}
		
		Send, {F5}
	return
#IfWinActive
