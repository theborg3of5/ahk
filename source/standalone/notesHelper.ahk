; Make the superscripting I do in my notes a little more automatic.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Notes helper", "ninja.png", "ninjaRed.png")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)
DetectHiddenWindows, On

#If Config.isWindowActive("OneNote")

; Hotstrings for various people/directions
:CB0*X?:mL::superscriptSides()
:CB0*X?:mR::superscriptSides()
:CB0*X?:mBL::superscriptSides()
:CB0*X?:mBR::superscriptSides()
:CB0*X?:mFL::superscriptSides()
:CB0*X?:mFR::superscriptSides()
:CB0*X?:mI::superscriptSides()
:CB0*X?:mO::superscriptSides()
:CB0*X?:mBI::superscriptSides()
:CB0*X?:mBO::superscriptSides()
:CB0*X?:mFI::superscriptSides()
:CB0*X?:mFO::superscriptSides()
:CB0*X?:mDL::superscriptSides()
:CB0*X?:mDR::superscriptSides()
:CB0*X?:mDB::superscriptSides()
:CB0*X?:mDF::superscriptSides()
:CB0*X?:mDI::superscriptSides()
:CB0*X?:mDO::superscriptSides()

:CB0*X?:uL::superscriptSides()
:CB0*X?:uR::superscriptSides()
:CB0*X?:uBL::superscriptSides()
:CB0*X?:uBR::superscriptSides()
:CB0*X?:uFL::superscriptSides()
:CB0*X?:uFR::superscriptSides()
:CB0*X?:uI::superscriptSides()
:CB0*X?:uO::superscriptSides()
:CB0*X?:uBI::superscriptSides()
:CB0*X?:uBO::superscriptSides()
:CB0*X?:uFI::superscriptSides()
:CB0*X?:uFO::superscriptSides()
:CB0*X?:uDL::superscriptSides()
:CB0*X?:uDR::superscriptSides()
:CB0*X?:uDB::superscriptSides()
:CB0*X?:uDF::superscriptSides()
:CB0*X?:uDI::superscriptSides()
:CB0*X?:uDO::superscriptSides()

:CB0*X?:bL::superscriptSides()
:CB0*X?:bR::superscriptSides()
:CB0*X?:bFL::superscriptSides()
:CB0*X?:bFR::superscriptSides()
:CB0*X?:bBL::superscriptSides()
:CB0*X?:bBR::superscriptSides()
:CB0*X?:bO::superscriptSides()
:CB0*X?:bO::superscriptSides()
:CB0*X?:bFO::superscriptSides()
:CB0*X?:bFO::superscriptSides()
:CB0*X?:bBO::superscriptSides()
:CB0*X?:bBO::superscriptSides()
:CB0*X?:bDL::superscriptSides()
:CB0*X?:bDR::superscriptSides()
:CB0*X?:bDB::superscriptSides()
:CB0*X?:bDF::superscriptSides()
:CB0*X?:bDI::superscriptSides()
:CB0*X?:bDO::superscriptSides()

; Degree hotstrings
:B0*?X:45d::dToDegree()
:B0*?X:90d::dToDegree()
:B0*?X:135d::dToDegree()
:B0*?X:180d::dToDegree()
:B0*?X:225d::dToDegree()
:B0*?X:270d::dToDegree()
:B0*?X:315d::dToDegree()
:B0*?X:360d::dToDegree()

#If


superscriptSides() {
	hotstring := A_ThisHotkey.afterString(":", true)
	length := hotstring.length()

	Send, {Shift Down}{Left %length%}{Shift Up} ; Select text
	Send, ^+= ; Superscript
	Send, {Right} ; Deselect, cursor back where it started
	Send, ^+= ; Remove superscript
}

dToDegree() {
	Send, {Backspace} ; Delete "d"
	Send, °
}
