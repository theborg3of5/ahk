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
	;  settingsFile (I,REQ) - Name or path of the settings INI file.
	;  windowsFile  (I,REQ) - Name or path of the windows TL file.
	;  pathsFile    (I,REQ) - Name or path of the paths TL file.
	;  programsFile (I,REQ) - Name or path of the programs TL file.
	;  gamesFile    (I,REQ) - Name or path of the games TL file.
	;  privatesFile (I,REQ) - Name or path of the privates TL file.
	; NOTES:          All names/paths must be found in the \config folder in the root of this repository.
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
	
	;---------
	; DESCRIPTION:    Whether this class has been initialized. Used to not show debug popups when
	;                 it's not initialized, to cut down on popups on restart in high-traffic areas.
	;---------
	initialized {
		get {
			return this.initDone
		}
	}
	
	;---------
	; DESCRIPTION:    The private information from the privates file from initialization.
	; PARAMETERS:
	;  key(I,REQ) - The key to the bit of private info you want.
	;---------
	private[key] {
		get {
			if(!key)
				return ""
			return this.privates[key]
		}
	}
	;---------
	; DESCRIPTION:    Replace any tags matching private keys, with those corresponding private values.
	; PARAMETERS:
	;  inputString (I,REQ) - The string to search and replace within.
	; RETURNS:        The updated string
	;---------
	replacePrivateTags(inputString) {
		return inputString.replaceTags(this.privates)
	}
	
	;---------
	; DESCRIPTION:    Which machine we're configured to act as, from the Machine_* constants in this class.
	;---------
	machine {
		get {
			return this.settings["MACHINE"]
		}
	}
	;---------
	; DESCRIPTION:    Convenience functions for checking whether we're currently a certain machine.
	; RETURNS:        true if we are the machine in question, false otherwise.
	;---------
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
	
	;---------
	; DESCRIPTION:    Which context we're configured to act as, from the Context_* constants in this class.
	;---------
	context {
		get {
			return this.settings["CONTEXT"]
		}
	}
	;---------
	; DESCRIPTION:    Convenience functions for checking whether we're currently in a certain context
	; RETURNS:        true if we are in the context in question, false otherwise.
	;---------
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
	
	;---------
	; DESCRIPTION:    The name of the media player to use (from the NAME column in mediaPlayers.tls).
	;---------
	mediaPlayer {
		get {
			return this.settings["MEDIA_PLAYER"]
		}
		set {
			this.settings["MEDIA_PLAYER"] := value
			IniWrite, % value, % this.settingsINIPath, % "Main", % "MEDIA_PLAYER"
		}
	}
	;---------
	; DESCRIPTION:    Whether the named media player is what we're configured to use.
	; PARAMETERS:
	;  mediaPlayerName (I/O/IO,REQ/OPT) - 
	; RETURNS:        true if we're configured to use the media player, false otherwise.
	;---------
	isMediaPlayer(mediaPlayerName) {
		return (this.settings["MEDIA_PLAYER"] = mediaPlayerName)
	}
	;---------
	; DESCRIPTION:    Check whether a window for the current media player exists.
	; RETURNS:        true if it does exist, false otherwise.
	;---------
	doesMediaPlayerExist() {
		player := this.settings["MEDIA_PLAYER"]
		return this.doesWindowExist(player)
	}
	;---------
	; DESCRIPTION:    Run the currently configured media player.
	;---------
	runMediaPlayer() {
		player := this.settings["MEDIA_PLAYER"]
		if(player) {
			; Always use runProgram based on the programs at play, but only show the "not yet running" toast if it really doesn't exist.
			if(!this.doesWindowExist(player))
				new Toast(player " not yet running, launching...").showMedium()
			this.runProgram(player)
		}
	}
	
	;---------
	; DESCRIPTION:    Return the WindowInfo instance corresponding to the provided name.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to retrieve info for.
	;---------
	windowInfo[name] {
		get {
			if(!name)
				return ""
			return this.windows[name].clone()
		}
	}
	;---------
	; DESCRIPTION:    Check whether the named window is currently active.
	; PARAMETERS:
	;  name (I,REQ) - Name of the window to check for.
	; RETURNS:        true if it's active, false otherwise.
	;---------
	isWindowActive(name) {
		return WinActive(this.windowInfo[name].titleString)
	}
	;---------
	; DESCRIPTION:    Check whether the named window currently exists.
	; PARAMETERS:
	;  name (I,REQ) - Name of the window to check for.
	; RETURNS:        true if it exists, false otherwise.
	;---------
	doesWindowExist(name) {
		return WinExist(this.windowInfo[name].titleString)
	}
	;---------
	; DESCRIPTION:    Find the WindowInfo instance that matches the specified window.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies the window in question. Defaults to the active window.
	; RETURNS:        The WindowInfo instance matching the specified window.
	;---------
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
	;---------
	; DESCRIPTION:    Find the name of the specified window, if a WindowInfo instance exists.
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies the window in question. Defaults to the active window.
	; RETURNS:        The NAME for the matched WindowInfo instance.
	;---------
	findWindowName(titleString := "A") {
		winInfo := this.findWindowInfo(titleString)
		return winInfo.name
	}
	
	;---------
	; DESCRIPTION:    A particular path from this class.
	; PARAMETERS:
	;  key (I,REQ) - The key for the path you want.
	;---------
	path[key] {
		get {
			if(!key)
				return ""
			return this.paths[key]
		}
	}
	;---------
	; DESCRIPTION:    Replace any tags matching path keys, with those corresponding paths.
	; PARAMETERS:
	;  inputString (I,REQ) - The string to search and replace within.
	; RETURNS:        The updated string
	;---------
	replacePathTags(inputPath) {
		return inputPath.replaceTags(this.paths)
	}
	
	;---------
	; DESCRIPTION:    Activate the window matching the specified name, running it if it doesn't yet exist.
	; PARAMETERS:
	;  name    (I,REQ) - The name of the window to activate.
	;  runArgs (I,OPT) - If the window doesn't currently exist, we'll run the corresponding program with these parameters.
	;---------
	activateProgram(name, runArgs := "") { ; runArgs are only used if the program's window doesn't already exist (and we're therefore running it).
		waitForHotkeyRelease()
		
		if(this.doesWindowExist(name)) ; If the program is already running, go ahead and activate it.
			WindowActions.activateWindowByName(name)
		else ; If it doesn't exist yet, we need to run the executable to make it happen.
			this.runProgram(name, runArgs)
	}
	;---------
	; DESCRIPTION:    Run the program matching the specified name.
	; PARAMETERS:
	;  name (I,REQ) - The name of the program to run.
	;  args (I,OPT) - The arguments to run the program with.
	;---------
	runProgram(name, args := "") {
		waitForHotkeyRelease()
		
		path := this.programs[name].path
		if(!FileExist(path)) {
			new ErrorToast("Could not run program: " name, "Path does not exist: " path).showMedium()
			return
		}
		
		runAsUser(path, args)
	}
	
	;---------
	; DESCRIPTION:    Check whether the specified window is a game (as identified in the games file passed in).
	; PARAMETERS:
	;  titleString (I,OPT) - Title string that identifies the window in question. Defaults to the active window.
	; RETURNS:        true if the specified window is a game, false otherwise.
	;---------
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
	
	;---------
	; DESCRIPTION:    Read in and store the contents of the privates file.
	; PARAMETERS:
	;  filePath (I,REQ) - Path to the file to read in.
	; RETURNS:        The compiled array of private bits.
	;---------
	loadPrivates(filePath) {
		privatesAry := new TableList(filePath).getColumnByColumn("VALUE", "KEY")
		
		; DEBUG.popup("Config.loadPrivates","Finish", "Filepath",filePath, "Table",privatesTable, "Indexed array",privatesAry)
		return privatesAry
	}
	
	;---------
	; DESCRIPTION:    Read in and store the contents of the settings file.
	; PARAMETERS:
	;  filePath (I,REQ) - Path to the file to read in.
	; RETURNS:        The compiled array of settings.
	;---------
	loadSettings(filePath) {
		this.settingsINIPath := filePath
		
		settings := {}
		settings["MACHINE"]      := IniRead(this.settingsINIPath, "Main", "MACHINE")         ; Which machine this is, from Config.Machine_* constants
		settings["CONTEXT"]      := IniRead(this.settingsINIPath, "Main", "CONTEXT")         ; Which context this is, from Config.Context_* constants
		settings["MEDIA_PLAYER"] := IniRead(this.settingsINIPath, "Main", "MEDIA_PLAYER")    ; What program the media keys should deal with
		
		; DEBUG.popup("Settings", settings)
		return settings
	}
	
	;---------
	; DESCRIPTION:    Read in and store the contents of the windows file.
	; PARAMETERS:
	;  filePath (I,REQ) - Path to the file to read in.
	; RETURNS:        The compiled array of WindowInfo instances.
	;---------
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
	
	;---------
	; DESCRIPTION:    Read in and store the contents of the paths file.
	; PARAMETERS:
	;  filePath (I,REQ) - Path to the file to read in.
	; RETURNS:        The compiled array of paths.
	;---------
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
	;---------
	; DESCRIPTION:    Build a hard-coded array of KEY => PATH pairs that can be used to replace
	;                 strings (and will also be applied to other paths as we read them in).
	; RETURNS:        Array of path tags, {KEY => PATH}
	;---------
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
	
	;---------
	; DESCRIPTION:    Read in and store the contents of the programs file.
	; PARAMETERS:
	;  filePath (I,REQ) - Path to the file to read in.
	; RETURNS:        The compiled array of ProgramInfo instances.
	;---------
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
	
	;---------
	; DESCRIPTION:    Read in and store the contents of the games file.
	; PARAMETERS:
	;  filePath (I,REQ) - Path to the file to read in.
	; RETURNS:        The compiled array of games arrays.
	;---------
	loadGames(filePath) {
		return new TableList(filePath).getTable()
	}
	
	;---------
	; DESCRIPTION:    Check whether the provided string contains a search string, with a specified match method.
	; PARAMETERS:
	;  haystack (I,REQ) - The string to search within.
	;  needle   (I,REQ) - The string to search for.
	;  method   (I,OPT) - The method to use when searching, from TitleContains_* constants in this class.
	; RETURNS:        For TitleContains_Any, the position where we found the match. For everything
	;                 else, true/false for whether we found a match.
	;---------
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
