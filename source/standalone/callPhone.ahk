; Tries to call a specific number via my work phone.

#Include <includeCommon>

; Start with any command line arguments.
Loop, % A_Args.Length() { ; Loop like this in case there are spaces (which split up into multiple parameters)
	numToCall := numToCall.appendPiece(" ", A_Args[A_Index])
}

; Next try selected text
if (!PhoneLib.isValidNumber(numToCall))
	numToCall := SelectLib.getCleanFirstLine()

; Finally, prompt for it
if (!PhoneLib.isValidNumber(numToCall)) {
	numToCall := InputBox("Call from work phone", "Enter phone number:")
	if (ErrorLevel)
		numToCall := ""
}

; If we still didn't get something, give up.
if(!PhoneLib.isValidNumber(numToCall))
	ExitApp

; Otherwise make it so!
PhoneLib.call(numToCall)
