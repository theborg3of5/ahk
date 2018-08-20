
class WindowInfo {
	
	; ==============================
	; == Public ====================
	; ==============================
	__New(windowAry) {
		this.windowName  := windowAry["NAME"]
		this.windowExe   := windowAry["EXE"]
		this.windowClass := windowAry["CLASS"]
		this.windowTitle := windowAry["TITLE"]
		
		titleStringMatchModeOverride  := windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"]
		this.windowEdgeOffsetOverride := windowAry["WINDOW_EDGE_OFFSET_OVERRIDE"]
		
		if(titleStringMatchModeOverride != "")
			this.windowTitleStringMatchModeOverride := %titleStringMatchModeOverride%
		if(!this.windowTitleStringMatchModeOverride)
			this.windowTitleStringMatchModeOverride := CONTAINS_ANY ; Default value
	}
	
	name[] {
		get {
			return this.windowName
		}
	}
	exe[] {
		get {
			return this.windowExe
		}
	}
	class[] {
		get {
			return this.windowClass
		}
	}
	title[] {
		get {
			return this.windowTitle
		}
	}
	
	edgeOffsetOverride[] {
		get {
			return this.windowEdgeOffsetOverride
		}
	}
	titleStringMatchModeOverride[] {
		get {
			return this.windowTitleStringMatchModeOverride
		}
	}
	
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