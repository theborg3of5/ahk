; Recurring timer script to turn off UAC.

#Include <includeCommon>
ScriptTrayInfo.Init("AHK: Kill UAC", "shieldGreen.ico", "shieldRed.ico")
CommonHotkeys.Init(CommonHotkeys.ScriptType_Sub)
CommonHotkeys.setSuspendTimerLabel("DoDisable")

disableUserAccountControl() ; Do it once immediately.
SetTimer, DoDisable, 1800000 ; 30m
return

DoDisable:
	disableUserAccountControl()
return

disableUserAccountControl() {
	RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System, EnableLUA, 0x00000000
}
