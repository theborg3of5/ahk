; Class for adding a hyperlink to the currently-selected text.

class Hyperlinker {
	; #PUBLIC#
	
	; [[ Methods for setting link information for the selected text ]] --=
	;---------
	; DESCRIPTION:    There's a popup with a field.
	;---------
	static Method_PopupField   := "POPUP_FIELD"
	;---------
	; DESCRIPTION:    There's a web "popup".
	;---------
	static Method_WebField     := "WEB_FIELD"
	;---------
	; DESCRIPTION:    It's text-based, where we'll generate the "link" (typically markdown) from a
	;                 string with <tags> for replacement.
	;---------
	static Method_TaggedString := "TAGGED_STRING"
	; =--
	
	; [[ Methods for closing the linking popup (when applicable) ]] --=
	;---------
	; DESCRIPTION:    Pressing enter.
	;---------
	static CloseMethod_Enter := "ENTER"
	;---------
	; DESCRIPTION:    Pressing alt+A.
	;---------
	static CloseMethod_Alt_A := "ALT_A"
	; =--
	
	;---------
	; DESCRIPTION:    Initialize this class with the windows that support hyperlinking and their methods.
	;---------
	Init() {
		this._windows := new TableList("hyperlinkWindows.tl").getRowsByColumn("NAME")
		; Debug.popup("Hyperlinker.Init",, "this._windows",this._windows)
	}
	
	;---------
	; DESCRIPTION:    Link the selected text with the given URL/path.
	; PARAMETERS:
	;  path         (I,REQ) - URL or file path to link to.
	;  errorMessage (O,OPT) - Error message about what went wrong if we return False.
	; RETURNS:        True if successful, False if something went wrong.
	;---------
	linkSelectedText(path, ByRef errorMessage := "") {
		if(!path) {
			errorMessage := "Path to link was blank"
			return false
		}
		
		path := FileLib.cleanupPath(path)
		windowName := Config.findWindowName()
		windowLinkInfoAry := Hyperlinker.getWindowLinkInfo(windowName)
		; Debug.popup("Hyperlinker.linkSelectedText","Finished gathering info", "windowName",windowName, "windowLinkInfoAry",windowLinkInfoAry, "Hyperlinker._windows",Hyperlinker._windows)
		
		if(!windowLinkInfoAry) {
			errorMessage := "Window not supported: " windowName
			return false
		}
		
		; Special handling
		if(windowName = "OneNote") ; OneNote can't handle double quotes in URLs for some reason, so encode them.
			path := path.replace("""", "%22")
		
		return Hyperlinker.doLink(path, windowLinkInfoAry, errorMessage)
	}
	
	
	; #PRIVATE#

	;---------
	; DESCRIPTION:    Associative array of windows information.
	; FORMAT:         First-level subscript is name. Second-level subscripts (i.e. _windows[<name>, "NAME"]):
	;                  ["NAME"]                  = Name of the window we're starting from,
	;                                              matches NAME column in windows.tl (also
	;                                              the <name> top-level subscript)
	;                  ["SET_PATH_METHOD"]       = Method that should be used to add the link,
	;                                              from the Hyperlinker.Method_* constants at the
	;                                              top of this file.
	;                  ["CLOSE_METHOD"]          = Method that should be used to close the linking
	;                                              popup (if applicable), from the Hyperlinker.CloseMethod_*
	;                                              constants at the top of this file.
	;                  ["LINK_POPUP"]            = If the method is Hyperlinker.Method_PopupField,
	;                                              this is the title string for the linking
	;                                              popup where we'll enter the path.
	;                  ["PATH_FIELD_CONTROL_ID"] = If the method is Hyperlinker.Method_PopupField,
	;                                              this is the control ID for the field where
	;                                              the path goes.
	;                  ["TAGGED_STRING_BASE"]    = If the method is Hyperlinker.Method_TaggedString,
	;                                              this is the "base" string that describes the
	;                                              format of the final linked string (that
	;                                              includes both the selected text and the path).
	;                                              It should include both <TEXT> and <PATH> tags
	;                                              for those respective bits of data.
	;---------
	static _windows := ""
	
	;---------
	; DESCRIPTION:    Grab the array of linking window info for the given starting window name.
	; PARAMETERS:
	;  windowName (I,REQ) - Starting window name, should match NAME column in windows.tl.
	; RETURNS:        Array of linking-related info about the window matching the given name. Format:
	;                    ary["NAME"]                  = Name of the window we're starting from,
	;                                                   matches NAME column in windows.tl (also the
	;                                                   <name> top-level subscript)
	;                       ["SET_PATH_METHOD"]       = Method that should be used to add the link,
	;                                                   from the Hyperlinker.Method_* constants at the
	;                                                   top of this file.
	;                       ["CLOSE_METHOD"]          = Method that should be used to close the linking
	;                                                   popup (if applicable), from the Hyperlinker.CloseMethod_*
	;                                                   constants at the top of this file.
	;                       ["LINK_POPUP"]            = If the method is Hyperlinker.Method_PopupField,
	;                                                   this is the title string for the linking
	;                                                   popup where we'll enter the path.
	;                       ["PATH_FIELD_CONTROL_ID"] = If the method is Hyperlinker.Method_PopupField,
	;                                                   this is the control ID for the field where
	;                                                   the path goes.
	;                       ["TAGGED_STRING_BASE"]    = If the method is Hyperlinker.Method_TaggedString,
	;                                                   this is the "base" string that describes the
	;                                                   format of the final linked string (that
	;                                                   includes both the selected text and the path).
	;                                                   It should include both <TEXT> and <PATH> tags
	;                                                   for those respective bits of data.
	;---------
	getWindowLinkInfo(windowName) {
		if(!windowName)
			return ""
		return Hyperlinker._windows[windowName]
	}
	
	;---------
	; DESCRIPTION:    Actually link the selected text with the given path, in whatever way is
	;                 required by our window-specific configuration.
	; PARAMETERS:
	;  path              (I,REQ) - URL or file path to link to.
	;  windowLinkInfoAry (I,REQ) - Array of linking-related info about the window matching the given
	;                              name. See getWindowLinkInfo() for format.
	;  errorMessage      (O,OPT) - Error message about what went wrong if we return False.
	; RETURNS:        True for success, False if something went wrong.
	;---------
	doLink(path, windowLinkInfoAry, ByRef errorMessage := "") {
		; Debug.toast("Hyperlinker.doLink","Start", "path",path, "windowLinkInfoAry",windowLinkInfoAry)
		
		; Handle linking differently depending on the specified method.
		setPathMethod := windowLinkInfoAry["SET_PATH_METHOD"]
		if(setPathMethod = Hyperlinker.Method_PopupField)
			return Hyperlinker.linkPopupField(path, windowLinkInfoAry["LINK_POPUP"], windowLinkInfoAry["PATH_FIELD_CONTROL_ID"], windowLinkInfoAry["CLOSE_METHOD"])
		if(setPathMethod = Hyperlinker.Method_WebField)
			return Hyperlinker.linkWebField(path, windowLinkInfoAry["CLOSE_METHOD"])
		if(setPathMethod = Hyperlinker.Method_TaggedString)
			return Hyperlinker.linkTaggedString(path, windowLinkInfoAry["TAGGED_STRING_BASE"])
		
		errorMessage := "Unsupported set path method: " setPathMethod
		return false
	}
	
	;---------
	; DESCRIPTION:    Link the selected text when the window in question offers a popup and a proper
	;                 (non-web-based) field.
	; PARAMETERS:
	;  path                 (I,REQ) - URL or file path to link to.
	;  linkPopupTitleString (I,REQ) - The title string for the linking popup where we'll enter the path.
	;  fieldControlId       (I,REQ) - The control ID for the field wherethe path goes.
	; RETURNS:        True for success, False if something went wrong.
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
	linkPopupField(path, linkPopupTitleString, fieldControlId, closeMethod) {
		if(!linkPopupTitleString || !fieldControlId || !closeMethod)
			return false
		
		; Launch linking popup and wait for it to open.
		Send, ^k
		WinWaitActive, % linkPopupTitleString
		if(ErrorLevel)
			return false
		
		; Set the value of the path field and accept the popup.
		ControlSetText, % fieldControlId, % path, A
		
		; Close the popup
		Hyperlinker.closeWithMethod(closeMethod)
		
		; Deselect the now-linked text
		Send, {Right}
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Link the selected text when the window in question offers a web-based popup.
	; PARAMETERS:
	;  path (I,REQ) - URL or file path to link to.
	; RETURNS:        True for success, False if something went wrong.
	;---------
	linkWebField(path, closeMethod) {
		if(!closeMethod)
			return false
		
		; Launch linking "popup" and wait for it to open (it's a web-based popup, no real window or fields).
		Send, ^k
		Sleep, 100
		
		; Set the value of the field and accept the "popup".
		Hyperlinker.setWebFieldValue(path)
		
		; Close the popup
		Sleep, 500 ; Wait an extra half a second for web popups, as some of them have to validate before we can accept.
		Hyperlinker.closeWithMethod(closeMethod)
		
		; Deselect the now-linked text
		Send, {Right}
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Set the currently focused web field to the given value using the clipboard,
	;                 double-checking that it worked.
	; PARAMETERS:
	;  value (I,REQ) - The value to set.
	; RETURNS:        true/false - whether we successfully set the value to what we want.
	;---------
	setWebFieldValue(value) {
		; Send our new value with the clipboard, then confirm it's correct by re-copying the field value (in case it just sent "v")
		WindowActions.selectAll() ; Select all so we overwrite anything already in the field
		ClipboardLib.send(value)
		if(Hyperlinker.webFieldMatchesValue(value))
			return true
		
		; If it didn't match, try a second time
		Sleep, 500
		WindowActions.selectAll()
		ClipboardLib.send(value)
		return Hyperlinker.webFieldMatchesValue(value)
	}
	
	;---------
	; DESCRIPTION:    Check whether the currently focused web field matches the given value.
	; PARAMETERS:
	;  value (I,REQ) - The value that the field should match.
	; RETURNS:        true/false - whether it matches.
	;---------
	webFieldMatchesValue(value) {
		WindowActions.selectAll()
		actualValue := SelectLib.getText()
		Send, {Right} ; Release the select all
		return (actualValue = value)
	}
	
	;---------
	; DESCRIPTION:    Link the selected text by adding it to a structured string that also includes
	;                 the path (i.e. markup-style links).
	; PARAMETERS:
	;  path             (I,REQ) - URL or file path to link to.
	;  taggedStringBase (I,REQ) - The "base" string that describes the format of the final linked
	;                             string (that includes both the selected text and the path). It
	;                             should include both <TEXT> (for the selected text we're linking)
	;                             and <PATH> (for the given path) tags.
	; RETURNS:        True for success, False if something went wrong.
	;---------
	linkTaggedString(path, taggedStringBase) {
		if(!taggedStringBase)
			return false
		
		; Grab the text that we're going to add a link to, then delete it - we're going to replace it
		; with the full link including both the text and the path.
		textToLink := SelectLib.getText()
		Send, {Backspace}
		
		; Build the full link string using the original text and path.
		linkedText := taggedStringBase.replaceTags({"TEXT":textToLink, "PATH":path})
		
		; Send the link string to the field (no accept, that's it).
		ClipboardLib.send(linkedText)
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Close the popup with the given method.
	; PARAMETERS:
	;  closeMethod (I,REQ) - The close method, from CloseMethod_* constants.
	;---------
	closeWithMethod(closeMethod) {
		if(closeMethod = Hyperlinker.CloseMethod_Enter)
			Send, {Enter}
		if(closeMethod = Hyperlinker.CloseMethod_Alt_A)
			Send, !a
	}
	; #END#
}
