; Wrapper functions for a variety of commands to add a cleaner return value, or in some cases, to add a return value
; Based on https://github.com/Paris/AutoHotkey-Scripts/blob/master/Functions.ahk

{ ; Straight replacements - exact same behavior
	IfBetween(ByRef var, LowerBound, UpperBound) {
		If var between %LowerBound% and %UpperBound%
			Return, true
	}
	IfNotBetween(ByRef var, LowerBound, UpperBound) {
		If var not between %LowerBound% and %UpperBound%
			Return, true
	}
	IfIn(ByRef var, MatchList) {
		If var in %MatchList%
			Return, true
	}
	IfNotIn(ByRef var, MatchList) {
		If var not in %MatchList%
			Return, true
	}
	IfContains(ByRef var, MatchList) {
		If var contains %MatchList%
			Return, true
	}
	IfNotContains(ByRef var, MatchList) {
		If var not contains %MatchList%
			Return, true
	}
	IfIs(ByRef var, type) {
		If var is %type%
			Return, true
	}
	IfIsNot(ByRef var, type) {
		If var is not %type%
			Return, true
	}

	ControlGet(Cmd, Value = "", Control = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		ControlGet, v, %Cmd%, %Value%, %Control%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
	ControlGetFocus(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		ControlGetFocus, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
	ControlGetText(Control = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		ControlGetText, v, %Control%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
	DriveGet(Cmd, Value = "") {
		DriveGet, v, %Cmd%, %Value%
		Return, v
	}
	DriveSpaceFree(Path) {
		DriveSpaceFree, v, %Path%
		Return, v
	}
	EnvGet(EnvVarName) {
		EnvGet, v, %EnvVarName%
		Return, v
	}
	EnvAdd(varName, amountToAdd, unit := "") {
		EnvAdd, varName, % amountToAdd, % unit
		return varName
	}
	FileGetShortcut(LinkFile, ByRef OutTarget = "", ByRef OutDir = "", ByRef OutArgs = "", ByRef OutDescription = "", ByRef OutIcon = "", ByRef OutIconNum = "", ByRef OutRunState = "") {
		FileGetShortcut, %LinkFile%, OutTarget, OutDir, OutArgs, OutDescription, OutIcon, OutIconNum, OutRunState
	}
	FileGetSize(Filename = "", Units = "") {
		FileGetSize, v, %Filename%, %Units%
		Return, v
	}
	FileGetTime(Filename = "", WhichTime = "") {
		FileGetTime, v, %Filename%, %WhichTime%
		Return, v
	}
	FileGetVersion(Filename = "") {
		FileGetVersion, v, %Filename%
		Return, v
	}
	FileRead(Filename) {
		FileRead, v, %Filename%
		Return, v
	}
	FileReadLine(Filename, LineNum) {
		FileReadLine, v, %Filename%, %LineNum%
		Return, v
	}
	FileSelectFile(Options = "", RootDir = "", Prompt = "", Filter = "") {
		FileSelectFile, v, %Options%, %RootDir%, %Prompt%, %Filter%
		Return, v
	}
	FileSelectFolder(StartingFolder = "", Options = "", Prompt = "") {
		FileSelectFolder, v, %StartingFolder%, %Options%, %Prompt%
		Return, v
	}
	FormatTime(YYYYMMDDHH24MISS = "", Format = "") {
		FormatTime, v, %YYYYMMDDHH24MISS%, %Format%
		Return, v
	}
	ImageSearch(ByRef OutputVarX, ByRef OutputVarY, X1, Y1, X2, Y2, ImageFile) {
		ImageSearch, OutputVarX, OutputVarY, %X1%, %Y1%, %X2%, %Y2%, %ImageFile%
	}
	IniRead(filePath, section, key) { ; *gdb - added, but doesn't support everything, only my use cases for now.
		IniRead, v, % filePath, % section, % key
		return v
	}
	IniWrite(filePath, section, key, value) { ; *gdb - Added
		IniWrite, % value, % filePath, % section, % key
	}
	Input(Options = "", EndKeys = "", MatchList = "") {
		Input, v, %Options%, %EndKeys%, %MatchList%
		Return, v
	}
	InputBox(Title = "", Prompt = "", HIDE = "", Width = "", Height = "", X = "", Y = "", Font = "", Timeout = "", Default = "") {
		InputBox, v, %Title%, %Prompt%, %HIDE%, %Width%, %Height%, %X%, %Y%, , %Timeout%, %Default%
		Return, v
	}
	MouseGetPos(ByRef OutputVarX = "", ByRef OutputVarY = "", ByRef OutputVarWin = "", ByRef OutputVarControl = "", Mode = "") {
		MouseGetPos, OutputVarX, OutputVarY, OutputVarWin, OutputVarControl, %Mode%
	}
	PixelGetColor(X, Y, Mode = "") {
		PixelGetColor, v, %X%, %Y%, %Mode%
		Return, v
	}
	PixelSearch(ByRef OutputVarX, ByRef OutputVarY, X1, Y1, X2, Y2, ColorID, Variation = "", Mode = "") {
		PixelSearch, OutputVarX, OutputVarY, %X1%, %Y1%, %X2%, %Y2%, %ColorID%, %Variation%, %Mode%
	}
	Random(Min = "", Max = "") {
		Random, v, %Min%, %Max%
		Return, v
	}
	RegRead(KeyName, ValueName = "") {
		RegRead, v, %KeyName%, %ValueName%
		Return, v
	}
	Run(Target, WorkingDir = "", Mode = "") {
		Run, %Target%, %WorkingDir%, %Mode%, v
		Return, v	
	}
	SoundGet(ComponentType = "", ControlType = "", DeviceNumber = "") {
		SoundGet, v, %ComponentType%, %ControlType%, %DeviceNumber%
		Return, v
	}
	SoundGetWaveVolume(DeviceNumber = "") {
		SoundGetWaveVolume, v, %DeviceNumber%
		Return, v
	}
	StatusBarGetText(Part = "", WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		StatusBarGetText, v, %Part%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
	SplitPath(ByRef InputVar, ByRef OutFileName = "", ByRef OutDir = "", ByRef OutExtension = "", ByRef OutNameNoExt = "", ByRef OutDrive = "") {
		SplitPath, InputVar, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	}
	StringLower(ByRef InputVar, T = "") {
		StringLower, v, InputVar, %T%
		Return, v
	}
	StringUpper(ByRef InputVar, T = "") {
		StringUpper, v, InputVar, %T%
		Return, v
	}
	Transform(Cmd, Value1, Value2 = "") {
		Transform, v, %Cmd%, %Value1%, %Value2%
		Return, v
	}
	WinGetActiveTitle() {
		WinGetActiveTitle, v
		Return, v
	}
	WinGetClass(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		WinGetClass, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
	WinGetText(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		WinGetText, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
	WinGetTitle(WinTitle = "", WinText = "", ExcludeTitle = "", ExcludeText = "") {
		WinGetTitle, v, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
}

{ ; Commands that can return pseudo-arrays - return proper arrays or objects in those cases instead.
	GuiControlGet(Subcommand := "", ControlID := "", Param4 := "") {
		if(Subcommand = "Pos") {
			GuiControlGet, Position, %Subcommand%, %ControlID%, %Param4%
			return {"X":PositionX, "Y":PositionY, "W":PositionW, "H":PositionH}
		}
		
		GuiControlGet, v, %Subcommand%, %ControlID%, %Param4%
		Return, v
	}
	SysGet(Subcommand, Param3 := "") {
		if(Subcommand = "Monitor" || Subcommand = "MonitorWorkArea") {
			SysGet, bounds, % Subcommand, % Param3
			return {"LEFT":boundsLeft, "RIGHT":boundsRight, "TOP":boundsTop, "BOTTOM":boundsBottom}
		}
		
		SysGet, v, %Subcommand%, %Param3%
		Return, v
	}
	WinGet(Cmd := "", WinTitle := "", WinText := "", ExcludeTitle := "", ExcludeText := "") {
		if(Cmd = "List" || Cmd = "ControlList") {
			global winGetValue
			WinGet, winGetValue, % Cmd, % WinTitle, % WinText, % ExcludeTitle, % ExcludeText
			return DataLib.convertPseudoArrayToArray("winGetValue")
		}
		
		WinGet, v, %Cmd%, %WinTitle%, %WinText%, %ExcludeTitle%, %ExcludeText%
		Return, v
	}
}
