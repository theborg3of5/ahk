
class WindowInfo {
	
	; ==============================
	; == Public ====================
	; ==============================
	__New(windowAry) {
		this.windowName               := windowAry["NAME"]
		this.windowExe                := windowAry["EXE"]
		this.windowClass              := windowAry["CLASS"]
		this.windowTitle              := windowAry["TITLE"]
		this.windowText               := windowAry["TEXT"]
		this.windowEdgeOffsetOverride := windowAry["WINDOW_EDGE_OFFSET_OVERRIDE"]
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
	text[] {
		get {
			return this.windowText
		}
	}
	edgeOffsetOverride[] {
		get {
			return this.windowEdgeOffsetOverride
		}
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	windowName               := ""
	windowExe                := ""
	windowClass              := ""
	windowTitle              := ""
	windowText               := ""
	windowEdgeOffsetOverride := ""
	
	
	; Debug info (used by the Debug class)
	debugName := "WindowInfo"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Name"           , this.windowName)
		debugBuilder.addLine("EXE"            , this.windowExe)
		debugBuilder.addLine("Class"          , this.windowClass)
		debugBuilder.addLine("Title"          , this.windowTitle)
		debugBuilder.addLine("Text"           , this.windowText)
		debugBuilder.addLine("Offset override", this.windowEdgeOffsetOverride)
	}
}