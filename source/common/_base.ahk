
; Non-objects (all use the same base class)
baseObj := "".base
; String functions
baseObj.length := Func("StrLen") ; <string>.length()

; Arrays (based on https://autohotkey.com/board/topic/83081-ahk-l-customizing-object-and-array/ )
; Define the base class.
#Include %A_LineFile%\..\class\base\arrayBase.ahk

; Redefine Array() to use our new ArrayBase base class
Array(params*) {
    ; Since params is already an array of the parameters, just give it a
    ; new base object and return it. Using this method, ArrayBase.__New()
    ; is not called and any instance variables are not initialized.
    params.base := ArrayBase
    return params
}
