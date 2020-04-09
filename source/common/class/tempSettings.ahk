; A wrapper for temporarily changing different script-level settings, then restoring everything when you're finished.

class TempSettings {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Restore all settings that were changed here, to their value just before the
	;                 first time they were changed.
	; NOTES:          This can only restore settings that were set using this class.
	;                 This function should only be called once - make a new instance of this class
	;                 if you need to set/restore settings multiple times.
	;---------
	restore() {
		For targetType,mode in this._coordMode {
			CoordMode, % targetType, % mode
		}
		
		if(this._detectHiddenWindows != "")
			DetectHiddenWindows, % this._detectHiddenWindows
		if(this._sendLevel           != "")
			SendLevel,           % this._sendLevel
		if(this._titleMatchMode      != "")
			SetTitleMatchMode,   % this._titleMatchMode
		if(this._titleMatchSpeed     != "")
			SetTitleMatchMode,   % this._titleMatchSpeed
		if(this._workingDirectory    != "")
			SetWorkingDir,       % this._workingDirectory
	}
	
	;---------
	; DESCRIPTION:    Set the CoordMode for a particular target type.
	; PARAMETERS:
	;  targetType (I,REQ) - The target type (ToolTip/Pixel/Mouse/Caret/Menu)
	;  new        (I,REQ) - The new CoordMode (Screen/Relative/Window/Client)
	; RETURNS:        this
	;---------
	coordMode(targetType, new) {
		if(this._coordMode[targetType] != "")
			this._coordMode[targetType] := this.getCoordMode(targetType)
		
		CoordMode, % targetType, % new
		return this
	}
	
	;---------
	; DESCRIPTION:    Set whether we should detect hidden windows.
	; PARAMETERS:
	;  new (I,REQ) - The new setting (On/Off).
	; RETURNS:        this
	;---------
	detectHiddenWindows(new) {
		if(this._detectHiddenWindows != "")
			this._detectHiddenWindows := A_DetectHiddenWindows
		
		DetectHiddenWindows, % new
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the SendLevel for the script.
	; PARAMETERS:
	;  new (I,REQ) - The new SendLevel (0-100).
	; RETURNS:        this
	;---------
	sendLevel(new) {
		if(this._sendLevel != "")
			this._sendLevel := A_SendLevel
		
		SendLevel, % new
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the title match mode.
	; PARAMETERS:
	;  new (I,REQ) - The new title match mode (use TitleMatchMode "enum" for named values).
	; RETURNS:        this
	; NOTES:          If you want to set the title match speed, use .titleMatchSpeed() instead.
	;---------
	titleMatchMode(new) {
		if(this._titleMatchMode != "")
			this._titleMatchMode := A_TitleMatchMode
		
		SetTitleMatchMode, % new
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the title match speed.
	; PARAMETERS:
	;  new (I,REQ) - The new title match speed (Slow/Fast).
	; RETURNS:        this
	;---------
	titleMatchSpeed(new) {
		if(this._titleMatchSpeed != "")
			this._titleMatchSpeed := A_TitleMatchModeSpeed
		
		SetTitleMatchMode, % new
		return this
	}
	
	;---------
	; DESCRIPTION:    Set the current working directory.
	; PARAMETERS:
	;  new (I,REQ) - The new working directory.
	; RETURNS:        this
	;---------
	workingDirectory(new) {
		if(this._workingDirectory != "")
			this._workingDirectory := A_WorkingDir
		
		SetWorkingDir, % new
		return this
	}
	
	
	; #PRIVATE#
	
	_coordMode           := {} ; {targetType: value}
	_detectHiddenWindows := ""
	_sendLevel           := ""
	_titleMatchMode      := ""
	_titleMatchSpeed     := ""
	_workingDirectory    := ""
	
	;---------
	; DESCRIPTION:    Get the current coordinate mode for the given target type.
	; PARAMETERS:
	;  targetType (I,REQ) - The target type (ToolTip/Pixel/Mouse/Caret/Menu)
	; RETURNS:        The current coordinate mode for the given type
	;---------
	getCoordMode(targetType) {
		Switch targetType {
			Case "ToolTip": return A_CoordModeToolTip
			Case "Pixel":   return A_CoordModePixel
			Case "Mouse":   return A_CoordModeMouse
			Case "Caret":   return A_CoordModeCaret
			Case "Menu":    return A_CoordModeMenu
		}
	}
	; #END#
}
