/* Modification class for parsing lists.
*/
class TableListMod {
	mod       := ""
	bit       := 1
	start     := 1
	len       := 0
	text      := ""
	label     := 0
	operation := ""
	
	__New(m, s, l, t, a, o) {
		this.mod       := m
		this.start     := s
		this.len       := l
		this.text      := t
		this.label     := a
		this.operation := o
	}
	
	; Actually do what this mod describes to the given row.
	executeMod(rowBits) {
		rowBit := rowBits[this.bit]
		
		startOffset := 0
		endOffset := 0
		if(this.len > 0)
			endOffset := this.len
		else if(this.len < 0)
			startOffset := this.len
		
		rowBitLen := StrLen(rowBit)
		if(this.start > 0)
			startLen := this.start - 1
		else if(this.start < 0)
			startLen := rowBitLen + this.start + 1
		else
			startLen := rowBitLen // 2
		
		outBit := SubStr(rowBit, 1, startLen + startOffset)
		outBit .= this.text
		outBit .= SubStr(rowBit, (startLen + 1) + endOffset)
		
		; Put the bit back into the full row.
		rowBits[this.bit] := outBit
		
		return rowBits
	}
	
	; Debug info
	debugName := "TableListMod"
	debugToString(numTabs = 0) {
		outStr .= DEBUG.buildDebugString("Mod",       this.mod,       numTabs, true)
		outStr .= DEBUG.buildDebugString("Bit",       this.bit,       numTabs, true)
		outStr .= DEBUG.buildDebugString("Start",     this.start,     numTabs, true)
		outStr .= DEBUG.buildDebugString("Length",    this.len,       numTabs, true)
		outStr .= DEBUG.buildDebugString("Text",      this.text,      numTabs, true)
		outStr .= DEBUG.buildDebugString("Label",     this.label,     numTabs, true)
		outStr .= DEBUG.buildDebugString("Operation", this.operation, numTabs, true)
		return outStr
	}
}