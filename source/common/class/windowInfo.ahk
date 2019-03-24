; Data class to hold identifying information about a specific window.

class WindowInfo {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	;---------
	; DESCRIPTION:    Creates a new instance of WindowInfo.
	; PARAMETERS:
	;  windowAry (I,REQ) - Array of identifying information about the window. Format:
	;                         windowAry["NAME"]  - The name of the window, for identification in code.
	;                                  ["EXE"]   - The exe for the window
	;                                  ["CLASS"] - The AHK class of the window
	;                                  ["TITLE"] - The title of the window
	;                      There are also a couple of special overrides available in the array:
	;                         windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"]
	;                                      - If the window is onethat handles its edges differently
	;                                        (mostly Microsoft Office and Chrome), this returns the
	;                                        edge offset that we should use for it.
	;                                  ["WINDOW_EDGE_OFFSET_OVERRIDE"]
	;                                      - If the window has a specific title match mode that
	;                                        needs to be used when locating it, this will return
	;                                        that override.
	; RETURNS:        Reference to a new WindowInfo object
	;---------
	__New(windowAry) {
		this.windowName  := windowAry["NAME"]
		this.windowExe   := windowAry["EXE"]
		this.windowClass := windowAry["CLASS"]
		this.windowTitle := windowAry["TITLE"]
		
		; Replace any private tags lurking in this info.
		this.windowName  := MainConfig.replacePrivateTags(this.windowName)
		this.windowExe   := MainConfig.replacePrivateTags(this.windowExe)
		this.windowClass := MainConfig.replacePrivateTags(this.windowClass)
		this.windowTitle := MainConfig.replacePrivateTags(this.windowTitle)
		
		if(windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"] = "")
			this.windowTitleStringMatchModeOverride := windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"]
		else
			this.windowTitleStringMatchModeOverride := CONTAINS_ANY ; Default value
		
		this.windowEdgeOffsetOverride := windowAry["WINDOW_EDGE_OFFSET_OVERRIDE"]
	}
	
	;---------
	; DESCRIPTION:    Name of the window
	;---------
	name[] {
		get {
			return this.windowName
		}
	}
	;---------
	; DESCRIPTION:    EXE for the program
	;---------
	exe[] {
		get {
			return this.windowExe
		}
	}
	;---------
	; DESCRIPTION:    AHK class of the window
	;---------
	class[] {
		get {
			return this.windowClass
		}
	}
	;---------
	; DESCRIPTION:    Title of the window
	;---------
	title[] {
		get {
			return this.windowTitle
		}
	}
	
	;---------
	; DESCRIPTION:    If the window is one that handles its edges differently (mostly Microsoft
	;                 Office and Chrome), this returns the edge offset that we should use for it.
	;---------
	edgeOffsetOverride[] {
		get {
			return this.windowEdgeOffsetOverride
		}
	}
	;---------
	; DESCRIPTION:    If the window has a specific title match mode that needs to be used when
	;                 locating it, this will return that override.
	;---------
	titleStringMatchModeOverride[] {
		get {
			return this.windowTitleStringMatchModeOverride
		}
	}
	
	;---------
	; DESCRIPTION:    A string that can be used with WinActive() and the like to identify this
	;                 window.
	;---------
	titleString[] {
		get {
			return buildWindowTitleString(this.exe, this.class, this.title)
		}
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	windowName  := ""
	windowExe   := ""
	windowClass := ""
	windowTitle := ""
	windowText  := ""
	
	windowTitleStringMatchModeOverride := ""
	windowEdgeOffsetOverride           := ""
	
	; Debug info (used by the Debug class)
	debugName := "WindowInfo"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Name"                            , this.name)
		debugBuilder.addLine("EXE"                             , this.exe)
		debugBuilder.addLine("Class"                           , this.class)
		debugBuilder.addLine("Title"                           , this.title)
		debugBuilder.addLine("Offset override"                 , this.edgeOffsetOverride)
		debugBuilder.addLine("Title string match mode override", this.titleStringMatchModeOverride)
	}
}