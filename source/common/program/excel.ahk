class Excel {
	; #INTERNAL#
	
	;---------
	; DESCRIPTION:    AutoFit the column widths for the entire sheet.
	;---------
	autoFixColumnWidth() {
		Send, ^a^a ; Select All (twice to get everything)
		Send, !hoi ; Home tab > Format > AutoFit Column Width
	}
	
	;---------
	; DESCRIPTION:    Bold the header row and freeze it.
	;---------
	boldFreezeHeaderRow() {
		Send, ^{Home}  ; Get back to top-left cell
		Send, +{Space} ; Select full row
		Send, ^b       ; Bold
		Send, !wfr		; View tab > Freeze Panes > Freeze Top Row
	}
	; #END#
}
