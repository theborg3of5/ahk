#Include %A_LineFile%\..\..\class\debugTable.ahk
#Include %A_LineFile%\..\..\class\debugPopup.ahk

/* Static class to show debug information about whatever it's given.
		Mostly relies on DebugTable to generate the debug display, then wraps in a DebugPopup, Toast, etc. as requested.
*/ ;

class Debug {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Display a popup of information about the information provided. See class
	;                 documentation for information about how we handle labels, values, arrays,
	;                 and objects.
	; PARAMETERS:
	;  params (I,REQ) - A variable number of arguments to display in the popup. For 1 argument,
	;                   we will interpret it as a value (not a label), but for >1 arguments an
	;                   even number of arguments should be passed in label,value pairs.
	; NOTES:          This function won't do anything before Config has initialized; this
	;                 is to prevent massive numbers of popups when debugging a function that it
	;                 uses (from each of the different standlone scripts that run). If you need
	;                 to show a popup before that point, you can use the .popupEarly() function
	;                 instead.
	;---------
	popup(params*) {
		; Only start showing popups once Config is finished loading - popupEarly can be used if you want to show debug messages in these cases.
		if(!Config.isInitialized)
			return
		
		new DebugPopup(params*)
	}
	
	;---------
	; DESCRIPTION:    Same as .popup(), but will run before Config is initialized. See
	;                 .popup() for details and parameters.
	;---------
	popupEarly(params*) {
		new DebugPopup(params*)
	}
	
	;---------
	; DESCRIPTION:    Copy debug info about the provided parameters to the clipboard. Useful when
	;                 the debug info has too many lines to show in a popup or toast.
	; PARAMETERS:
	;  params* (I,REQ) - A variable number of arguments to display in the popup. For 1 argument,
	;                    we will interpret it as a value (not a label), but for >1 arguments an
	;                    even number of arguments should be passed in label,value pairs.
	;---------
	copy(params*) {
		table := new DebugTable().setBorderType(TextTable.BorderType_None)
		table.addPairs(params*)
		
		clipboard := table.getText()
	}
	
	;---------
	; DESCRIPTION:    Display a toast (brief, semi-transparent display in the bottom-right) of
	;                 information about the information provided. See class documentation for
	;                 information about how we handle labels, values, arrays, and objects.
	; PARAMETERS:
	;  params* (I,REQ) - A variable number of arguments to display in the popup. For 1 argument,
	;                    we will interpret it as a value (not a label), but for >1 arguments an
	;                    even number of arguments should be passed in label,value pairs.
	;---------
	toast(params*) {
		table := new DebugTable().setBorderType(TextTable.BorderType_BoldLine)
		table.addPairs(params*)
		
		new Toast(table.getText()).showLong()
	}
	; #END#
}
