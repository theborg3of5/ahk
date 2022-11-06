#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Icon Tester", "pictureWhite.ico", "pictureRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

global currentNum ; Number of the current icon in iconsAry
global iconsAry   ; Array of icon file names
global t          ; Toast object for showing the current icon


; Find all icons in sub-folder, track their paths in an array by number
SetWorkingDir, %A_ScriptDir%\icons
iconsAry := []
iconsAry[0] := A_IconFile ; Entry 0 is the original icon for the script
Loop, Files, *.ico
{
	iconsAry.push(A_LoopFileName)
}

; Let the user know how many we found.
if(!iconsAry.maxIndex()) {
	Toast.BlockAndShowMedium("No icons found in folder, exiting...")
	ExitApp
}
if(iconsAry.maxIndex() = 1)
	Toast.ShowMedium("Loaded 1 icon")
else
	Toast.ShowMedium("Loaded " iconsAry.maxIndex() " icons")

; Set current icon number and show the persistent Toast for the icons
currentNum := 0
t := new Toast().show(VisualWindow.X_RightEdge, VisualWindow.Y_TopEdge)
switchToIconWithNum(0)

return


; Hotkeys to cycle back/forward through all icons in folder
Left:: switchToIconWithNum(currentNum - 1)
Right::switchToIconWithNum(currentNum + 1)

; Hotkeys for specific icons
NumPad0::switchToIconWithNum(0) ; Default icon for script
NumPad1::switchToIconWithNum(1)
NumPad2::switchToIconWithNum(2)
NumPad3::switchToIconWithNum(3)
NumPad4::switchToIconWithNum(4)
NumPad5::switchToIconWithNum(5)
NumPad6::switchToIconWithNum(6)
NumPad7::switchToIconWithNum(7)
NumPad8::switchToIconWithNum(8)
NumPad9::switchToIconWithNum(9)


switchToIconWithNum(num) {
	num := getFixedIconNum(num)
	
	; Find the right icon and use it
	iconPath := iconsAry[num]
	if(iconPath = "" || !FileExist(iconPath)) {
		Toast.ShowError("No icon found", "Icon " num " does not exist")
		return
	}
	Menu, Tray, Icon, % iconPath
	
	; Update the current number, and the toast to match
	currentNum := num
	t.setText(getUpdatedToastMessage())
}

getFixedIconNum(num) {
	min := iconsAry.minIndex()
	max := iconsAry.maxIndex()
	
	if(num > max)
		return min
	if(num < min)
		return max
	
	return num
}

getUpdatedToastMessage() {
	if(currentNum = 0)
		return "Using icon " currentNum " (original)"
	else
		return "Using icon " currentNum
}
