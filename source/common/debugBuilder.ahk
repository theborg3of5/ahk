; Non-static class for use in building blocks of debug text.

class DebugBuilder {
	numTabs   := 0  ; How indented our base level of text should be.
	outString := "" ; Built-up string to eventually return.
	
	__New(numTabs = 0) {
		this.numTabs := numTabs
	}
	
	addLine(label, value) {
		newLine := DEBUG.buildDebugString(label, value, this.numTabs)
		this.outString := appendLine(this.outString, newLine)
	}
	
	toString() {
		return this.outString
	}
}
