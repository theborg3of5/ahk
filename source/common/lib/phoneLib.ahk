; Phone number and calling-related functions.

class PhoneLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Format a local (10-digit) phone number with parens/spaces/dash.
	; PARAMETERS:
	;  input (I,REQ) - The number for format.
	; RETURNS:        The formatted number, in format:
	;                  (XXX) XXX-XXXX
	;---------
	formatNumber(input) { ; Only works for non-international phone numbers.
		number := input.removeRegEx("[^0-9]") ; Strip everything except the digits.
		number := number.sub(-9) ; Last 10 chars only.
		return "(" number.sub(1, 3) ") " number.sub(4, 3) "-" number.sub(7, 4)
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string is a valid phone number.
	; PARAMETERS:
	;  number (I,REQ) - The string to evaluate
	; RETURNS:        true/false - whether it's a valid phone number.
	;---------
	isValidNumber(number) {
		if(!Config.contextIsWork)
			return false
		
		return (PhoneLib.getRawNumber(number) != "") ; Returns "" if it's not a valid number
	}
	
	;---------
	; DESCRIPTION:    Parse and process the given phone number into a valid number to call from work.
	; PARAMETERS:
	;  input (I,REQ) - The input string to parse.
	; RETURNS:        The processed number, or "HANGUP" if that was passed in.
	;---------
	getRawNumber(input) {
		; Special case - hang up
		if(input = "HANGUP")
			return input
		
		number := input
		number := number.removeRegEx("[^0-9\+]") ; Strip out anything that's not a number (or plus)
		number := number.replaceRegEx("\+", "011") ; + becomes country exit code (USA code here)
		
		Switch number.length() {
			Case 4:  return "7"  number ; Old extension.
			Case 5:  return      number ; Extension.
			Case 7:  return      number ; Normal
			Case 10: return "81" number ; Normal with area code.
			Case 11: return "8"  number ; Normal with 1 + area code at beginning.
			Case 12: return      number ; Normal with 8 + 1 + area code at beginning.
			Case 14: return "8"  number ; International number with exit code, just needs 8 to get out.
			Case 15: return      number ; International number with 2-digit exit code and 8, should be set.
			Case 16: return      number ; International number with 3-digit exit code and 8, should be set.
			Default: return ""          ; We don't know how to handle this number of digits, wipe the number.
		}
	}
	
	;---------
	; DESCRIPTION:    Dials a given number using the Cisco WebDialer API.
	; PARAMETERS:
	;  formattedNum (I,REQ) - An optionally-formatted phone number to call.
	;  name         (I,OPT) - If this is given, we'll show a name above the formatted number.
	;---------
	call(formattedNum, name := "") {
		; Get the raw number (with leading digits as needed) to plug into the URL.
		rawNumber := PhoneLib.getRawNumber(formattedNum)
		if(rawNumber = "") {
			Toast.ShowError("Could not make call", "Phone number is invalid: " formattedNum)
			return
		}
		
		; Confirm the user wants to call.
		if(!PhoneLib.confirmCall(rawNumber, formattedNum, name))
			return
		
		; Build the URL.
		url := PhoneLib.buildWebDialerURL(rawNumber)
		if(!url)
			return
		
		; Dial with a web request.
		HTTPRequest(url, In := "", Out := "")
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	;---------
	; DESCRIPTION:    Show the user a confirmation popup for the call we're about to make.
	; PARAMETERS:
	;  rawNum       (I,REQ) - The number we'll actually call. Will be shown last in square brackets.
	;  formattedNum (I,REQ) - The formatted version of the number we're going to call. It will be
	;                         shown above the raw number.
	;  name         (I,OPT) - An optional name to show above the formatted number.
	; RETURNS:        true/false - whether the user said to continue making the call.
	;---------
	confirmCall(rawNum, formattedNum, name := "") {
		if(!rawNum || !formattedNum)
			return false
		
		if(formattedNum = "HANGUP") {
			title          := "Hang up?"
			messageText    := "Hanging up current call. `n`nContinue?"
		} else {
			title          := "Dial number?"
			messageText    := "Calling: `n`n"
			if(name)
				messageText .= name "`n"
			messageText    .= formattedNum "`n"
			messageText    .= "[" rawNum "] `n`n"
			messageText    .= "Continue?"
		}
		
		return GuiLib.showConfirmationPopup(messageText, title)
	}
	
	;---------
	; DESCRIPTION:    Build the URL for Cisco WebDialer to make a call from my desk.
	; PARAMETERS:
	;  rawNumber (I,REQ) - The number to call, in a format (including 8, 81, etc. as needed) that WebDialer understands.
	; RETURNS:        The finished URL to run to make the call.
	;---------
	buildWebDialerURL(rawNumber) {
		if(!rawNumber)
			return ""
		if(!Config.contextIsWork)
			return ""
		
		if(rawNumber = "HANGUP")
			command := "HangUpCall?"
		else
			command := "CallNumber?extension=" rawNumber
		
		return Config.private["CISCO_PHONE_BASE"].replaceTag("COMMAND", command)
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
