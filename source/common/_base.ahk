; Base classes with various additional functionality
#Include %A_LineFile%\..\class\base\stringBase.ahk
#Include %A_LineFile%\..\class\base\arrayBase.ahk

; Strings (technically all non-objects, since they all share a base class - see https://www.autohotkey.com/docs/Objects.htm#Pseudo_Properties )
"".base.base := StringBase ; Can't replace the base itself, but can give it a base instead.

; Arrays (based on https://autohotkey.com/board/topic/83081-ahk-l-customizing-object-and-array/ )
; Redefine Array() to use our new ArrayBase base class
Array(params*) {
    ; Since params is already an array of the parameters, just give it a
    ; new base object and return it. Using this method, ArrayBase.__New()
    ; is not called and any instance variables are not initialized.
    params.base := ArrayBase
    return params
}
