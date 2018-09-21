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
	
	init(settingsFile, windowsFile, pathsFile, programsFile, gamesFile, privatesFile) {
		; All config files are expected to live in config/ folder under the root of this repo.
		ahkRootPath := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
		configFolder := ahkRootPath "\config"
		
		; Build full paths to config files
		settingsPath := configFolder "\" settingsFile
		windowsPath  := configFolder "\" windowsFile
		pathsPath    := configFolder "\" pathsFile
		programsPath := configFolder "\" programsFile
		gamesPath    := configFolder "\" gamesFile
		privatesPath := configFolder "\" privatesFile
		
		; Read in and process the files.
		this.privates := this.loadPrivates(privatesPath) ; This should be loaded before everything else, so the tags defined there can be used by other config files as needed.
		this.settings := this.loadSettings(settingsPath)
		this.windows  := this.loadWindows(windowsPath)
		this.paths    := this.loadPaths(pathsPath)
		this.programs := this.loadPrograms(programsPath)
		this.games    := this.loadGames(gamesPath)
		; DEBUG.popupEarly("MainConfig","Loaded all", "Settings",this.settings, "Windows",this.windows, "Paths",this.paths, "Programs",this.programs, "Games",this.games)
		
		; Create indexed versions of some of our information, for easier access.
		this.windowsByName := this.loadWindowsByName(this.windows)
		
		this.initDone := true
	}
	
	
	isInitialized() {
		return this.initDone
	}
	
	getPrivate(key) {
		if(!key)
			return ""
		return this.privates[key]
	}
	replacePrivateTags(inputString) {
		return replaceTags(inputString, this.privates)
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
	
	getWindowInfo(name) {
		if(!name)
			return ""
		
		return this.windowsByName[name].clone()
	}
	getWindowTitleString(name) {
		if(!name)
			return ""
		
		return this.windowsByName[name].titleString
	}
	isWindowActive(name) {
		return WinActive(this.getWindowInfo(name).titleString)
	}
	doesWindowExist(name) {
		return WinExist(this.getWindowInfo(name).titleString)
	}
	findWindowInfo(titleString := "A") {
		exe      := WinGet("ProcessName", titleString)
		ahkclass := WinGetClass(titleString)
		title    := WinGetTitle(titleString)
		
		For i,winInfo in this.windows {
			; DEBUG.popup("Against WindowInfo",winInfo, "EXE",exe, "Class",ahkClass, "Title",title)
			if(exe      && winInfo.exe   && (exe != winInfo.exe))
				Continue
			if(ahkClass && winInfo.class && (ahkClass != winInfo.class))
				Continue
			if(title    && winInfo.title) {
				; Allow titles to be compared more flexibly than straight equality.
				stringMatchMode := winInfo.titleStringMatchModeOverride
				if(!stringMatchMode)
					stringMatchMode := CONTAINS_ANY ; Default if not overridden
				
				if(!stringMatches(title, winInfo.title, stringMatchMode))
					Continue
			}
			
			return winInfo.clone()
		}
		
		return ""
	}
	findWindowName(titleString := "A") {
		winInfo := this.findWindowInfo(titleString)
		return winInfo.name
	}
	
	getPath(key) {
		if(!key)
			return ""
		return this.paths[key]
	}
	replacePathTags(inputPath) {
		return replaceTags(inputPath, this.paths)
	}
	
	getProgramInfo(name) {
		return this.programs[name]
	}
	getProgramPath(name) {
		if(!name)
			return ""
		
		return this.programs[name].path
	}
	activateProgram(name) {
		waitForHotkeyRelease()
		
		if(this.doesWindowExist(name)) { ; If the program is already running, go ahead and activate it.
			WindowActions.activateWindowByName(name)
		} else { ; If it doesn't exist yet, we need to run the executable to make it happen.
			progInfo := this.getProgramInfo(name)
			RunAsUser(progInfo.path, progInfo.args)
		}
	}
	runProgram(name) {
		waitForHotkeyRelease()
		
		progInfo := this.getProgramInfo(name)
		RunAsUser(progInfo.path, progInfo.args)
	}
	
	windowIsGame(titleString := "A") {
		ahkExe := WinGet("ProcessName", titleString)
		if(!ahkExe)
			return false
		
		For i,game in this.games
			if(ahkExe = game["EXE"])
				return true
		
		return false
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
	
	static windowsByName := []
	
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
		windowsTable := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
		
		windowsAry := []
		For i,row in windowsTable
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
			row["PATH"] := this.replacePathTags(row["PATH"])
			programsAry[row["NAME"]] := new ProgramInfo(row)
		}
		; DEBUG.popupEarly("MainConfig","loadPrograms", "Finished programs",programsAry)
		
		return programsAry
	}
	
	loadGames(filePath) {
		tl := new TableList(filePath)
		return tl.getTable()
	}
	
	
	loadWindowsByName(windowsByLineNum) {
		windowsAry := []
		For i,winInfo in windowsByLineNum
			windowsAry[winInfo.name] := winInfo
		return windowsAry
	}
}
