/* Class for duration information, which takes in a string with a particular format. --=
   
   Input string format:
		1 or more of nU, where n is a number and U is a unit from the following list:
			h - Hours
			m - Minutes
			s - Seconds
	
	You may add/subtract time using the same units with .addTime() and .subTime(), and can get the breakdown of time into hour/minute/second units with the corresponding properties.
	
*/ ; =--

class Duration {
	; #PUBLIC#
	
	; [[ Supported characters - conversion factors are in .unitConversionFactors ]]
	;---------
	; DESCRIPTION:    Hours
	;---------
	static Char_Hour   := "h"
	;---------
	; DESCRIPTION:    Minutes
	;---------
	static Char_Minute := "m"
	;---------
	; DESCRIPTION:    Seconds
	;---------
	static Char_Second := "s"
	
	;---------
	; DESCRIPTION:    Hours in this duration.
	;---------
	hours {
		get {
			this.getUnitBreakdown(h)
			return h
		}
	}
	;---------
	; DESCRIPTION:    Minutes in this duration.
	; NOTES:          This count takes into account larger units - for example, a Duration with
	;                 1:01:00 will return "1" for minutes (not 61 minutes).
	;---------
	minutes {
		get {
			this.getUnitBreakdown("", m)
			return m
		}
	}
	;---------
	; DESCRIPTION:    Seconds in this duration.
	; NOTES:          This count takes into account larger units - for example, a Duration with
	;                 1:01:01 will return "1" for seconds (not 3661 seconds).
	;---------
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
	; DESCRIPTION:    Add a certain amount of time to this Duration.
	; PARAMETERS:
	;  value    (I,REQ) - How much time to add.
	;  unitChar (I,OPT) - Character (from Duration.Char_* constants) representing the unit you want
	;                     to add. Defaults to "s" (seconds).
	;---------
	addTime(value, unitChar := "s") {
		if(!this.isUnitChar(unitChar))
			return
		
		this.durationTotalSeconds += value * this.unitConversionFactors[unitChar]
	}
	;---------
	; DESCRIPTION:    Remove a certain amount of time from this Duration.
	; PARAMETERS:
	;  value    (I,REQ) - How much time to remove.
	;  unitChar (I,OPT) - Character (from Duration.Char_* constants) representing the unit you want
	;                     to remove. Defaults to "s" (seconds).
	;---------
	subTime(value, unitChar := "s") {
		this.addTime(-value, unitChar)
	}
	
	
	; #PRIVATE#
	
	; All supported units, from largest to smallest, with their conversion to seconds.
	static unitConversionFactors := {Duration.Char_Hour:3600, Duration.Char_Minute:60, Duration.Char_Second:1} ; {unitChar: multiplierToSeconds}
	
	durationTotalSeconds := 0 ; The internal representation of all time (including hours, minutes, seconds)
	
	
	;---------
	; DESCRIPTION:    Check whether the provided unit character is supported.
	; PARAMETERS:
	;  char (I,REQ) - The character to check.
	; RETURNS:        True if it's supported, False otherwise.
	;---------
	isUnitChar(char) {
		return Duration.unitConversionFactors.HasKey(char)
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
		
		For unit,multiplier in Duration.unitConversionFactors {
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
	; #END#
}
