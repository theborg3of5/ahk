; Data class to hold identifying information about a specific window.

class WindowInfo {
	; #PUBLIC#
	
	; @GROUP@ Window edge types (see VisualWindow class for what this means/how it's used).
	static EdgeStyle_HasPadding := "HAS_PADDING" ; The window has the standard padding around the edges.
	static EdgeStyle_NoPadding  := "NO_PADDING"  ; The window has no padding around the edges.
	; @GROUP-END@
	
	; @GROUP@
	name           := "" ; Name of the window
	exe            := "" ; EXE for the corresonding program
	class          := "" ; AHK class of the window
	title          := "" ; Title of the window
	priority       := "" ; Priority of this WindowInfo instance versus others. Can be used to break a tie if multiple instances match a given window.
	edgeType       := "" ; Edge type of the window (from WindowInfo.EdgeStyle_* constants)
	titleMatchMode := "" ; The title match mode (from TitleMatchMode.*) to use when searching for this window
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    A string that can be used with WinActive() and the like to identify this
	;                 window.
	; NOTES:          Make sure to check .titleMatchMode as well, in case the window requires a special condition there.
	;---------
	titleString {
		get {
			return WindowLib.buildTitleString(this.exe, this.class, this.title)
		}
	}
	
	;---------
	; DESCRIPTION:    Creates a new instance of WindowInfo.
	; PARAMETERS:
	;  windowAry (I,REQ) - Array of identifying information about the window. Format:
	;                         windowAry["NAME"]  - The name of the window, for identification in code.
	;                                  ["EXE"]   - The exe for the window
	;                                  ["CLASS"] - The AHK class of the window
	;                                  ["TITLE"] - The title of the window
	;                      There are also a couple of special overrides available in the array:
	;                         windowAry["PRIORITY"]
	;                                      - If more than one WindowInfo instance matches a given
	;                                        window, this can be used to break the tie.
	;                                  ["EDGE_TYPE"]
	;                                      - The type of edges the window has (from
	;                                        WindowInfo.EdgeStyle_* constants), which determines
	;                                        whether the window is the size that it appears or if it
	;                                        has invisible padding around it that needs to be taken
	;                                        into account when resizing, etc.
	;                                  ["TITLE_MATCH_MODE"]
	;                                      - If the window has a specific title match mode that
	;                                        needs to be used when locating it, this will return
	;                                        that override.
	;---------
	__New(windowAry) {
		; Replace any private tags lurking in these portions of info.
		this.name  := Config.replacePrivateTags(windowAry["NAME"])
		this.exe   := Config.replacePrivateTags(windowAry["EXE"])
		this.class := Config.replacePrivateTags(windowAry["CLASS"])
		this.title := Config.replacePrivateTags(windowAry["TITLE"])
		
		this.priority := windowAry["PRIORITY"]
		this.edgeType := windowAry["EDGE_TYPE"]
		
		this.titleMatchMode := TitleMatchMode.convertFromString(windowAry["TITLE_MATCH_MODE"])
	}
	
	;---------
	; DESCRIPTION:    Get the the first window that matches all of the critieria contained in this class.
	; RETURNS:        The matching window's ID
	;---------
	getMatchingWindowID() {
		; Spotify is a special case - we can't distill the right window down to a simple title string.
		if(this.name = "Spotify")
			return Spotify.getMainWindowId()
		
		settings := new TempSettings().titleMatchMode(this.titleMatchMode)
		winId := WinExist(this.titleString)
		settings.restore()
		
		return winId
	}
	
	;---------
	; DESCRIPTION:    Check whether the window matching the given title string matches all of our info.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string identifying the window in question.
	; RETURNS:        true/false - does it match?
	; NOTES:          Blank values for this class' pieces are effectively wildcards - they match anything.
	;---------
	windowMatches(titleString) {
		exe   := WinGet("ProcessName", titleString)
		class := WinGetClass(titleString)
		title := WinGetTitle(titleString)
		return this.windowMatchesPieces(exe, class, title)
	}
	
	;---------
	; DESCRIPTION:    Check whether the given info matches what we have here.
	; PARAMETERS:
	;  exe   (I,OPT) - Window exe
	;  class (I,OPT) - Window class
	;  title (I,OPT) - Window title
	; RETURNS:        true/false - did all of the pieces match?
	; NOTES:          Blank values for this class' pieces are effectively wildcards - they match anything.
	;---------
	windowMatchesPieces(exe := "", class := "", title := "") {
		; Check EXE, if we have it specified
		if(this.exe && (this.exe != exe))
			return false
		
		; Check class, if we have it specified
		if(this.class && (this.class != class))
			return false
		
		; Title is checked based on titleMatchMode, if we have it specified
		if(this.title && !TitleMatchMode.titleMatches(title, this.title, this.titleMatchMode))
			return false
		
		return true
	}
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "WindowInfo"
	}
	; #END#
}
