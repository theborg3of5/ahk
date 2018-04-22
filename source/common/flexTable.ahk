
class FlexTable {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	__New(guiId, x = 0, y = 0, rowHeight = 25, columnPadding = 30) {
		this.guiId := guiId
		
		this.xMin := x
		this.yMin := y
		this.setX(x)
		this.setY(y)
		this.xCurrColumn := x
		
		this.rowHeight := rowHeight
		this.columnPadding := columnPadding
	}
	
	addCell(cellText = "", leftPadding = "", width = "", extraProperties = "") {
		this.makeGuiTheDefault()
		
		if(leftPadding)
			this.addToX(leftPadding)
		
		propString := "x" this.xCurr " y" this.yCurr
		if(width != "")
			propString .= " w" width
		if(extraProperties != "")
			propString .= " " extraProperties
		; DEBUG.popup("FlexTable.addCell","Before add text", "cellText",cellText, "width",width, "extraProperties",extraProperties, "propString",propString)
		
		Gui, Add, Text, % propString, % cellText
		
		if(width = "")
			width := getLabelWidthForText(cellText, this.getNextUniqueControlId())
		this.addToX(width)
	}
	
	addHeaderCell(titleText, leftPadding = "", width = "", extraProperties = "") {
		this.makeGuiTheDefault()
		
		applyTitleFormat()
		this.addCell(titleText, leftPadding, width, extraProperties)
		clearTitleFormat()
	}
	
	addRow() {
		; DEBUG.popup("Before add row","", "xCurr",this.xCurr, "yCurr",this.yCurr, "rowHeight",this.rowHeight,"xCurrColumn",this.xCurrColumn)
		this.addToY(this.rowHeight)
		this.setX(this.xCurrColumn)
		; DEBUG.popup("Added row","", "xCurr",this.xCurr, "yCurr",this.yCurr)
	}
	
	addColumn() {
		this.xCurrColumn := this.xMax + this.columnPadding
		this.setX(this.xCurrColumn)
		this.setY(this.yMin)
	}
	
	getTotalHeight() {
		return this.yMax - this.yMin + this.rowHeight
	}
	
	getTotalWidth() {
		return this.xMax - this.xMin
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	guiId := ""
	static uniqueControlNum := 0 ; Used to get a unique name for each control we have to figure out the width of.
	
	; Top-left corner of table
	xMin := ""
	yMin := ""
	
	; Bottom-right corner of table
	xMax := ""
	yMax := ""
	
	; Current position within gui
	xCurr := ""
	yCurr := ""
	
	; Starting X for current column
	xCurrColumn := ""
	
	
	addToX(value) {
		this.setX(this.xCurr + value)
	}
	addToY(value) {
		this.setY(this.yCurr + value)
	}
	
	setX(value) {
		this.xCurr := value
		this.xMax := max(this.xMax, value)
		; DEBUG.popup("flexTable.setX","Finish", "Current",this.xCurr, "Min",this.xMin, "Max",this.xMax)
	}
	setY(value) {
		this.yCurr := value
		this.yMax := max(this.yMax, value)
		; DEBUG.popup("flexTable.setY","Finish", "Current",this.yCurr, "Min",this.yMin, "Max",this.yMax)
	}
	
	getNextUniqueControlId() {
		FlexTable.uniqueControlNum++
		return "FlexTableControl" FlexTable.uniqueControlNum
	}
	
	; Make sure all of the Gui* commands refer to the right one.
	makeGuiTheDefault() {
		Gui, % this.guiId ":Default" ; GDB TODO test to make sure this works (vs: Gui, %guiId%:Default).
	}
	
}