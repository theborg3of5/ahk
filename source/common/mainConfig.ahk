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
		ahkRootPath := getParentFolder(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
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
	setSetting(settingName, newValue) {
		if(!settingName)
			return
		
		this.settings[settingName] := newValue
		this.settingsINIObject.set("Main", settingName, newValue)
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
	getMediaPlayer() {
		return this.settings["MEDIA_PLAYER"]
	}
	isMediaPlayer(mediaPlayerName) {
		return (this.settings["MEDIA_PLAYER"] = mediaPlayerName)
	}
	doesMediaPlayerExist() {
		player := this.getMediaPlayer()
		return this.doesWindowExist(player)
	}
	runMediaPlayer() {
		player := this.getMediaPlayer()
		if(player) {
			; Always use runProgram based on the programs at play, but only show the "not yet running" toast if it really doesn't exist.
			if(!MainConfig.doesWindowExist(player))
				Toast.showMedium(player " not yet running, launching...")
			this.runProgram(player)
		}
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
		
		For _,winInfo in this.windows {
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
		
		For _,game in this.games
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
	
	static settingsINIObject
	
	loadPrivates(filePath) {
		tl := new TableList(filePath)
		privatesTable := tl.getTable()
		
		; Index private values by key.
		privatesAry := reduceTableToColumn(privatesTable, "VALUE", "KEY")
		
		; DEBUG.popup("MainConfig.loadPrivates","Finish", "Filepath",filePath, "Table",privatesTable, "Indexed array",privatesAry)
		return privatesAry
	}
	
	loadSettings(filePath) {
		this.settingsINIObject := new IniObject(filePath)
		
		settingsAry := []
		settingsAry["MACHINE"]         := this.settingsINIObject.get("Main", "MACHINE")         ; Which machine this is, from MACHINE_* constants
		settingsAry["MENU_KEY_ACTION"] := this.settingsINIObject.get("Main", "MENU_KEY_ACTION") ; What to do with the menu key, from MENUKEYACTION_* constants
		settingsAry["MEDIA_PLAYER"]    := this.settingsINIObject.get("Main", "MEDIA_PLAYER")    ; What program the media keys should deal with
		
		; DEBUG.popup("Settings", settingsAry)
		return settingsAry
	}
	
	loadWindows(filePath) {
		tl := new TableList(filePath)
		windowsTable := tl.getFilteredTable("MACHINE", MainConfig.getMachine())
		
		windowsAry := []
		For _,row in windowsTable
			windowsAry.push(new WindowInfo(row))
		
		return windowsAry
	}
	
	loadPaths(filePath) {
		tl := new TableList(filePath)
		pathsTable := tl.getFilteredTableUnique("NAME", "MACHINE", MainConfig.getMachine())
		
		; Index paths by key.
		pathsAry := reduceTableToColumn(pathsTable, "PATH", "KEY")
		
		; Apply calculated values and private tags.
		userRootPath := getParentFolder(A_Desktop)
		ahkRootPath  := getParentFolder(A_LineFile, 3) ; This file lives in <AHK_ROOT>\source\common\.
		For key,value in pathsAry {
			value := replaceTag(value, "USER_ROOT", userRootPath)
			value := replaceTag(value, "AHK_ROOT",  ahkRootPath)
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
		For _,row in programsTable
			programsAry[row["NAME"]] := new ProgramInfo(row)
		; DEBUG.popupEarly("MainConfig","loadPrograms", "Finished programs",programsAry)
		
		return programsAry
	}
	
	loadGames(filePath) {
		tl := new TableList(filePath)
		return tl.getTable()
	}
	
	
	loadWindowsByName(windowsByLineNum) {
		windowsAry := []
		For _,winInfo in windowsByLineNum
			windowsAry[winInfo.name] := winInfo
		return windowsAry
	}
}
