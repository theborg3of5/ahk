; Searches the GAL by mobile phone number. Command line argument is that number.

inputNumber = %1%                                ; Input from command line

if(!inputNumber)
	InputBox, inputNumber, Search GAL for Mobile Number, Enter a phone number to search in the Global Address List

if(!inputNumber)
	return

phoneNumFormatted := reformatPhone(inputNumber)  ; Put the number in the right format, because search is picky
Run, % "rundll32 dsquery.dll,OpenQueryWindow"    ; Search window
WinWaitActive, Find Users, Contacts, and Groups  ; Wait for it to appear
Sleep, 100                                       ; Little bit of buffer time
Send, ^{Tab}                                     ; Advanced tab
Send, !l                                         ; Field button
Send, {Down}{Right}M{Down 3}{Enter}              ; Mobile Number menu item
Send, !u                                         ; Value field
Send, % phoneNumFormatted                        ; User-input number
Send, !a                                         ; Add condition button
Send, !i                                         ; Find Now button

reformatPhone(input) {
	nums := RegExReplace(input, "[^0-9\+]" , "") ; Strip out spaces and other odd chars.
	trimmedNums := SubStr(nums, -9) ; Last 10 chars only.
	return "(" SubStr(trimmedNums, 1, 3) ") " SubStr(trimmedNums, 4, 3) "-" SubStr(trimmedNums, 7, 4)
}
