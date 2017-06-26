global lastGuiId = 0

getNextGuiId() {
	lastGuiId++
	
	; 100 should be a reasonable limit to wrap around from if scripts run long enough to need to wrap.
	if(lastGuiId = 100)
		lastGuiId = 1
	
	return lastGuiId
}