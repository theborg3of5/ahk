/* Calculates and sends a time relative to the class's instantiation (or the user submitting their relative time string, if one not provided to the constructor).
	
	Relative time string format
		The relative time string is in this format:
			<Unit><Operator><ShiftAmount>
				Unit        - The unit to shift the time by (see "Units" section below)
				Operator    - Plus (+) or minus (-) for the direction to shift
				ShiftAmount - How much to shift the time by, in the provided unit
	
	Units
		This class supports a few time units, including:
			h - hours
			m - minutes
			n - minutes (stands for "now")
			s - seconds
	
	Example Usage
		rt := new RelativeTime("h+5") ; 5 hours in the future, at the time this line runs
		newTime := rt.Instant         ; Get the calculated instant
		rt.SendInFormat("hh:mm:ss")   ; Send the calculated date in a specific format
*/

class RelativeTime {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    The calculated instant, based on the relative time string passed to the constructor.
	;---------
	Instant {
		get {
			return this._instant
		}
	}
	
	;---------
	; DESCRIPTION:    Create a new representation of a time relative to right now.
	; PARAMETERS:
	;  relativeTime (I,OPT) - The relative time string to use to find the new time. If not provided,
	;                         we'll prompt the user for it.
	;---------
	__New(relativeTime := "") {
		; If no time is passed, prompt the user for a relative one.
		if(relativeTime = "")
			relativeTime := InputBox("Enter relative time string", , , 300, 100)
		if(relativeTime = "")
			return ""
		
		this._instant := this.parseRelativeTime(relativeTime)
	}
	
	;---------
	; DESCRIPTION:    Send the relative time in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to send the date in, a la FormatTime().
	;---------
	SendInFormat(format) {
		Send, % FormatTime(this._instant, format)
	}

	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	_instant := "" ; The actual timestamp that we calculate based on the relative time string.
	
	;---------
	; DESCRIPTION:    Turn the relative time string into a timestamp, relative to right now.
	; PARAMETERS:
	;  relativeTime (I,REQ) - The relative time string. Format is <Unit><Operator><ShiftAmount>, e.g.
	;                         h+5 for 5 hours from now, and m-3 (or n-3) for 3 minutes ago. See
	;                         class documentation for supported units, operators, etc.
	; RETURNS:        The instant matching the relative time.
	;---------
	parseRelativeTime(relativeTime) {
		unit        := relativeTime.sub(1, 1)
		operator    := relativeTime.sub(2, 1)
		shiftAmount := relativeTime.sub(3)
		
		; Relative minutes can actually be written as a "n" for now - switch it out if that's the case here.
		if(unit = "n")
			unit := "m"
		
		; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
		if(operator = "-")
			shiftAmount := -shiftAmount
		
		; Do the shift
		outDateTime := A_Now
		outDateTime += shiftAmount, %unit%
		
		return outDateTime
	}
}
