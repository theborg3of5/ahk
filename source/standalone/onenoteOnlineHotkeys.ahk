; Click specific buttons in Onenote's online interface with hotkeys that mirror the desktop version.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
DetectHiddenWindows, On

^+=::
	Click, 428, 279
	Click, 428, 340
return

^=::
	Click, 428, 279
	Click, 428, 310 
return