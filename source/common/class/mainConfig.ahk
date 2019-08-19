/* Config class which holds the various options and settings that go into this set of scripts' slightly different behavior in different situations.
*/

class MainConfig {

; ==============================
; == Public ====================
; ==============================
	; Constants for specific machines (matched to settings.ini).
	static Machine_EpicLaptop  := "EPIC_LAPTOP"
	static Machine_EpicVDI     := "EPIC_VDI"
	static Machine_HomeLaptop  := "HOME_LAPTOP"
	static Machine_HomeDesktop := "HOME_DESKTOP"
	
	; Constants for contexts
	static Context_Work := "WORK"
	static Context_Home := "HOME"
	
	; Title string matching modes
	static TitleContains_Any   := "ANY"
	static TitleContains_Start := "START"
	static TitleContains_End   := "END"
	static TitleContains_Exact := "EXACT"
	
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
		; DEBUG.popupEarly("MainConfig","Loaded all", "Settings",this.settings)
		; DEBUG.popupEarly("MainConfig","Loaded all", "Windows",this.windows)
		; DEBUG.popupEarly("MainConfig","Loaded all", "Paths",this.paths)
		; DEBUG.popupEarly("MainConfig","Loaded all", "Programs",this.programs)
		; DEBUG.popupEarly("MainConfig","Loaded all", "Games",this.games)
		
		this.initDone := true
	}
	
	
	initialized {
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
	
	
	machine {
		get {
			return this.settings["MACHINE"]
		}
	}
	machineIsEpicLaptop {
		get {
			return (this.machine = MainConfig.Machine_EpicLaptop)
		}
	}
	machineIsEpicVDI {
		get {
			return (this.machine = MainConfig.Machine_EpicVDI)
		}
	}
	machineIsHomeDesktop {
		get {
			return (this.machine = MainConfig.Machine_HomeDesktop)
		}
	}
	machineIsHomeLaptop {
		get {
			return (this.machine = MainConfig.Machine_HomeLaptop)
		}
	}
	machineSelectorFilter {
		get {
			filter := []
			filter["COLUMN"] := "MACHINE"
			filter["VALUE"]  := this.machine
			return filter
		}
	}
	
	context {
		get {
			return this.settings["CONTEXT"]
		}
	}
	contextIsWork {
		get {
			return (this.context = MainConfig.Context_Work)
		}
	}
	contextIsHome {
		get {
			return (this.context = MainConfig.Context_Home)
		}
	}
	contextSelectorFilter {
		get {
			filter := []
			filter["COLUMN"] := "CONTEXT"
			filter["VALUE"]  := this.context
			return filter
		}
	}
	
	mediaPlayer {
		get {
			return this.settings["MEDIA_PLAYER"]
		}
		set {
			this.settings["MEDIA_PLAYER"] := value
			IniWrite, % value, % this.settingsINIPath, % "Main", % "MEDIA_PLAYER"
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
			if(!this.doesWindowExist(player))
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
					stringMatchMode := MainConfig.TitleContains_Any ; Default if not overridden
				
				if(!this.matchesWithMethod(title, winInfo.title, stringMatchMode))
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
	
	activateProgram(name, runArgs := "") { ; runArgs are only used if the program's window doesn't already exist (and we're therefore running it).
		waitForHotkeyRelease()
		
		if(this.doesWindowExist(name)) ; If the program is already running, go ahead and activate it.
			WindowActions.activateWindowByName(name)
		else ; If it doesn't exist yet, we need to run the executable to make it happen.
			this.runProgram(name, runArgs)
	}
	runProgram(name, args := "") {
		waitForHotkeyRelease()
		
		path := this.programs[name].path
		if(!FileExist(path)) {
			Toast.showError("Could not run program: " name, "Path does not exist: " path)
			return
		}
		
		runAsUser(path, args)
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
	
	static settingsINIPath
	
	loadPrivates(filePath) {
		tl := new TableList(filePath)
		privatesTable := tl.getTable()
		
		; Index private values by key.
		privatesAry := reduceTableToColumn(privatesTable, "VALUE", "KEY")
		
		; DEBUG.popup("MainConfig.loadPrivates","Finish", "Filepath",filePath, "Table",privatesTable, "Indexed array",privatesAry)
		return privatesAry
	}
	
	loadSettings(filePath) {
		this.settingsINIPath := filePath
		
		settingsAry := []
		settingsAry["MACHINE"]         := IniRead(this.settingsINIPath, "Main", "MACHINE")         ; Which machine this is, from MainConfig.Machine_* constants
		settingsAry["CONTEXT"]         := IniRead(this.settingsINIPath, "Main", "CONTEXT")         ; Which context this is, from MainConfig.Context_* constants
		settingsAry["MEDIA_PLAYER"]    := IniRead(this.settingsINIPath, "Main", "MEDIA_PLAYER")    ; What program the media keys should deal with
		
		; DEBUG.popup("Settings", settingsAry)
		return settingsAry
	}
	
	loadWindows(filePath) {
		tl := new TableList(filePath)
		windowsTable := tl.getTable()
		
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
		pathsTable := tl.getFilteredTableUnique("NAME", "CONTEXT", this.context)
		
		; Index paths by key.
		pathsAry := reduceTableToColumn(pathsTable, "PATH", "KEY")
		
		; Grab and calculate special paths from the system/relative to this script.
		pathTagsAry := mergeArrays(this.getSystemPathTags(), this.getCalculatedPathTags())
		
		; Replace calculated and private path tags.
		For key,path in pathsAry {
			; Special case: for tags which are exclusively pass-throughs (blank path), just use the matching tag's value (from either path or private).
			if(path = "")
				path := pathTagsAry[key]
			if(path = "")
				path := this.private[key]
			
			path := replaceTags(path, pathTagsAry)
			path := this.replacePrivateTags(path)
			
			pathsAry[key] := path ; make sure to store it back in the actual array
		}
		
		; DEBUG.popupEarly("mainConfig.loadPaths","Finish", "Paths",pathsAry)
		return pathsAry
	}
	
	getSystemPathTags() {
		tagsAry := []
		
		tagsAry["PROGRAM_DATA"]       := A_AppDataCommon                        ; C:\ProgramData
		tagsAry["USER_ROOT"]          := EnvGet("HOMEDRIVE") EnvGet("HOMEPATH") ; C:\Users\<UserName>
		tagsAry["USER_APPDATA_LOCAL"] := EnvGet("LOCALAPPDATA")                 ; C:\Users\<UserName>\AppData\Local
		tagsAry["USER_TEMP"]          := A_Temp                                 ; C:\Users\<UserName>\AppData\Local\Temp
		tagsAry["USER_APPDATA"]       := A_AppData                              ; C:\Users\<UserName>\AppData\Roaming
		tagsAry["USER_START_MENU"]    := A_StartMenu                            ; C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu
		tagsAry["USER_STARTUP"]       := A_Startup                              ; C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
		tagsAry["USER_DESKTOP"]       := A_Desktop                              ; C:\Users\<UserName>\Desktop
		tagsAry["PROGRAM_FILES"]      := A_ProgramFiles                         ; C:\Program Files
		tagsAry["PROGRAM_FILES_86"]   := EnvGet("ProgramFiles(x86)")            ; C:\Program Files (x86)
		tagsAry["WINDOWS"]            := A_WinDir                               ; C:\Windows
		tagsAry["CMD"]                := A_ComSpec                              ; C:\Windows\system32\cmd.exe
		
		return tagsAry
	}
	
	getCalculatedPathTags() {
		tagsAry := []
		
		tagsAry["AHK_ROOT"] := getParentFolder(A_LineFile, 4) ; Top-level ahk folder, this file lives in <AHK_ROOT>\source\common\class\
		
		return tagsAry
	}
	
	loadPrograms(filePath) {
		tl := new TableList(filePath)
		programsTable := tl.getFilteredTableUnique("NAME", "MACHINE", this.machine)
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
	
	matchesWithMethod(haystack, needle, method := "ANY") { ; method := MainConfig.TitleContains_Any
		if(method = MainConfig.TitleContains_Any)
			return haystack.contains(needle)
		
		else if(method = MainConfig.TitleContains_Start)
			return haystack.startsWith(needle)
		
		else if(method = MainConfig.TitleContains_End)
			return haystack.endsWith(needle)
		
		else if(method = MainConfig.TitleContains_Exact)
			return (haystack = needle)
		
		DEBUG.popup("Unsupported match method",method)
		return ""
	}
}
