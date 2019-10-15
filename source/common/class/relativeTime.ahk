#Include ..\base\relativeDateTimeBase.ahk

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

class RelativeTime extends RelativeDateTimeBase {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Create a new representation of a time relative to right now.
	; PARAMETERS:
	;  relativeTime (I,OPT) - The relative time string to use to find the new time. If not provided,
	;                         we'll prompt the user for it.
	;---------
	__New(relativeTime := "") {
		this.loadCurrentDateTime()
		
		; If no relative time string is passed, prompt the user for a relative one.
		if(relativeTime = "")
			relativeTime := InputBox("Enter relative time string", , , 300, 100)
		if(relativeTime = "")
			return ""
		
		this.shiftByRelativeString(relativeTime)
	}

	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Handle the actual time shift relative to now.
	; PARAMETERS:
	;  shiftAmount (I,REQ) - The amount to shift
	;  unit        (I,REQ) - The unit to shift in
	;---------
	doShift(shiftAmount, unit) {
		if(unit = "n") ; Relative minutes can also be written as "n" for now.
			unit := "m"
		
		; All of the time units (hours, minutes, seconds) are supported by EnvAdd(), so just use that.
		this._instant := EnvAdd(this._instant, shiftAmount, unit) ; Can't use += format because it doesn't support this.*-style variable names.
		this.updatePartsFromInstant()
	}
}
