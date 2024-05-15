/* Base class for relative date/time classes.
	
	Should not be used directly, only extended.
	
*/

class RelativeDateTimeBase {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    The calculated instant, based on the relative date string passed to the constructor.
	;---------
	instant {
		get {
			return this._instant
		}
	}
	
	;---------
	; NOTES:          Should be overridden by child class.
	;---------
	__New() {
		Toast.ShowError("RelativeDateTimeBase instance created", "RelativeDateTimeBase is a base class only, use a date/time-specific child class instead.")
		return ""
	}
	
	;---------
	; DESCRIPTION:    Send the relative date/time in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to send the date/time in, a la FormatTime().
	;---------
	sendInFormat(format) {
		Send, % FormatTime(this._instant, format)
	}
	
	
	; #INTERNAL#
	
	; The current value for different time units.
	year    := ""
	month   := ""
	day     := ""
	hour    := ""
	minute  := ""
	second  := ""
	
	;---------
	; DESCRIPTION:    Load the current date and time into class members.
	;---------
	loadCurrentDateTime() {
		this._instant := A_Now
		
		this.year   := A_YYYY
		this.month  := A_MM
		this.day    := A_DD
		this.hour   := A_Hour
		this.minute := A_Min
		this.second := A_Sec
	}
	
	;---------
	; DESCRIPTION:    Split up the relative date/time string and call into the child class to
	;                 perform the shift.
	; PARAMETERS:
	;  relativeString (I,REQ) - The relative date/time string, in format:
	;                            <unitLetter><operator><shiftAmount>
	;                           Where unitLetter is the letter for the unit, operator is + or -, and
	;                           shiftAmount is how many to add/subtract.
	;---------
	shiftByRelativeString(relativeString) {
		unit        := relativeString.sub(1, 1)
		operator    := relativeString.sub(2, 1)
		shiftAmount := relativeString.sub(3)
		
		; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
		if(operator = "-")
			shiftAmount := operator shiftAmount ; Append instead of negating to preserve special day-of-week cases like "t+2m"
		
		this.doShift(shiftAmount, unit)
	}
	
	;---------
	; DESCRIPTION:    Update the individual member variables for different units based on the instant.
	;---------
	updatePartsFromInstant() {
		this.year   := this._instant.sub(1,  4)
		this.month  := this._instant.sub(5,  2)
		this.day    := this._instant.sub(7,  2)
		this.hour   := this._instant.sub(9,  2)
		this.minute := this._instant.sub(11, 2)
		this.second := this._instant.sub(13, 2)
	}
	
	;---------
	; DESCRIPTION:    Update the instant based on the individual member variables for different units.
	;---------
	updateInstantFromParts() {
		year   :=   this.year.prePadToLength(4, "0")
		month  :=  this.month.prePadToLength(2, "0")
		day    :=    this.day.prePadToLength(2, "0")
		hour   :=   this.hour.prePadToLength(2, "0")
		minute := this.minute.prePadToLength(2, "0")
		second := this.second.prePadToLength(2, "0")
		
		this._instant := year month day hour minute second
	}
	
	;---------
	; DESCRIPTION:    Perform the date or time shift.
	; NOTES:          Just shows an error - should be overridden by the child class.
	;---------
	doShift(shiftAmount, unit) {
		Toast.ShowError("RelativeDateTimeBase.doShift called", "The child class should override doShift().")
	}
	
	
	; #PRIVATE#
	
	_instant := "" ; The actual timestamp that we calculate based on the relative date/time string.
	; #END#
}
