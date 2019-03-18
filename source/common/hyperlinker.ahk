/* Class for adding a hyperlink to the currently-selected text.
	
	***
*/

global LinkPathMethod_PopupField   := "POPUP_FIELD"
global LinkPathMethod_WebField     := "WEB_FIELD"
global LinkPathMethod_TaggedString := "TAGGED_STRING"

class Hyperlinker {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Link the selected text with the given URL/path.
	; PARAMETERS:
	;  path (I,REQ) - URL or file path to link to.
	; RETURNS:        True if successful, False if something went wrong.
	;---------
	linkSelectedText(path) {
		if(!path)
			return false
		
		path := cleanupPath(path)
		path := mapPath(path)
		
		if(!isObject(Hyperlinker.windows))
			Hyperlinker.windows := Hyperlinker.getWindows()
		
		windowName := MainConfig.findWindowName()
		windowLinkInfoAry := Hyperlinker.getWindowLinkInfo(windowName)
		if(!windowLinkInfoAry)
			return false
		; DEBUG.toast("Hyperlinker.linkSelectedText","Finished gathering info", "windowName",windowName, "windowLinkInfoAry",windowLinkInfoAry)
		
		return Hyperlinker.doLink(path, windowLinkInfoAry)
	}
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static windows := ""
	
	;---------
	; DESCRIPTION:    Read the link windows config file into an indexed-by-name array of windows' info.
	; RETURNS:        Array of arrays of window info. Format:
	;                    ary[<name>]["NAME"]                  = Name of the window we're starting from,
	;                                                           matches NAME column in windows.tl (also
	;                                                           the <name> top-level subscript)
	;                               ["SET_PATH_METHOD"]       = Method that should be used to add the link,
	;                                                           from the LinkPathMethod_* constants at the
	;                                                           top of this file.
	;                               ["LINK_POPUP"]            = If the method is LinkPathMethod_PopupField,
	;                                                           this is the title string for the linking
	;                                                           popup where we'll enter the path.
	;                               ["PATH_FIELD_CONTROL_ID"] = If the method is LinkPathMethod_PopupField,
	;                                                           this is the control ID for the field where
	;                                                           the path goes.
	;                               ["TAGGED_STRING_BASE"]    = If the method is LinkPathMethod_TaggedString,
	;                                                           this is the "base" string that describes the
	;                                                           format of the final linked string (that
	;                                                           includes both the selected text and the path).
	;                                                           It should include both <TEXT> and <PATH> tags
	;                                                           for those respective bits of data.
	;---------
	getWindows() {
		tl := new TableList(findConfigFilePath("hyperlinkWindows.tl"))
		return reIndexArrayBySubscript(tl.getTable(), "NAME")
	}
	
	;---------
	; DESCRIPTION:    Grab the array of linking window info for the given starting window name.
	; PARAMETERS:
	;  windowName (I,REQ) - Starting window name, should match NAME column in windows.tl.
	; RETURNS:        Array of linking-related info about the window matching the given name. Format:
	;                    ary["NAME"]                  = Name of the window we're starting from,
	;                                                   matches NAME column in windows.tl (also the
	;                                                   <name> top-level subscript)
	;                       ["SET_PATH_METHOD"]       = Method that should be used to add the link,
	;                                                   from the LinkPathMethod_* constants at the
	;                                                   top of this file.
	;                       ["LINK_POPUP"]            = If the method is LinkPathMethod_PopupField,
	;                                                   this is the title string for the linking
	;                                                   popup where we'll enter the path.
	;                       ["PATH_FIELD_CONTROL_ID"] = If the method is LinkPathMethod_PopupField,
	;                                                   this is the control ID for the field where
	;                                                   the path goes.
	;                       ["TAGGED_STRING_BASE"]    = If the method is LinkPathMethod_TaggedString,
	;                                                   this is the "base" string that describes the
	;                                                   format of the final linked string (that
	;                                                   includes both the selected text and the path).
	;                                                   It should include both <TEXT> and <PATH> tags
	;                                                   for those respective bits of data.
	;---------
	getWindowLinkInfo(windowName) {
		if(!windowName)
			return ""
		return Hyperlinker.windows[windowName]
	}
	
	;---------
	; DESCRIPTION:    Actually link the selected text with the given path, in whatever way is
	;                 required by our window-specific configuration.
	; PARAMETERS:
	;  path              (I,REQ) - URL or file path to link to.
	;  windowLinkInfoAry (I,REQ) - Array of linking-related info about the window matching the given
	;                              name. See getWindowLinkInfo() for format.
	; RETURNS:        True for success, False if something went wrong.
	;---------
	doLink(path, windowLinkInfoAry) {
		; DEBUG.toast("Hyperlinker.doLink","Start", "path",path, "windowLinkInfoAry",windowLinkInfoAry)
		
		; Handle linking differently depending on the specified method.
		setPathMethod := windowLinkInfoAry["SET_PATH_METHOD"]
		if(setPathMethod = LinkPathMethod_PopupField)
			return Hyperlinker.linkPopupField(path, windowLinkInfoAry["LINK_POPUP"], windowLinkInfoAry["PATH_FIELD_CONTROL_ID"])
		if(setPathMethod = LinkPathMethod_WebField)
			return Hyperlinker.linkWebField(path)
		if(setPathMethod = LinkPathMethod_TaggedString)
			return Hyperlinker.linkTaggedString(path, windowLinkInfoAry["TAGGED_STRING_BASE"])
		
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
	linkPopupField(path, linkPopupTitleString, fieldControlId) {
		if(!linkPopupTitleString || !fieldControlId)
			return false
		
		; Launch linking popup and wait for it to open.
		Send, ^k
		WinWaitActive, % linkPopupTitleString
		if(ErrorLevel)
			return false
		
		; Set the value of the path field and accept the popup.
		ControlSetText, % fieldControlId, % path, A
		Send, {Enter}
		
		return true
	}
	
	;---------
	; DESCRIPTION:    Link the selected text when the window in question offers a web-based popup.
	; PARAMETERS:
	;  path (I,REQ) - URL or file path to link to.
	; RETURNS:        True for success, False if something went wrong.
	;---------
	linkWebField(path) {
		; Launch linking "popup" and wait for it to open (it's a web-based popup, no real window or fields).
		Send, ^k
		Sleep, 100
		
		; Set the value of the field and accept the "popup".
		setWebFieldValue(path)
		Send, !a
		
		return true
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
		textToLink := getSelectedText()
		Send, {Backspace}
		
		; Build the full link string using the original text and path.
		linkedText := taggedStringBase
		linkedText := replaceTag(linkedText, "TEXT", textToLink)
		linkedText := replaceTag(linkedText, "PATH", path)
		
		; Send the link string to the field (no accept, that's it).
		sendTextWithClipboard(linkedText)
		
		return true
	}
}