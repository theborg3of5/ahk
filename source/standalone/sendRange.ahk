; Generate a Hyperdrive environments file from the environments we have configured for Hyperspace.

#Include <includeCommon>
#LTrim, Off

; This is from DataLib.getNumericRangeBits(), keep it up to date with that
prompt := "
(
Supported formats:
  START-END
  START:[STEP:]END

  START
    Numeric start of the range.
  
  STEP
    How much to increment each time. Defaults to 1.
    Step direction is always calculated based on start/end (positive if begin is smaller than end, etc.)
  
  END (any of)
    - A normal number
    - [+/-]num: start +/- a number (+5 to specify start+5) [not supported for hyphenated ranges]
    - *num: Replace the last few digits of start with the new one (*53 will be start with its last two digits replaced with 53)
)"

rangeString := InputBox("Enter range to send", prompt, , 1100, 375)
if (rangeString = "")
	ExitApp

rangeAry := DataLib.expandList(rangeString)
if (DataLib.isNullOrEmpty(rangeAry)) {
	ClipboardLib.set(rangeString)
	Toast.BlockAndShowError("Failed to convert input", "", "Input copied to clipboard")
	ExitApp
}

ClipboardLib.send(rangeAry.join(","))

ExitApp
