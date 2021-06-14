class Onetastic {
	; #INTERNAL#

	;---------
	; DESCRIPTION:    Open the XML popup for the current macro or function.
	;---------
	openEditXMLPopup() {
		Send, !u ; Function
		Send, x  ; Edit XML
		WinWaitActive, Edit XML
	}

	;---------
	; DESCRIPTION:    Copy the XML for the current macro or function.
	;---------
	copyCurrentXML() {
		Onetastic.openEditXMLPopup()
		xml := ControlGetText("Edit1", "A")
		
		ClipboardLib.set(xml) ; Can't use ClipboardLib.setAndToast() because we don't want to show all of the XML
		if(Clipboard = "")
			new ErrorToast("Failed to get XML").showMedium()
		else
			new Toast("Clipboard set to new XML").showMedium()
		
		if(xml)
			Send, {Esc} ; Close the popup
	}
	; #END#
}
