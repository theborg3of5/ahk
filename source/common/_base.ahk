
; Non-objects (all use the same base class)
baseObj := "".base
; String functions
baseObj.length := Func("StrLen") ; <string>.length()

; Arrays (based on https://autohotkey.com/board/topic/83081-ahk-l-customizing-object-and-array/ )
; Define the base class.
class _Array { ; new base class for Array
	join(delim := ",") {
		outString := ""
		
		For _,value in this
			outString := appendPieceToString(outString, delim, value)
		
		return outString
	}
}
; Redefine Array().
Array(prm*) {
    ; Since prm is already an array of the parameters, just give it a
    ; new base object and return it. Using this method, _Array.__New()
    ; is not called and any instance variables are not initialized.
    prm.base := _Array
    return prm
}
