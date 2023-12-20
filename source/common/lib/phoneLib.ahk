; Phone number and calling-related functions.

class PhoneLib {
	;region ==================== PUBLIC ====================",
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
	;endregion ================= PUBLIC ====================",
}
