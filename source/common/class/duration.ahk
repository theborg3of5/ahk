/* Class for duration information, which takes in a string with a particular format.
   
   Input string format:
		1 or more of Nu, where N is a number and u is a unit from the following list:
			h - Hours
			m - Minutes
			s - Seconds
	
	You may add/subtract time using the same units with .addTime() and .subTime(), and can get the breakdown of time into hour/minute/second units with the corresponding properties.
*/

global DURATIONCHAR_Hour   := "h"
global DURATIONCHAR_Minute := "m"
global DURATIONCHAR_Second := "s"

class Duration {
	; ==============================
	; == Public ====================
	; ==============================
	
	
	__New(durationString := "") {
		if(isEmpty(this.supportedUnitsAry))
			this.supportedUnitsAry := this.buildSupportedUnitsAry()
		
		if(durationString != "")
			this.loadFromDurationString(durationString)
		
		; DEBUG.popup("durationString",durationString, "this.durationTotalSeconds",this.durationTotalSeconds)
	}
	
	
	addTime(value, unitChar := "s") {
		if(unitChar = DURATIONCHAR_Hour)
			this.durationTotalSeconds += value * 3600 ; Hours   - 60 * 60 seconds
		else if(unitChar = DURATIONCHAR_Minute)
			this.durationTotalSeconds += value * 60   ; Minutes - 60 seconds
		else if(unitChar = DURATIONCHAR_Second)
			this.durationTotalSeconds += value        ; Seconds
		
		; DEBUG.popup("Duration.addTime","Finish", "value",value, "unitChar",unitChar, "this.durationTotalSeconds",this.durationTotalSeconds)
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
	
	
	isZero[] {
		get {
			return (this.durationTotalSeconds = 0)
		}
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static supportedUnitsAry := []
	durationTotalSeconds := 0
	
	buildSupportedUnitsAry() {
		supportedUnitsAry := []
		
		supportedUnitsAry.push(DURATIONCHAR_Hour)
		supportedUnitsAry.push(DURATIONCHAR_Minute)
		supportedUnitsAry.push(DURATIONCHAR_Second)
		
		return supportedUnitsAry
	}
	
	; Supported characters:
		;   h - hour
		;   m - minute
		;   s - second
	loadFromDurationString(durationString) {
		currentNumber := ""
		Loop, Parse, durationString
		{
			if(this.isUnitChar(A_LoopField)) {
				this.addTime(currentNumber, A_LoopField)
				currentNumber := ""
				Continue
			}
			
			currentNumber .= A_LoopField ; Appending (as a string), not adding (as a number)
		}
	}
	
	
	isUnitChar(char) {
		return arrayContains(this.supportedUnitsAry, char)
	}
	
	
	getUnitBreakdown(ByRef hours = "", ByRef minutes = "", ByRef seconds = "") {
		remainingSeconds := this.durationTotalSeconds
		
		hours := remainingSeconds // 3600  ; Hours   - 60 * 60 seconds
		remainingSeconds -= hours * 3600
		
		minutes := remainingSeconds // 60  ; Minutes - 60 seconds
		remainingSeconds -= minutes * 60
		
		seconds := remainingSeconds        ; Seconds
	}
}
