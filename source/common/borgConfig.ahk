; Optional file of private variables.
#Include *i %A_LineFile%/../../../config/local/privateVariables.ahk

; Constants for machines.
global EPIC_DESKTOP   := "EPIC_DESKTOP"
global BORG_ASUS      := "BORG_ASUS"
global BORG_DESKTOP   := "BORG_DESKTOP"

; Constants for what the menu key should do.
global menuKeyActionMiddleClick := "MIDDLE_CLICK"
global menuKeyActionWindowsKey  := "WINDOWS_KEY"

global BORG_CENTRAL_SCRIPT := "BORG_CENTRAL_SCRIPT"

; Calculate some useful paths and put them in globals.
global ahkRootPath  := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
global userPath     := reduceFilepath(A_Desktop, 1)
global ahkLibPath   := A_MyDocuments "\AutoHotkey\Lib\" ; This built-in AHK variable doesn't return a \ on the end (before "AutoHotkey\") so add it.
global configFolder := ahkRootPath "config\"
global localConfigFolder := configFolder "local\"
; DEBUG.popup("Script", A_ScriptFullPath, "AHK Root", ahkRootPath, "User path", userPath, "AHK Lib", ahkLibPath, "Config folder", configFolder, "Local config folder", localConfigFolder)

; Config class which holds the various options and settings that go into this set of scripts' slightly different behavior in different situations.
class BorgConfig {
	static multiDelim := "|"
	static settingsIndices := ["MACHINE", "MENU_KEY_ACTION", "VIM_CLOSE_KEY", "WINDOW_EDGE_OFFSET", "MAX_EXTRA_WINDOW_EDGE_OFFSET"]
	
	static defaultSettings := {"VIM_CLOSE_KEY": "F9", "WINDOW_EDGE_OFFSET": 0, "MAX_EXTRA_WINDOW_EDGE_OFFSET": 0}
	static settings := []
	static windows  := []
	static programs := []
	
	init(settingsINI, windowsINI, programsINI) {
		this.loadSettings(settingsINI)
		this.loadWindows(windowsINI)
		this.loadPrograms(programsINI)
		
		; DEBUG.popup("BorgConfig", "End of init", "Settings", this.settings, "Window settings", this.windows, "Program info", this.programs)
	}
	
	loadSettings(iniPath) {
		For i,configName in this.settingsIndices {
			IniRead, value, %iniPath%, Main, %configName%
			; DEBUG.popup("INI", iniPath, "Config name", configName, "Value", value)
		
			; Multi-entry value, put into an array.
			if(stringContains(value, this.multiDelim)) {
				this.settings[configName] := StrSplit(value, this.multiDelim)
			
			; Single value, use it as-is.
			} else if(value) {
				this.settings[configName] := value
			
			; Empty value, use default.
			} else {
				this.settings[configName] := this.defaultSettings[configName]
			}
		}
		
		; DEBUG.popup("Script", A_ScriptFullPath, "AHK Root", ahkRootPath, "User path", userPath, "AHK Lib", ahkLibPath, "Borg ini path", iniPath, "Settings", this.settings)
	}
	
	loadWindows(iniPath) {
		settings := []
		settings["CHARS"] := []
		settings["CHARS", "PLACEHOLDER"] := "-"
		settings["FILTER", "COLUMN"] := "MACHINE"
		settings["FILTER", "INCLUDE", "VALUE"] := BorgConfig.getMachine()
		
		this.windows := TableList.parseFile(iniPath, settings)
		; DEBUG.popup("BorgConfig", "loadWindows", "Loaded windows", this.windows)
	}
	
	loadPrograms(iniPath) {
		settings := []
		settings["CHARS"] := []
		settings["CHARS", "ESCAPE"] := "" ; No escape char, to let single backslashes through.
		settings["CHARS", "PLACEHOLDER"] := "-"
		rawPrograms := TableList.parseFile(iniPath, settings) ; Format: rawPrograms[idx] := [program info array]
		; DEBUG.popup("BorgConfig", "loadPrograms", "Raw table", rawPrograms)
		
		; Index it by name and machine.
		indexedProgs := [] ; Format: indexedProgs[NAME][MACHINE] := [program info array]
		For i,pAry in rawPrograms {
			name    := pAry["NAME"]    ; Identifying name of this entry (which this.programs will be indexed by)
			machine := pAry["MACHINE"] ; Which machine this is specific to
			
			if(!IsObject(indexedProgs[name])) ; Initialize the array.
				indexedProgs[name] := []
			
			if(!machine) ; No machine means it's for all of them, or at least the default.
				machine := "ALL"
			
			indexedProgs[name][machine] := pAry
		}
		; DEBUG.popup("Programs indexed by name and machine", indexedProgs)
		
		; Condense down to our local machine, using machine = "ALL" for fallbacks where empty.
		For name,machinesAry in indexedProgs {
			this.programs[name] := []
			
			; Default values across all machines.
			allAry := machinesAry["ALL"]
			For idx,val in allAry
				this.programs[name][idx] := val
			
			; Specific overrides for this machine.
			specificAry := machinesAry[this.getMachine()]
			For idx,val in specificAry
				if(val)
					this.programs[name][idx] := val
		}
		
		; DEBUG.popup("BorgConfig", "loadPrograms", "Finished programs", this.programs)
	}
	
	
	
	; Note that this will return an array of values if that's what's in settings.
	getSetting(settingName = "") {
		if(settingName)
			return this.settings[settingName]
		else
			return this.settings
	}
	setSetting(settingName, value, saveToINI = false) {
		this.settings[settingName] := value
		
		if(saveToINI) {
			; If it's an array, turn it into a delimited string to write it to the INI.
			if(isObject(value)) {
				For i,v in value {
					if(i > 1)
						valToWrite .= this.multiDelim
					
					valToWrite .= v
				}
			} else {
				valToWrite := value
			}
			
			IniWrite, %valToWrite%, %configFolder%settings.ini, Main, %settingName%
		}
	}
	
	getWindow(title = "", ahkClass = "", controlClass = "") {
		retWindow := ""
		if(!title && !ahkClass && !controlClass)
			return ""
		
		For i,w in this.windows {
			; DEBUG.popup("Class", ahkClass, "Title", title, "Control", controlClass, "Against settings", w)
			if(ahkClass && w["WIN_CLASS"] && ahkClass != w["WIN_CLASS"])
				Continue
			if(title && w["WIN_TITLE"] && title != w["WIN_TITLE"])
				Continue
			if(controlClass && w["CONTROL_CLASS"] && controlClass != w["CONTROL_CLASS"])
				Continue
			
			retWindow := w
			Break
		}
		
		return retWindow
	}
	
	; Subscripts available (only set if set in INI):
	;	NAME    - Program name
	;	CLASS   - ahk_class (or sometimes title prefaced with "{NAME} ")
	;	PATH    - Full path to the executable, including the executable.
	;	ARGS    - Arguments to run with.
	;	EXE     - Executable name (+.exe)
	;	MACHINE - Machine this was specific to, "" if default.
	getProgram(name, subscript = "") {
		if(subscript) { ; Get the specific subscript.
			return this.programs[name][subscript]
		} else { ; Just return the whole array.
			return this.programs[name]
		}
	}
	
	
	
	; === Comparison functions for easy "check if this hotkey should trigger X" type needs ===
	
	; Checks for the given value (regardless of whether the desired setting is an array or not).
	isValue(configName, value) {
		; DEBUG.popup("Name", configName, "Check value", value, "Name value", this.settings[configName], "All settings", this.settings)
		
		; If the setting has multiple values, loop over them and return true if it's in there.
		if(IsObject(this.settings[configName])) {
			For i,s in this.settings[configName] {
				if(s = value)
					return true
			}
		} else {
			if(this.settings[configName] = value)
				return true
		}
		
		return false
	}
	
	; === Shortcut functions for oft-used settings ===
	getMachine() {
		return this.getSetting("MACHINE")
	}
	isMachine(machineName) {
		return this.isValue("MACHINE", machineName)
	}
}

BorgConfig.init(localConfigFolder "settings.ini", configFolder "windows.ini", configFolder "programs.ini")