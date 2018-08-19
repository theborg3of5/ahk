; Constants for machines.
global MACHINE_EpicLaptop  := "EPIC_LAPTOP"
global MACHINE_HomeAsus    := "HOME_ASUS"
global MACHINE_HomeDesktop := "HOME_DESKTOP"

; Constants for what the menu key should do.
global MENUKEYACTION_MiddleClick := "MIDDLE_CLICK"
global MENUKEYACTION_WindowsKey  := "WINDOWS_KEY"

global MAIN_CENTRAL_SCRIPT := "MAIN_CENTRAL_SCRIPT"

; Config class which holds the various options and settings that go into this set of scripts' slightly different behavior in different situations.
class MainConfig {
	
	; ==============================
	; == Public ====================
	; ==============================
	
	init(settingsFile, windowsFile, pathsFile, programsFile, gamesFile, privatesFile, windowsLegacyFile) {
		; All config files are expected to live in config/ folder under the root of this repo.
		ahkRootPath := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
		configFolder := ahkRootPath "\config"
		
		settingsPath := configFolder "\" settingsFile
		windowsPath  := configFolder "\" windowsFile
		pathsPath    := configFolder "\" pathsFile
		programsPath := configFolder "\" programsFile
		gamesPath    := configFolder "\" gamesFile
		privatesPath := configFolder "\" privatesFile
		windowsLegacyPath := configFolder "\" windowsLegacyFile
		
		this.privates := this.loadPrivates(privatesPath) ; This should be loaded before everything else, so the tags defined there can be used by other config files as needed.
		
		this.settings := this.loadSettings(settingsPath)
		this.windows  := this.loadWindows(windowsPath)
		this.paths    := this.loadPaths(pathsPath)
		this.programs := this.loadPrograms(programsPath)
		this.games    := this.loadGames(gamesPath)
		this.windowsLegacy := this.loadWindowsLegacy(windowsLegacyPath)
		; DEBUG.popupEarly("MainConfig","Loaded all", "Settings",this.settings, "Windows",this.windows, "Paths",this.paths, "Programs",this.programs, "Games",this.games)
		
		this.initDone := true
	}
	
	
	isInitialized() {
		return this.initDone
	}
	
	getSetting(settingName) {
		if(!settingName)
			return ""
		return this.settings[settingName]
	}
	getMachine() {
		return this.getSetting("MACHINE")
	}
	isMachine(machineName) {
		return (this.settings["MACHINE"] = machineName)
	}
	getMachineTableListFilter() {
		filter := []
		filter["COLUMN"] := "MACHINE"
		filter["VALUE"]  := this.getMachine()
		
		return filter
	}
	
	getPrivate(key) {
		if(!key)
			return ""
		return this.privates[key]
	}
	replacePrivateTags(inputString) {
		return replaceTags(inputString, this.privates)
	}
	
	getWindow(name := "", exe := "", ahkClass := "", title := "", text := "") {
		retWindow := ""
		if(!name && !exe && !ahkClass && !title && !text)
			return ""
		
		For i,w in this.windowsLegacy {
			; DEBUG.popupEarly("Against settings",w, "Name",name, "EXE",exe, "Class",ahkClass, "Title",title, "Text",text)
			if(name && w["NAME"] && (name != w["NAME"]))
				Continue
			if(exe && w["EXE"] && (exe != w["EXE"]))
				Continue
			if(ahkClass && w["CLASS"] && (ahkClass != w["CLASS"]))
				Continue
			if(title && w["TITLE"]) {
				if(stringStartsWith(w["TITLE"], "{REGEX}")) {
					regexNeedle := removeStringFromStart(w["TITLE"], "{REGEX}")
					if(!RegExMatch(title, regexNeedle))
						Continue
				} else {
					if(title != w["TITLE"])
						Continue
				}
			}
			if(text && w["TEXT"] && !stringContains(text, w["TEXT"]))
				Continue
			
			retWindow := w.clone()
			Break
		}
		
		; DEBUG.popupEarly("MainConfig","getWindow", "Found window",retWindow)
		return retWindow
	}
	isWindowActive(windowName) {
		return (windowName = getWindowSetting("NAME"))
	}
	isRemoteDesktopActive(titleString := "A") {
		return WinActive(getWindowTitleString("Remote Desktop"))
	}
	windowIsGame(titleString := "A") {
		ahkExe := WinGet("ProcessName", titleString)
		if(!ahkExe)
			return false
		
		For i,game in this.games {
			if(ahkExe = game["EXE"])
				return true
		}
		
		return false
	}
	
	getPath(key) {
		if(!key)
			return ""
		return this.paths[key]
	}
	replacePathTags(inputPath) {
		return replaceTags(inputPath, this.paths)
	}
	
	; Subscripts available (only set if set in file):
	;	NAME    - Program name
	;	CLASS   - ahk_class (or sometimes title prefaced with "{NAME} ")
	;	PATH    - Full path to the executable, including the executable.
	;	ARGS    - Arguments to run with.
	;	EXE     - Executable name (+.exe)
	;	MACHINE - Machine this was specific to, "" if default.
	getProgram(name, subscript := "") {
		if(subscript) { ; Get the specific subscript.
			return this.programs[name][subscript]
		} else { ; Just return the whole array.
			return this.programs[name]
		}
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static initDone := false
	static settings := []
	static windows  := []
	static paths    := [] ; KEY => PATH
	static programs := []
	static games    := []
	static privates := [] ; KEY => VALUE
	
	loadPrivates(filePath) {
		tl := new TableList(filePath)
		privatesTable := tl.getTable()
		
		; Index private values by key.
		privatesAry := []
		For i,valueRow in privatesTable {
			key := valueRow["KEY"]
			if(key)
				privatesAry[key] := valueRow["VALUE"]
		}
		
		; DEBUG.popup("MainConfig.loadPrivates","Finish", "Filepath",filePath, "Table",privatesTable, "Indexed array",privatesAry)
		return privatesAry
	}
	
	loadSettings(filePath) {
		settingsAry := []
		settingsAry["MACHINE"]         := this.loadSettingFromFile(filePath, "MACHINE")         ; Which machine this is, from MACHINE_* constants
		settingsAry["MENU_KEY_ACTION"] := this.loadSettingFromFile(filePath, "MENU_KEY_ACTION") ; What to do with the menu key, from MENUKEYACTION_* constants
		
		; DEBUG.popup("Settings", settingsAry)
		return settingsAry
	}
	loadSettingFromFile(filePath, configName) {
		iniObj := new IniObject(filePath)
		return iniObj.get("Main", configName)
	}
	
	loadWindows(filePath) {
		tl := new TableList(filePath)
		filteredTable := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
		
		windowsAry := []
		For i,row in filteredTable
			windowsAry.push(new WindowInfo(row))
		
		return windowsAry
	}
	
	loadPaths(filePath) {
		tl := new TableList(filePath)
		pathsTable := tl.getFilteredTableUnique("NAME", "MACHINE", MainConfig.getMachine())
		
		; Index paths by key.
		pathsAry := []
		For i,row in pathsTable {
			key := row["KEY"]
			if(key)
				pathsAry[key] := row["PATH"]
		}
		
		; Apply calculated values and private tags.
		For key,value in pathsAry {
			value := replaceTag(value, "USER_ROOT", reduceFilepath(A_Desktop,  1))
			value := replaceTag(value, "AHK_ROOT",  reduceFilepath(A_LineFile, 3)) ; 2 levels out, plus one to get out of file itself.
			value := this.replacePrivateTags(value)
			pathsAry[key] := value ; make sure to store it back in the actual array
		}
		
		; DEBUG.popupEarly("mainConfig.loadPaths","Finish", "Paths",pathsAry)
		return pathsAry
	}
	
	loadPrograms(filePath) {
		tl := new TableList(filePath)
		programsTable := tl.getFilteredTableUnique("NAME", "MACHINE", this.getMachine())
		; DEBUG.popupEarly("MainConfig","loadPrograms", "Unique table",programsTable)
		
		; Index it by name.
		programsAry := []
		For i,row in programsTable {
			name := row["NAME"] ; Identifying name of this entry (which this.programs will be indexed by)
			
			if(!IsObject(programsAry[name])) ; Initialize the array.
				programsAry[name] := []
			
			programsAry[name] := row
		}
		; DEBUG.popupEarly("MainConfig","loadPrograms", "Finished programs",programsAry)
		
		return programsAry
	}
	
	loadGames(filePath) {
		tl := new TableList(filePath)
		return tl.getTable()
	}
	
	loadWindowsLegacy(filePath) {
		tl := new TableList(filePath)
		return tl.getFilteredTable("MACHINE", MainConfig.getMachine())
	}
}
