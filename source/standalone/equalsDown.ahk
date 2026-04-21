; Send the equals key and down a specified number of times.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

; Set mouseover text for icon
A_IconTip := "
	( LTrim
		Equals+Down Sender
		Ctrl+R to prompt for how many Equals+Down keystrokes to send.

		Emergency Exit: Ctrl+Shift+Alt+Win+R
	)"

^r:: {
	ib := InputBox("Enter how many times to send Equals+Down:", "Send Equals+Down Keystrokes")
	if(ib.Result = "Cancel" || ib.Value = "")
		return
	numToSend := ib.Value

	; Sanity checks
	if(!numToSend.isNum()) {
		MsgBox("Error: given value was not a number.")
		return
	}
	if(numToSend < 1) {
		MsgBox("Error: given number is smaller than 1.")
		return
	}

	; Confirmation if it's a really big number
	if(numToSend > 100) {
		result := MsgBox("Are you sure you want to send Equals+Down " numToSend " times?", "Delete page?", "YesNo")
		if(result = "No")
			return
	}

	; Send the keystrokes
	Loop numToSend {
		Send("={Down}")
	}
}
