; Optional file of private variables.
#Include *i %A_LineFile%/../../../config/local/privateVariables.ahk

; Constants for machines.
global MACHINE_EpicLaptop  := "EPIC_LAPTOP"
global MACHINE_HomeAsus    := "HOME_ASUS"
global MACHINE_HomeDesktop := "HOME_DESKTOP"

; Constants for what the menu key should do.
global MENUKEYACTION_MiddleClick := "MIDDLE_CLICK"
global MENUKEYACTION_WindowsKey  := "WINDOWS_KEY"

global MAIN_CENTRAL_SCRIPT := "MAIN_CENTRAL_SCRIPT"

; Calculate some useful paths and put them in globals.
global ahkRootPath       := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
global userPath          := reduceFilepath(A_Desktop,  1)
global configFolder      := ahkRootPath "\config"
global localConfigFolder := configFolder "\local"
; DEBUG.popup("Script", A_ScriptFullPath, "AHK Root", ahkRootPath, "User path", userPath, "Config folder", configFolder, "Local config folder", localConfigFolder)

; Config class which holds the various options and settings that go into this set of scripts' slightly different behavior in different situations.
class MainConfig {
	static multiDelim := "|"
	static defaultSettings := {"VIM_CLOSE_KEY":"F9"}
	static settings := []
	static windows  := []
	static folders  := [] ; abbrev => path
	static programs := []
	static games    := []
	
	init(settingsFile, windowsFile, foldersFile, programsFile, gamesFile) {
		this.loadSettings(settingsFile)
		this.loadWindows(windowsFile)
		this.folders  := this.loadFolders(foldersFile)
		this.loadPrograms(programsFile)
		this.loadGames(gamesFile)
		; this.settings := this.loadSettings(settingsFile) ; GDB TODO - switch to this style to reduce this.* references in load* functions
		; this.windows  := this.loadWindows(windowsFile)
		; this.programs := this.loadPrograms(programsFile)
		; this.games    := this.loadGames(gamesFile)
		
		; DEBUG.popup("MainConfig", "End of init", "Settings", this.settings, "Window settings", this.windows, "Program info", this.programs)
	}
	
	loadSettings(filePath) {
		this.loadSetting(filePath, "MACHINE")            ; Which machine this is, from MACHINE_* constants
		this.loadSetting(filePath, "MENU_KEY_ACTION")    ; What to do with the menu key, from MENU_KEY_ACTION_* constants
		this.loadSetting(filePath, "VIM_CLOSE_KEY")      ; Which keys should close tabs via vimBindings (generally F-keys).
		
		; DEBUG.popup("Script", A_ScriptFullPath, "AHK Root", ahkRootPath, "User path", userPath, "Main file path", filePath, "Settings", this.settings)
	}
	loadSetting(filePath, configName) {
		IniRead, value, %filePath%, Main, %configName%
		; DEBUG.popup("Filepath", filePath, "Config name", configName, "Value", value)
	
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
	
	loadWindows(filePath) {
		settings := []
		settings["CHARS"] := []
		
		tl := new TableList(filePath, settings)
		this.windows := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
	}
	
	loadFolders(filePath) {
		global ahkRootPath,userPath
		
		; Tags that can be used in folders.tl
		systemTags := []
		systemTags["AHK_ROOT"]  := ahkRootPath
		systemTags["USER_ROOT"] := userPath
		
		tl := new TableList(filePath)
		folderTable := tl.getFilteredTableUnique("NAME", "MACHINE", MainConfig.getMachine())
		
		; Build abbrev-indexed array of entries.
		folderPaths := []
		For i,folder in folderTable {
			abbrevAry := forceArray(folder["ABBREV"])
			For j,abbrev in abbrevAry { ; Handle having multiple abbrevs defined (with | syntax)
				if(!abbrev) ; Ignore folders with no shortcuts, mostly headers and Selector settings.
					Continue
				
				folderPaths[abbrev] := replaceTags(folder["PATH"], systemTags)
			}
		}
		
		return folderPaths
	}
	
	loadPrograms(filePath) {
		settings := []
		settings["CHARS"] := []
		settings["CHARS", "ESCAPE"] := "" ; No escape char, to let single backslashes through.
		tl := new TableList(filePath, settings)
		uniquePrograms := tl.getFilteredTableUnique("NAME", "MACHINE", this.getMachine())
		; DEBUG.popup("MainConfig", "loadPrograms", "Unique table", uniquePrograms)
		
		; Index it by name and machine.
		For i,pAry in uniquePrograms {
			name    := pAry["NAME"]    ; Identifying name of this entry (which this.programs will be indexed by)
			
			if(!IsObject(this.programs[name])) ; Initialize the array.
				this.programs[name] := []
			
			this.programs[name] := pAry
		}
		; DEBUG.popup("MainConfig", "loadPrograms", "Finished programs", this.programs)
	}
	
	loadGames(filePath) {
		tl := new TableList(filePath)
		this.games := tl.getTable()
	}
	
	
	
	; Note that this will return an array of values if that's what's in settings.
	getSetting(settingName = "") {
		if(settingName)
			return this.settings[settingName]
		else
			return this.settings
	}
	setSetting(settingName, value, saveToFile = false) {
		this.settings[settingName] := value
		
		if(saveToFile) {
			; If it's an array, turn it into a delimited string to write it to the file.
			if(isObject(value)) {
				For i,v in value {
					if(i > 1)
						valToWrite .= this.multiDelim
					
					valToWrite .= v
				}
			} else {
				valToWrite := value
			}
			
			IniWrite, %valToWrite%, %configFolder%\settings.tl, Main, %settingName%
		}
	}
	
	getWindow(title = "", ahkClass = "", exe = "", controlClass = "") {
		retWindow := ""
		if(!title && !ahkClass && !controlClass && !exe)
			return ""
		
		For i,w in this.windows {
			; DEBUG.popup("Class", ahkClass, "Title", title, "EXE", exe, "Control", controlClass, "Against settings", w)
			if(ahkClass && w["WIN_CLASS"] && (ahkClass != w["WIN_CLASS"]) )
				Continue
			if(title && w["WIN_TITLE"] && (title != w["WIN_TITLE"]) )
				Continue
			if(controlClass && w["CONTROL_CLASS"] && (controlClass != w["CONTROL_CLASS"]) )
				Continue
			if(exe && w["EXE"] && (exe != w["EXE"]) )
				Continue
			
			retWindow := w
			Break
		}
		
		return retWindow
	}
	
	getFolder(abbrev) {
		if(!abbrev)
			return ""
		return this.folders[abbrev]
	}
	replacePathTags(inputPath) {
		return replaceTags(inputPath, this.folders)
	}
	
	; Subscripts available (only set if set in file):
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
	settingIsValue(configName, value) {
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
	
	windowIsGame(titleString := "A") {
		WinGet, ahkExe, ProcessName, %titleString%
		if(!ahkExe)
			return false
		
		For i,game in this.games {
			if(ahkExe = game["EXE"])
				return true
		}
		
		return false
	}
	
	; === Shortcut functions for oft-used settings ===
	getMachine() {
		return this.getSetting("MACHINE")
	}
	isMachine(machineName) {
		return this.settingIsValue("MACHINE", machineName)
	}
	getMachineTableListFilter() {
		filter := []
		filter["COLUMN"] := "MACHINE"
		filter["VALUE"]  := this.getMachine()
		
		return filter
	}
}
