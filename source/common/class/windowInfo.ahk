; Data class to hold identifying information about a specific window.

class WindowInfo {

; ==============================
; == Public ====================
; ==============================
	; Constants for the type of edge a window has (see VisualWindow class for what this means/how it's used).
	static EdgeStyle_HasPadding := "HAS_PADDING" ; The window has the standard padding around the edges.
	static EdgeStyle_NoPadding  := "NO_PADDING"  ; The window has no padding around the edges.
	
	;---------
	; DESCRIPTION:    Creates a new instance of WindowInfo.
	; PARAMETERS:
	;  windowAry (I,REQ) - Array of identifying information about the window. Format:
	;                         windowAry["NAME"]  - The name of the window, for identification in code.
	;                                  ["EXE"]   - The exe for the window
	;                                  ["CLASS"] - The AHK class of the window
	;                                  ["TITLE"] - The title of the window
	;                      There are also a couple of special overrides available in the array:
	;                         windowAry["EDGE_TYPE"]
	;                                      - The type of edges the window has (from
	;                                        WindowInfo.EdgeStyle_* constants), which determines
	;                                        whether the window is the size that it appears or if it
	;                                        has invisible padding around it that needs to be taken
	;                                        into account when resizing, etc.
	;                                  ["TITLE_STRING_MATCH_MODE_OVERRIDE"]
	;                                      - If the window has a specific title match mode that
	;                                        needs to be used when locating it, this will return
	;                                        that override.
	;                                  ["PRIORITY"]
	;                                      - If more than one WindowInfo instance matches a given
	;                                        window, this can be used to break the tie.
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
		
		if(windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"] != "")
			this.windowTitleStringMatchModeOverride := windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"]
		else
			this.windowTitleStringMatchModeOverride := CONTAINS_ANY ; Default value
		
		if(windowAry["EDGE_TYPE"] != "")
			this.windowEdgeType := windowAry["EDGE_TYPE"]
		else
			this.windowEdgeType := WindowInfo.EdgeStyle_HasPadding
		
		this.windowPriority := windowAry["PRIORITY"]
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
	; DESCRIPTION:    Edge type of the window (from WindowInfo.EdgeStyle_* constants)
	;---------
	edgeType[] {
		get {
			return this.windowEdgeType
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
	
	;---------
	; DESCRIPTION:    Priority of this WindowInfo instance versus others. Can be used to break a tie
	;                 if multiple instances match a given window.
	;---------
	priority[] {
		get {
			return this.windowPriority
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
	windowEdgeType                     := ""
	windowPriority                     := ""
	
	; Debug info (used by the Debug class)
	debugName := "WindowInfo"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Name"                            , this.name)
		debugBuilder.addLine("EXE"                             , this.exe)
		debugBuilder.addLine("Class"                           , this.class)
		debugBuilder.addLine("Title"                           , this.title)
		debugBuilder.addLine("Edge type"                       , this.edgeType)
		debugBuilder.addLine("Title string match mode override", this.titleStringMatchModeOverride)
	}
}