; Google Chrome hotkeys.
#IfWinActive, ahk_class Chrome_WidgetWin_1
	; Options hotkey.
	!o::
		Send, !e
		Sleep, 100
		Send, s
	return
	
	$^f::
		originalClipboard := clipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
		clipboard :=                      ; Clear the clipboard so we can tell when something is added by ^c.
		Send, ^c                          ; Copy selected text to the clipboard.
		
		Send, ^f                          ; Open the find box immediately so user can start typing if nothing was selected.
		
		ClipWait, 1                       ; Wait for the clipboard to actually contain data.
		selectedText := clipboard
		clipboard := originalClipboard    ; Restore the original clipboard. Note we're using clipboard (not clipboardAll).
		
		if(selectedText)                  ; If we found some text selected, pop it into the find box.
			SendRaw, % selectedText
		Send, ^a                          ; Select all in case they want to type something else.
	return
#IfWinActive
