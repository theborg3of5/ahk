; Tries to call a specific number via my work phone.

#Include <includeCommon>

; Start with any command line arguments.
Loop A_Args.Length { ; Loop like this in case there are spaces (which split up into multiple parameters)
	numToCall := numToCall.appendPiece(" ", A_Args[A_Index])
}

; Next try selected text
if (!PhoneLib.isValidNumber(numToCall))
	numToCall := SelectLib.getCleanFirstLine()

; Finally, prompt for it
if (!PhoneLib.isValidNumber(numToCall)) {
	ib := InputBox("Enter phone number:", "Call from work phone")
	if (ib.Result = "Cancel")
		numToCall := ""
	else
		numToCall := ib.Value
}

; If we still didn't get something, give up.
if(!PhoneLib.isValidNumber(numToCall))
	ExitApp

; Otherwise make it so!
PhoneLib.call(numToCall)

ExitApp
