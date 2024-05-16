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
;		rt := new RelativeTime("h+5") ; 5 hours in the future, at the time this line runs
;		newTime := rt.instant         ; Get the calculated instant
;		rt.SendInFormat("hh:mm:ss")   ; Send the calculated date in a specific format
	
*/

class RelativeTime extends RelativeDateTimeBase {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Create a new representation of a time relative to right now.
	; PARAMETERS:
	;  relativeTime (I,REQ) - The relative time string to use to find the new time.
	;---------
	__New(relativeTime) {
		this.loadCurrentDateTime()
		this.shiftByRelativeString(relativeTime)
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
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
	;endregion ------------------------------ PRIVATE ------------------------------
}
