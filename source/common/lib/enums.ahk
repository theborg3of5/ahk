; This script holds classes representing enumerations of constants.

; The title match mode
class TitleMatchMode {
	; #PUBLIC#
	
	; @GROUP@ Title match mode options
	static Start    := 1       ; The title must start with the string.
	static Contains := 2       ; The title may contain the string anywhere inside.
	static Exact    := 3       ; The title must exactly equal the string.
	static RegEx    := "RegEx" ; The title must match the provided regex.
	; @GROUP-END@
	; #END#
}

; Text alignment
class TextAlignment {
	; #PUBLIC#
	
	; @GROUP@ Text alignment options
	static Left   := "LEFT"   ; The title must start with the string.
	static Right  := "RIGHT"  ; The title may contain the string anywhere inside.
	static Center := "CENTER" ; The title must exactly equal the string.
	; @GROUP-END@
	; #END#
}
