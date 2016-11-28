; TortoiseSVN hotkeys.
#IfWinActive, ahk_class #32770
	
	; Fill the dlg box with the correct one from the below filepath.
	:*:.dlg::
	$^d::
		SetTitleMatchMode, 2
		
		if(WinActive("- Commit - TortoiseSVN")) { ; The ahk_class is shared among many, but I don't want it to work with all of them.
			SetTitleMatchMode, 1
			
			ControlGetText, svnURL, Edit1
			; MsgBox, % svnURL
			
			; May need to be tweaked as more is learned about URL structure.
			StringSplit, svnExplodedURL, svnURL, /
			; MsgBox, % svnExplodedURL12
			
			ControlFocus, Edit2
			
			Send, %svnExplodedURL12%
			Send, {Tab 2}
		} else {
			Send, ^d
		}
	return
	
#IfWinActive
