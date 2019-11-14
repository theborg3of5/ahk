; This script holds classes representing enumerations of constants.

; The title match mode
class TitleMatchMode {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    The title must start with the string.
	;---------
	static Start := 1
	;---------
	; DESCRIPTION:    The title may contain the string anywhere inside.
	;---------
	static Contains := 2
	;---------
	; DESCRIPTION:    The title must exactly equal the string.
	;---------
	static Exact := 3
	;---------
	; DESCRIPTION:    The title must match the regex string.
	;---------
	static RegEx := "RegEx"
	; #END#
}
