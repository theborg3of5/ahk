/* Class for duration information, which takes in a string with a particular format.
   
   Input string format:
		1 or more of Nu, where N is a number and u is a unit from the following list:
			h - Hours
			m - Minutes
			s - Seconds
	
	You may add/subtract time using the same units with .addTime() and .subTime(), and can get the breakdown of time into hour/minute/second units with the corresponding properties.
*/

class Duration {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	; Supported characters
	static Char_Hour   := "h" ; Hours
	static Char_Minute := "m" ; Minutes
	static Char_Second := "s" ; Seconds
	
	;---------
	; DESCRIPTION:    Hours/minutes/seconds in this duration.
	; NOTES:          These counts take into account the other units - for example, a Duration with
	;                 1:01:00 will return "1" for minutes (not 61 minutes).
	;---------
	hours {
		get {
			this.getUnitBreakdown(h)
			return h
		}
	}
	minutes {
		get {
			this.getUnitBreakdown("", m)
			return m
		}
	}
	seconds {
		get {
			this.getUnitBreakdown("", "", s)
			return s
		}
	}
	
	;---------
	; DESCRIPTION:    A string representation of the total time in the duration, broken down into
	;                 hours, minutes, and seconds. Hours (and their following :) are only included
	;                 if there are >0 hours, and minutes are the same (unless there are hours, in
	;                 which case minutes are always included). For example:
	;                   1:05:03
	;                   5:03
	;                   3
	;---------
	displayTime {
		get {
			this.getUnitBreakdown(hours, minutes, seconds)
			
			if(hours > 0)
				return hours ":" minutes.prepadToLength(2, "0") ":" seconds.prepadToLength(2, "0") ; h:mm:ss
			else if(minutes > 0)
				return minutes ":" seconds.prepadToLength(2, "0") ; m:ss
			else
				return seconds ; s
		}
	}
	
	;---------
	; DESCRIPTION:    Whether the duration has no time remaining.
	;---------
	isZero {
		get {
			return (this.durationTotalSeconds = 0)
		}
	}
	
	
	;---------
	; DESCRIPTION:    Create a new Duration object based on a duration string.
	; PARAMETERS:
	;  durationString (I,OPT) - A string describing how much time this Duration instance should
	;                           represent. See class header for format. If not given, we'll default
	;                           to no time (0 seconds).
	;---------
	__New(durationString := "") {
		if(durationString != "")
			this.addTimeFromDurationString(durationString)
		
		; Debug.popup("durationString",durationString, "this.durationTotalSeconds",this.durationTotalSeconds)
	}
	
	;---------
	; DESCRIPTION:    Add a certain amount of time to this Duration.
	; PARAMETERS:
	;  durationString (I,REQ) - A string describing how much time we should add to this Duration.
	;                           See class header for format.
	;---------
	addTimeFromDurationString(durationString) {
		currentNumber := ""
		Loop, Parse, durationString
		{
			if(Duration.isUnitChar(A_LoopField)) {
				this.addTime(currentNumber, A_LoopField)
				currentNumber := ""
				Continue
			}
			
			currentNumber .= A_LoopField ; Appending (as a string), not adding (as a number)
		}
	}
	
	;---------
	; DESCRIPTION:    Add/remove a certain amount of time to/from this Duration.
	; PARAMETERS:
	;  value    (I,REQ) - How much time to add or remove.
	;  unitChar (I,OPT) - Character (from Duration.Char_* constants) representing the unit you want
	;                     to add. Defaults to "s" (seconds).
	;---------
	addTime(value, unitChar := "s") {
		if(!this.isUnitChar(unitChar))
			return
		
		this.durationTotalSeconds += value * this._units[unitChar]
		
		; Debug.popup("Duration.addTime","Finish", "value",value, "unitChar",unitChar, "multiplier",this._units[unitChar], "Seconds added",value * this.getUnitMultiplier(unitChar), "this.durationTotalSeconds",this.durationTotalSeconds)
	}
	subTime(value, unitChar := "s") {
		this.addTime(-value, unitChar)
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	durationTotalSeconds := 0 ; The internal representation of all time (including hours, minutes, seconds)
	
	; All supported units, from largest to smallest.
	static _units := {Duration.Char_Hour:3600, Duration.Char_Minute:60, Duration.Char_Second:1} ; {unitChar: multiplierToSeconds}
	
	
	;---------
	; DESCRIPTION:    Check whether the provided unit character is supported.
	; PARAMETERS:
	;  char (I,REQ) - The character to check.
	; RETURNS:        True if it's supported, False otherwise.
	;---------
	isUnitChar(char) {
		return Duration._units.HasKey(char)
	}
	
	;---------
	; DESCRIPTION:    Get the conversion factor from the given unit character to seconds.
	; PARAMETERS:
	;  char (I,REQ) - The character to check.
	; RETURNS:        The number of seconds in the provided unit.
	;---------
	getUnitMultiplier(char) {
		if(char = "")
			return 0
		return Duration._units[char]
	}
	
	;---------
	; DESCRIPTION:    Break the current duration down into hours, minutes, and seconds.
	; PARAMETERS:
	;  hours   (O,OPT) - The number of hours in this Duration.
	;  minutes (O,OPT) - The number of minutes in this Duration (excluding hours).
	;  seconds (O,OPT) - The number of seconds in this Duration (excluding hours and minutes).
	;---------
	getUnitBreakdown(ByRef hours := "", ByRef minutes := "", ByRef seconds := "") {
		remainingSeconds := this.durationTotalSeconds
		
		For unit,multiplier in Duration._units {
			quantity := remainingSeconds // multiplier
			remainingSeconds -= quantity * multiplier
			
			if(unit = Duration.Char_Hour)
				hours := quantity
			if(unit = Duration.Char_Minute)
				minutes := quantity
			if(unit = Duration.Char_Second)
				seconds := quantity
		}
		
		; Debug.popup("this.durationTotalSeconds",this.durationTotalSeconds, "hours",hours, "minutes",minutes, "seconds",seconds)
	}
}
