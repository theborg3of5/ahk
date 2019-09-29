/* Config class which holds the various options and settings that go into this set of scripts' slightly different behavior in different situations.
*/

class Config {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	; Constants for specific machines (matched to settings.ini).
	static Machine_WorkLaptop  := "WORK_LAPTOP"
	static Machine_WorkVDI     := "WORK_VDI"
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
	
	;---------
	; DESCRIPTION:    Initialize this static config class.
	; PARAMETERS:
	;  settingsFile (I,REQ) - 
	;  windowsFile  (I,REQ) - 
	;  pathsFile    (I,REQ) - 
	;  programsFile (I,REQ) - 
	;  gamesFile    (I,REQ) - 
	;  privatesFile (I,REQ) - 
	; RETURNS:        
	; SIDE EFFECTS:   
	; NOTES:          
	;---------
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
		
		; Read in settings and add automatic context/machine filters to TableList.
		this.settings := this.loadSettings(settingsPath)
		TableList.addAutomaticFilter("CONTEXT", this.context)
		TableList.addAutomaticFilter("MACHINE", this.machine)
		
		; Read in and process the other files.
		this.privates := this.loadPrivates(privatesPath) ; This should be loaded before most other things, as they can use the resulting tags.
		this.windows  := this.loadWindows(windowsPath)
		this.paths    := this.loadPaths(pathsPath)
		this.programs := this.loadPrograms(programsPath)
		this.games    := this.loadGames(gamesPath)
		; DEBUG.popupEarly("Config","Loaded all", "Settings",this.settings)
		; DEBUG.popupEarly("Config","Loaded all", "Windows",this.windows)
		; DEBUG.popupEarly("Config","Loaded all", "Paths",this.paths)
		; DEBUG.popupEarly("Config","Loaded all", "Programs",this.programs)
		; DEBUG.popupEarly("Config","Loaded all", "Games",this.games)
		
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
		return inputString.replaceTags(this.privates)
	}
	
	
	machine {
		get {
			return this.settings["MACHINE"]
		}
	}
	machineIsWorkLaptop {
		get {
			return (this.machine = Config.Machine_WorkLaptop)
		}
	}
	machineIsWorkVDI {
		get {
			return (this.machine = Config.Machine_WorkVDI)
		}
	}
	machineIsHomeDesktop {
		get {
			return (this.machine = Config.Machine_HomeDesktop)
		}
	}
	machineIsHomeLaptop {
		get {
			return (this.machine = Config.Machine_HomeLaptop)
		}
	}
	
	context {
		get {
			return this.settings["CONTEXT"]
		}
	}
	contextIsWork {
		get {
			return (this.context = Config.Context_Work)
		}
	}
	contextIsHome {
		get {
			return (this.context = Config.Context_Home)
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
				new Toast(player " not yet running, launching...").showMedium()
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
					stringMatchMode := Config.TitleContains_Any ; Default if not overridden
				
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
		return inputPath.replaceTags(this.paths)
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
			new ErrorToast("Could not run program: " name, "Path does not exist: " path).showMedium()
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
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	static initDone := false
	static settingsINIPath := ""
	static settings := {} ; {NAME: VALUE}
	static windows  := {} ; {NAME: WindowInfo}
	static paths    := {} ; {KEY: PATH}
	static programs := {} ; {NAME: ProgramInfo}
	static games    := [] ; [{NAME:name, EXE:exe}]
	static privates := {} ; {KEY: VALUE}
	
	
	loadPrivates(filePath) {
		privatesAry := new TableList(filePath).getColumnByColumn("VALUE", "KEY")
		
		; DEBUG.popup("Config.loadPrivates","Finish", "Filepath",filePath, "Table",privatesTable, "Indexed array",privatesAry)
		return privatesAry
	}
	
	loadSettings(filePath) {
		this.settingsINIPath := filePath
		
		settings := {}
		settings["MACHINE"]      := IniRead(this.settingsINIPath, "Main", "MACHINE")         ; Which machine this is, from Config.Machine_* constants
		settings["CONTEXT"]      := IniRead(this.settingsINIPath, "Main", "CONTEXT")         ; Which context this is, from Config.Context_* constants
		settings["MEDIA_PLAYER"] := IniRead(this.settingsINIPath, "Main", "MEDIA_PLAYER")    ; What program the media keys should deal with
		
		; DEBUG.popup("Settings", settings)
		return settings
	}
	
	loadWindows(filePath) {
		windowsTable := new TableList(filePath).getTable()
		
		windows := {}
		For _,row in windowsTable {
			winInfo := new WindowInfo(row)
			name := winInfo.name
			if(name)
				windows[name] := winInfo
		}
		
		return windows
	}
	
	loadPaths(filePath) {
		pathsAry := new TableList(filePath).getColumnByColumn("PATH", "KEY")
		
		; Grab special path tags from the system to replace in the ones we just read in.
		systemPathTags := this.getSystemPathTags()
		
		; Replace calculated and private path tags.
		For key,path in pathsAry {
			; Special case: for tags which are exclusively pass-throughs (blank path), just use the matching tag's value (from either path or private).
			if(path = "")
				path := systemPathTags[key]
			if(path = "")
				path := this.private[key]
			
			path := path.replaceTags(systemPathTags)
			path := this.replacePrivateTags(path)
			
			pathsAry[key] := path ; make sure to store it back in the actual array
		}
		
		; DEBUG.popupEarly("Config.loadPaths","Finish", "Paths",pathsAry)
		return pathsAry
	}
	
	getSystemPathTags() {
		tags := {}
		
		tags["PROGRAM_DATA"]       := A_AppDataCommon                        ; C:\ProgramData
		tags["USER_ROOT"]          := EnvGet("HOMEDRIVE") EnvGet("HOMEPATH") ; C:\Users\<UserName>
		tags["USER_APPDATA_LOCAL"] := EnvGet("LOCALAPPDATA")                 ; C:\Users\<UserName>\AppData\Local
		tags["USER_TEMP"]          := A_Temp                                 ; C:\Users\<UserName>\AppData\Local\Temp
		tags["USER_APPDATA"]       := A_AppData                              ; C:\Users\<UserName>\AppData\Roaming
		tags["USER_START_MENU"]    := A_StartMenu                            ; C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu
		tags["USER_STARTUP"]       := A_Startup                              ; C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
		tags["USER_DESKTOP"]       := A_Desktop                              ; C:\Users\<UserName>\Desktop
		tags["PROGRAM_FILES"]      := A_ProgramFiles                         ; C:\Program Files
		tags["PROGRAM_FILES_86"]   := EnvGet("ProgramFiles(x86)")            ; C:\Program Files (x86)
		tags["WINDOWS"]            := A_WinDir                               ; C:\Windows
		tags["CMD"]                := A_ComSpec                              ; C:\Windows\system32\cmd.exe
		
		tags["AHK_ROOT"]           := getParentFolder(A_LineFile, 4)         ; Top-level ahk folder, this file lives in <AHK_ROOT>\source\common\class\
		
		return tags
	}
	
	loadPrograms(filePath) {
		programsTable := new TableList(filePath).getRowsByColumn("NAME", "MACHINE")
		; DEBUG.popupEarly("Config","loadPrograms", "Unique table",programsTable)
		
		; Turn each row into a ProgramInfo object.
		programs := {}
		For name,row in programsTable
			programs[name] := new ProgramInfo(row)
		; DEBUG.popupEarly("Config","loadPrograms", "Finished programs",programs)
		
		return programs
	}
	
	loadGames(filePath) {
		return new TableList(filePath).getTable()
	}
	
	matchesWithMethod(haystack, needle, method := "ANY") { ; method := Config.TitleContains_Any
		if(method = Config.TitleContains_Any)
			return haystack.contains(needle)
		
		else if(method = Config.TitleContains_Start)
			return haystack.startsWith(needle)
		
		else if(method = Config.TitleContains_End)
			return haystack.endsWith(needle)
		
		else if(method = Config.TitleContains_Exact)
			return (haystack = needle)
		
		DEBUG.popup("Unsupported match method",method)
		return ""
	}
}
