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
		configFolder := getParentFolder(A_LineFile, 4) "\config" ; Root path is 3 levels out, plus one to get out of file itself.
		
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
		
		this.initDone := true
	}
	
	
	initialized[] {
		get {
			return this.initDone
		}
	}
	
	private[key] {
		get {
			if(!key)
				return ""
			return this.privates[key]
		}
	}
	replacePrivateTags(inputString) {
		return replaceTags(inputString, this.privates)
	}
	
	menuKeyAction[] {
		get {
			return this.settings["MENU_KEY_ACTION"]
		}
	}
	
	machine[] {
		get {
			return this.settings["MACHINE"]
		}
	}
	isMachine(machineName) {
		return (this.settings["MACHINE"] = machineName)
	}
	machineTLFilter[] {
		get {
			filter := []
			filter["COLUMN"] := "MACHINE"
			filter["VALUE"]  := this.settings["MACHINE"]
			return filter
		}
	}
	
	mediaPlayer[] {
		get {
			return this.settings["MEDIA_PLAYER"]
		}
	}
	isMediaPlayer(mediaPlayerName) {
		return (this.settings["MEDIA_PLAYER"] = mediaPlayerName)
	}
	doesMediaPlayerExist() {
		player := this.settings["MEDIA_PLAYER"]
		return this.doesWindowExist(player)
	}
	runMediaPlayer() {
		player := this.settings["MEDIA_PLAYER"]
		if(player) {
			; Always use runProgram based on the programs at play, but only show the "not yet running" toast if it really doesn't exist.
			if(!MainConfig.doesWindowExist(player))
				Toast.showMedium(player " not yet running, launching...")
			this.runProgram(player)
		}
	}
	
	windowInfo[name] {
		get {
			if(!name)
				return ""
			return this.windows[name].clone()
		}
	}
	isWindowActive(name) {
		return WinActive(this.windowInfo[name].titleString)
	}
	doesWindowExist(name) {
		return WinExist(this.windowInfo[name].titleString)
	}
	findWindowInfo(titleString := "A") {
		exe      := WinGet("ProcessName", titleString)
		ahkclass := WinGetClass(titleString)
		title    := WinGetTitle(titleString)
		
		bestMatch := ""
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
			
			; If we already found another match, don't replace it unless the new match has a better (lower) priority
			if((bestMatch != "") && bestMatch.priority < winInfo.priority)
				Continue
			
			; This is the best match we've found so far
			bestMatch := winInfo
		}
		
		return bestMatch.clone() ; Handles "" fine ("".clone() = "")
	}
	findWindowName(titleString := "A") {
		winInfo := this.findWindowInfo(titleString)
		return winInfo.name
	}
	
	path[key] {
		get {
			if(!key)
				return ""
			return this.paths[key]
		}
	}
	replacePathTags(inputPath) {
		return replaceTags(inputPath, this.paths)
	}
	
	programInfo[name] {
		get {
			if(!name)
				return ""
			return this.programs[name].clone()
		}
	}
	activateProgram(name) {
		waitForHotkeyRelease()
		
		if(this.doesWindowExist(name)) { ; If the program is already running, go ahead and activate it.
			WindowActions.activateWindowByName(name)
		} else { ; If it doesn't exist yet, we need to run the executable to make it happen.
			progInfo := this.programInfo[name]
			RunAsUser(progInfo.path, progInfo.args)
		}
	}
	runProgram(name) {
		waitForHotkeyRelease()
		
		progInfo := this.programInfo[name]
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
		windowsTable := tl.getFilteredTable("MACHINE", MainConfig.settings["MACHINE"])
		
		windowsAry := []
		For _,row in windowsTable {
			winInfo := new WindowInfo(row)
			name := winInfo.name
			if(name)
				windowsAry[name] := winInfo
		}
		
		return windowsAry
	}
	
	loadPaths(filePath) {
		tl := new TableList(filePath)
		pathsTable := tl.getFilteredTableUnique("NAME", "MACHINE", MainConfig.settings["MACHINE"])
		
		; Index paths by key.
		pathsAry := reduceTableToColumn(pathsTable, "PATH", "KEY")
		
		; Apply calculated values and private tags.
		userRootPath := getParentFolder(A_Desktop)
		ahkRootPath  := getParentFolder(A_LineFile, 4) ; This file lives in <AHK_ROOT>\source\common\class\.
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
		programsTable := tl.getFilteredTableUnique("NAME", "MACHINE", this.settings["MACHINE"])
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
}
