/* Move and resize windows to match presets of different positions specified in a TL tile.
		Presets come from PRESET column in config file, default is the NORMAL preset.
*/

class WindowPositions {
	; #PUBLIC#
	
	static Preset_Default := "NORMAL" ; Default preset
	static Filename_Config := "windowPositions.tl"
	static Filename_PresetList := "windowPositionPresets.tls"
	
	;---------
	; DESCRIPTION:    "Fix" the position of the given window to match what's specified in our config file.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string identifying the window to fix, defaults to active window ("A").
	;  preset      (I,OPT) - The preset to "fix" the window with regards to - a given window could have a different position per preset.
	;---------
	fixWindow(titleString := "A", preset := "NORMAL") { ; preset := Preset_Default
		if(!this.validatePreset(preset))
			return
		
		position := this.findBestPositionMatch(titleString, preset)
		if(!position)
			return
		
		this.fixWindowPosition(titleString, position)
	}
	
	;---------
	; DESCRIPTION:    "Fix" all windows listed in the config file to match the positions specified there.
	; PARAMETERS:
	;  preset (I,OPT) - Name of the preset to apply. If not passed, user will get a Selector popup prompting them for one.
	;---------
	fixAllWindows(preset := "") {
		if(!this.validatePreset(preset))
			return
		
		pt := new ProgressToast("Fixing window positions")
		For name,position in this.positions[preset] {
			pt.nextStep(name, "fixed")
			winInfo := Config.windowInfo[name]
			
			; Ensure that the window we identified doesn't better match another, more specific position entry
			if(name != Config.findWindowName(winInfo.idString)) {
				pt.endStep("not found")
				Continue
			}
			
			if(!winInfo.exists()) {
				pt.endStep("not found")
				Continue
			}
			
			this.fixWindowPosition(winInfo.idString, position)
		}
		pt.finish()
	}
	
	
	; #PRIVATE#
	
	static _positions := "" ; Cache of window positions, {presetName: {windowName: WindowPosition}}
	
	
	;---------
	; DESCRIPTION:    Get the associative array of window positions for a particular preset.
	; PARAMETERS:
	;  preset (I,REQ) - Preset name
	; RETURNS:        Associative array of WindowPosition objects by window name.
	; SIDE EFFECTS:   Populates relevant subscript of this._positions cache if it's not already.
	;---------
	positions[preset] {
		get {
			if(!this._positions)
				this._positions := {}
			if(!this._positions[preset]) {
				presetPositions := new TableList(this.Filename_Config).filterByColumn("PRESET", preset).getRowsByColumn("NAME")
				
				this._positions[preset] := {}
				For name,positionAry in presetPositions
					this._positions[preset, name] := new this.WindowPosition(positionAry)
			}
			
			return this._positions[preset]
		}
	}
		
	
	;---------
	; DESCRIPTION:    Get the window position in the given preset for the named window.
	; PARAMETERS:
	;  preset (I,REQ) - Preset name
	;  name   (I,REQ) - Window name
	; RETURNS:        WindowPosition object matching the preset and window name.
	;---------
	getPosition(preset, name) {
		return this.positions[preset][name] ; Double brackets so we don't try to pass name as a second parameter to positions property.
	}
	
	;---------
	; DESCRIPTION:    Make sure a preset is specified, and prompt the user if it's not.
	; PARAMETERS:
	;  preset (IO,REQ) - The preset name. If blank, user will be prompted and the new value set here.
	; RETURNS:        true/false - did we end up with a preset?
	;---------
	validatePreset(ByRef preset) {
		; Have a preset
		if(preset)
			return true
		
		; Prompt for preset
		preset := new Selector(this.Filename_PresetList).selectGui("PRESET")
		if(preset)
			return true
		
		; No preset given by caller or user.
		return false
	}
	
	;---------
	; DESCRIPTION:    Find the position that best matches the specified window.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string identifying the window.
	;  preset      (I,REQ) - Name of the preset to look within.
	; RETURNS:        Matching WindowPosition object, or nothing if none found.
	;---------
	findBestPositionMatch(titleString, preset) {
		For _,names in Config.findAllMatchingWindowNames(titleString) { ; Looping by priority
			For _,name in names {
				position := this.getPosition(preset, name)
				if(position)
					return position
			}
		}
	}
	
	;---------
	; DESCRIPTION:    "Fix" the position for a single window, to match the provided position.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string identifying the window.
	;  position    (I,REQ) - WindowPosition object to adjust the window to match.
	;---------
	fixWindowPosition(titleString, position) {
		if(!position)
			return
		
		if(position.shouldActivate) ; If the flag says to activate it, always do so.
			Config.activateProgram(position.name)
		
		; Track initially-minimized windows so we can re-minimize them when we're done (VisualWindow.resizeMove will restore them).
		startedMinimized := WindowLib.isMinimized(titleString)
		
		workArea := MonitorLib.workAreaForLocation[position.monitor]
		new VisualWindow(titleString).resizeMove(position.width, position.height, position.x, position.y, workArea)
		
		; Put window into final state
		if(startedMinimized) ; Otherwise, re-minimize the window if it started out that way.
			WinMinimize, % titleString
	}
	
	
	; Data class that holds the bits that make up a window's position and how to make that happen.
	class WindowPosition {
		name    := "" ; Window name
		monitor := "" ; Name of the monitor (from MonitorLib) the window should be on
		width   := "" ; Window width
		height  := "" ; Window height
		x       := "" ; Top-left corner's x coordinate
		y       := "" ; Top-left corner's y coordinate
		
		shouldActivate := "" ; Whether the window needs to be activated as part of "fixing" it
		
		__New(positionAry) {
			if(!positionAry)
				return ""
			
			this.name    := positionAry["NAME"]
			this.monitor := positionAry["MONITOR"]
			this.width   := positionAry["WIDTH"]
			this.height  := positionAry["HEIGHT"]
			this.x       := positionAry["X"]
			this.y       := positionAry["Y"]
			
			this.shouldActivate := positionAry["ACTIVATE"]
		}
	}
	
	; #END#
}
