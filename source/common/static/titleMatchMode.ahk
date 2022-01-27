; The title match mode
class TitleMatchMode {
	; #PUBLIC#
	
	; @GROUP@ Title match mode options
	static Start    := 1       ; The title must start with the string.
	static Contains := 2       ; The title may contain the string anywhere inside.
	static Exact    := 3       ; The title must exactly equal the string.
	static RegEx    := "RegEx" ; The title must match the provided regex.
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Map a set of string values, to the actual numeric values that will work with SetTitleMatchMode.
	; PARAMETERS:
	;  stringMode (I,REQ) - String version of any match mode (see .MatchModeString_*).
	; RETURNS:        Value from TitleMatchMode.* that can be used with SetTitleMatchMode.
	;---------
	convertFromString(stringMode) {
		Switch stringMode {
			Case this.MatchModeString_Start:    return this.Start
			Case this.MatchModeString_Contains: return this.Contains
			Case this.MatchModeString_Exact:    return this.Exact
			Case this.MatchModeString_RegEx:    return this.RegEx
		}
	}
	
	;---------
	; DESCRIPTION:    Check whether the two strings match, taking the given titleMatchMode into account.
	; PARAMETERS:
	;  haystack  (I,REQ) - The first string, that we want to check for a match
	;  needle    (I,REQ) - The value to search for (first string should contain/start with/equal/match this regex)
	;  matchMode (I,REQ) - The match mode to use, from TitleMatchMode.*
	; RETURNS:        true/false - do the titles match?
	;---------
	matches(haystack, needle, matchMode) {
		Switch matchMode {
			Case TitleMatchMode.Start:    return haystack.startsWith(needle)
			Case TitleMatchMode.Contains: return (haystack.contains(needle) > 0)
			Case TitleMatchMode.Exact:    return (haystack = needle)
			Case TitleMatchMode.RegEx:    return (haystack.containsRegEx(needle) > 0)
		}
	}
	
	
	; #PRIVATE#
	
	; String versions of the match modes, for use in places that we can't use the constants at the top.
	static MatchModeString_Start    := "START"
	static MatchModeString_Contains := "CONTAINS"
	static MatchModeString_Exact    := "EXACT"
	static MatchModeString_RegEx    := "REGEX"
	
	; #END#
}