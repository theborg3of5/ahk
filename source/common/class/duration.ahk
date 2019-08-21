/* Class for duration information, which takes in a string with a particular format.
   
   Input string format:
		1 or more of Nu, where N is a number and u is a unit from the following list:
			h - Hours
			m - Minutes
			s - Seconds
	
	You may add/subtract time using the same units with .addTime() and .subTime(), and can get the breakdown of time into hour/minute/second units with the corresponding properties.
*/

class Duration {

; ==============================
; == Public ====================
; ==============================
	; Supported characters:
	static Char_Hour   := "h" ; Hours
	static Char_Minute := "m" ; Minutes
	static Char_Second := "s" ; Seconds
	
	
	__New(durationString := "") {
		if(!Duration.supportedUnitsAry)
			Duration.buildUnitArrays()
		
		if(durationString != "")
			this.addTimeFromDurationString(durationString)
		
		; DEBUG.popup("durationString",durationString, "this.durationTotalSeconds",this.durationTotalSeconds)
	}
	
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
	
	
	addTime(value, unitChar := "s") {
		if(!this.isUnitChar(unitChar))
			return
		
		this.durationTotalSeconds += value * this.getUnitMultiplier(unitChar)
		
		; DEBUG.popup("Duration.addTime","Finish", "value",value, "unitChar",unitChar, "multiplier",this.getUnitMultiplier(unitChar), "Seconds added",value * this.getUnitMultiplier(unitChar), "this.durationTotalSeconds",this.durationTotalSeconds)
	}
	
	
	subTime(value, unitChar := "s") {
		this.addTime(-value, unitChar)
	}
	
	
	hours[] {
		get {
			this.getUnitBreakdown(h)
			return h
		}
	}
	
	
	minutes[] {
		get {
			this.getUnitBreakdown("", m)
			return m
		}
	}
	
	
	seconds[] {
		get {
			this.getUnitBreakdown("", "", s)
			return s
		}
	}
	
	
	displayTime[] {
		get {
			this.getUnitBreakdown(hours, minutes, seconds)
			timeString := ""
			
			if(hours > 0)
				timeString .= hours ":"
			if(minutes > 0)
				timeString .= minutes.prepadToLength(2, "0") ":"
			timeString .= seconds.prepadToLength(2, "0")
			
			return timeString
		}
	}
	
	
	isZero[] {
		get {
			return (this.durationTotalSeconds = 0)
		}
	}
	
	
; ==============================
; == Private ===================
; ==============================
	static supportedUnitsAry := ""
	static unitMultiplierAry := ""
	durationTotalSeconds := 0
	
	buildUnitArrays() {
		; Supported units, ordered from largest to smallest.
		Duration.supportedUnitsAry := []
		Duration.supportedUnitsAry.push(Duration.Char_Hour)
		Duration.supportedUnitsAry.push(Duration.Char_Minute)
		Duration.supportedUnitsAry.push(Duration.Char_Second)
		
		; Multiplers to turn each unit into seconds.
		Duration.unitMultiplierAry := []
		Duration.unitMultiplierAry[Duration.Char_Hour]   := 60 * 60
		Duration.unitMultiplierAry[Duration.Char_Minute] := 60
		Duration.unitMultiplierAry[Duration.Char_Second] := 1
	}
	
	
	isUnitChar(char) {
		return Duration.supportedUnitsAry.contains(char)
	}
	
	
	getUnitMultiplier(char) {
		if(char = "")
			return 0
		return Duration.unitMultiplierAry[char]
	}
	
	
	getUnitBreakdown(ByRef hours := "", ByRef minutes := "", ByRef seconds := "") {
		remainingSeconds := this.durationTotalSeconds
		
		For _,unit in Duration.supportedUnitsAry {
			multiplier := Duration.getUnitMultiplier(unit)
			quantity := remainingSeconds // multiplier
			remainingSeconds -= quantity * multiplier
			
			if(unit = Duration.Char_Hour)
				hours := quantity
			if(unit = Duration.Char_Minute)
				minutes := quantity
			if(unit = Duration.Char_Second)
				seconds := quantity
		}
		
		; DEBUG.popup("this.durationTotalSeconds",this.durationTotalSeconds, "hours",hours, "minutes",minutes, "seconds",seconds)
	}
}
