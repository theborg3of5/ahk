/* GDB TODO
	
	Example Usage
		GDB TODO
*/

class RelativeDateTimeBase {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    The calculated instant, based on the relative date string passed to the constructor.
	;---------
	Instant {
		get {
			return this._instant
		}
	}
	
	;---------
	; NOTES:          Should be overridden by child class.
	;---------
	__New(relativeDateTime := "") {
		new ErrorToast("RelativeDateTimeBase instance created", "RelativeDateTimeBase is a base class only, use a date/time-specific child class instead.").showMedium()
		return ""
	}
	
	;---------
	; DESCRIPTION:    Send the relative date/time in a particular format.
	; PARAMETERS:
	;  format (I,REQ) - The format to send the date/time in, a la FormatTime().
	;---------
	SendInFormat(format) {
		Send, % FormatTime(this._instant, format)
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	_instant := "" ; The actual timestamp that we calculate based on the relative date/time string.
	_year := ""
	_month := ""
	_day := ""
	_hour := ""
	_minute := ""
	_second := ""
	
	
	loadCurrentDateTime() {
		this._instant := A_Now
		
		this._year   := A_YYYY
		this._month  := A_MM
		this._day    := A_DD
		this._hour   := A_Hour
		this._minute := A_Min
		this._second := A_Sec
	}
	
	shiftByRelativeString(relativeString) {
		unit        := relativeString.sub(1, 1)
		operator    := relativeString.sub(2, 1)
		shiftAmount := relativeString.sub(3)
		
		; Make shiftAmount match unit (because we have to use EnvAdd/+= for date/time math)
		if(operator = "-")
			shiftAmount := -shiftAmount
		
		this.doShift(shiftAmount, unit)
	}
	
	updatePartsFromInstant() {
		this._year   := this._instant.sub(1,  4)
		this._month  := this._instant.sub(5,  2)
		this._day    := this._instant.sub(7,  2)
		this._hour   := this._instant.sub(9,  2)
		this._minute := this._instant.sub(11, 2)
		this._second := this._instant.sub(13, 2)
	}
	
	updateInstantFromParts() {
		year   :=  this._year.prePadToLength(4, "0")
		month  := this._month.prePadToLength(2, "0")
		day    :=   this._day.prePadToLength(2, "0")
		hour   :=  this._hour.prePadToLength(2, "0")
		minute :=  this._hour.prePadToLength(2, "0")
		second :=  this._hour.prePadToLength(2, "0")
		
		this._instant := year month day hour minute second
	}
}
