
;---------
; DESCRIPTION:    Set the clipboard to the given HTML, as HTML (not plain text).
;                 From https://www.autohotkey.com/boards/viewtopic.php?p=537060&sid=0c4d70d7020e18e8a1e8dc3209247681#p537060
;                 Once I upgrade to AHK v2, consider this approach instead: https://www.autohotkey.com/boards/viewtopic.php?p=513187#p513187
; PARAMETERS:
;  Html (I,REQ) - The HTML string (like "<a href=...>...</a>") to set.
;---------
SetClipboardHTML(Html) {
	; 74 is the length of this whole prefix, Format() just pads the total length to 5 digits
	Html := "Version:0.9`nStartHTML:-1`nEndHTML:-1`nStartFragment:00074`nEndFragment:" Format("{:05u}", StrLen(Html) + 74) "`n" Html

	DllCall("OpenClipboard", "Ptr", A_ScriptHwnd)
	DllCall("EmptyClipboard")
	
	hMem := DllCall("GlobalAlloc", "UInt", 0x42, "Ptr", StrPut(Html, "cp0"), "Ptr")
	StrPut(Html, DllCall("GlobalLock", "Ptr", hMem, "Ptr"), "cp0")
	DllCall("GlobalUnlock", "Ptr", hMem)
	
	DllCall("SetClipboardData", "UInt", DllCall("RegisterClipboardFormat", "Str", "HTML Format"), "Ptr", hMem)
	DllCall("CloseClipboard")
}