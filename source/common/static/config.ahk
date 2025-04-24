; Config class which holds the various options and settings that go into this set of scripts' slightly different behavior in different situations.

class Config {
	;region ------------------------------ PUBLIC ------------------------------
	debugOn := false ; GDB TODO window cache debug issue
	
	;---------
	; DESCRIPTION:    Whether this class has been initialized. Used to not show debug popups when
	;                 it's not initialized, to cut down on popups on restart in high-traffic areas.
	;---------
	isInitialized {
		get {
			return this.initDone
		}
	}
	
	
	;---------
	; DESCRIPTION:    Initialize this static config class. Loads information from various config files (see individual this.load* functions).
	;---------
	Init() {
		; Add automatic context/machine filters to TableList.
		TableList.addAutomaticFilter("CONTEXT", this.context)
		TableList.addAutomaticFilter("MACHINE", this.machine)
		
		this.initDone := true
	}
	
	
	;region Privates
	;---------
	; DESCRIPTION:    The private information from the privates file from initialization.
	; PARAMETERS:
	;  key(I,REQ) - The key to the bit of private info you want.
	;---------
	private[key] {
		get {
			return (this.privates)[key] ; Parens are so it doesn't try to pass a parameter to the this.privates property.
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
	;endregion Privates
	
	;region Settings
	;region Current machine checks
	;---------
	; DESCRIPTION:    Which machine we're configured to act as, from the Machine_* constants in this class.
	;---------
	machine {
		get {
			return this.setting["MACHINE"]
		}
	}
	;---------
	; DESCRIPTION:    Work laptop machine.
	;---------
	machineIsWorkDesktop {
		get {
			return (this.machine = Config.Machine_WorkDesktop)
		}
	}
	;---------
	; DESCRIPTION:    Work VDI machine.
	;---------
	machineIsWorkVDI {
		get {
			return (this.machine = Config.Machine_WorkVDI)
		}
	}
	;---------
	; DESCRIPTION:    Home desktop machine.
	;---------
	machineIsHomeDesktop {
		get {
			return (this.machine = Config.Machine_HomeDesktop)
		}
	}
	;---------
	; DESCRIPTION:    Home laptop machine.
	;---------
	machineIsHomeLaptop {
		get {
			return (this.machine = Config.Machine_HomeLaptop)
		}
	}
	;endregion Current machine checks
	
	;region Current context checks
	;---------
	; DESCRIPTION:    Which context we're configured to act as, from the Context_* constants in this class.
	;---------
	context {
		get {
			return this.setting["CONTEXT"]
		}
	}
	;---------
	; DESCRIPTION:    Work context
	;---------
	contextIsWork {
		get {
			return (this.context = Config.Context_Work)
		}
	}
	;---------
	; DESCRIPTION:    Home context
	;---------
	contextIsHome {
		get {
			return (this.context = Config.Context_Home)
		}
	}
	;endregion Current context checks
	;endregion Settings
	
	;region Windows
	;---------
	; DESCRIPTION:    Return the WindowInfo instance corresponding to the provided name.
	; PARAMETERS:
	;  name (I,REQ) - The name of the window to retrieve info for.
	;---------
	windowInfo[name] {
		get {
			return (this.windows)[name].clone() ; Parens are so it doesn't try to pass a parameter to the this.windows property.
		}
	}
	
	;---------
	; DESCRIPTION:    Check whether the named window is currently active.
	; PARAMETERS:
	;  name (I,REQ) - Name of the window to check for.
	; RETURNS:        The window ID if it's active, otherwise false.
	;---------
	isWindowActive(name) {
		return this.windowInfo[name].isActive()
	}
	
	;---------
	; DESCRIPTION:    Check whether the named window currently exists.
	; PARAMETERS:
	;  name (I,REQ) - Name of the window to check for.
	; RETURNS:        The window ID if it exists, otherwise false.
	;---------
	doesWindowExist(name) {
		return this.windowInfo[name].exists()
	}
	
	;---------
	; DESCRIPTION:    Check whether the given window matches the info with the provided name.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string identifying the window to check
	;  name        (I,REQ) - Name of the WindowInfo to compare it to
	; RETURNS:        true/false - does it match?
	;---------
	windowMatchesInfo(titleString, name) {
		return this.windowInfo[name].windowMatches(titleString)
	}
	
	;---------
	; DESCRIPTION:    Find the WindowInfo instance that matches the specified window.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string that identifies the window in question.
	; RETURNS:        The WindowInfo instance matching the specified window.
	;---------
	findWindowInfo(titleString) {
		exe   := WinGet("ProcessPath", titleString) ; Use full process path so win_exe values can match on full path if needed.
		class := WinGetClass(titleString)
		title := WinGetTitle(titleString)
		
		bestMatch := ""
		For _,winInfo in this.windows {
			if(!winInfo.windowMatchesPieces(exe, class, title))
				Continue
			
			; If we already found another match, don't replace it unless the new match has a better (lower) priority
			if((bestMatch != "") && bestMatch.priority < winInfo.priority)
				Continue
			
			; This is the best match we've found so far
			bestMatch := winInfo
		}
		
		if(Config.debugOn) { ; GDB TODO window cache debug issue
			debugString := "findWindowInfo():"
			debugString .= "`n" "titleString=" titleString
			debugString .= "`n" "exe" "=" exe "`t`t`t|`t`t`t" "bestMatch.exe" "=" bestMatch.exe
			debugString .= "`n" "class" "=" class "`t`t`t|`t`t`t" "bestMatch.class" "=" bestMatch.class
			debugString .= "`n" "title" "=" title "`t`t`t|`t`t`t" "bestMatch.title" "=" bestMatch.title
			debugString .= "`n" "bestMatch.name" "=" bestMatch.name
			debugString .= "`n" "bestMatch.clone().name" "=" bestMatch.clone().name
			debugString .= "`n" "(this.windows)[""Telegram""].name" "=" (this.windows)["Telegram"].name
			debugString .= "`n" "(Config.windows)[""Telegram""].name" "=" (Config.windows)["Telegram"].name
			debugString .= "`n" "(this._windows)[""Telegram""].name" "=" (this._windows)["Telegram"].name
			debugString .= "`n" "(Config._windows)[""Telegram""].name" "=" (Config._windows)["Telegram"].name
			MsgBox, % debugString
		}
		
		return bestMatch.clone() ; Handles "" fine ("".clone() = "")
	}
	
	;---------
	; DESCRIPTION:    Find the name of the specified window, if a WindowInfo instance exists.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string that identifies the window in question.
	; RETURNS:        The NAME for the matched WindowInfo instance.
	;---------
	findWindowName(titleString) {
		winInfo := this.findWindowInfo(titleString)
		return winInfo.name
	}
	
	;---------
	; DESCRIPTION:    Find the names of all WindowInfo instances that match the given window.
	; PARAMETERS:
	;  titleString (I,REQ) - Title string that identifies the window in question.
	; RETURNS:        Array of WindowInfo names, divided up by priority:
	;                    matchingNames[priority] := [name1, name2]
	;---------
	findAllMatchingWindowNames(titleString) {
		exe   := WinGet("ProcessPath", titleString) ; Use full process path so win_exe values can match on full path if needed.
		class := WinGetClass(titleString)
		title := WinGetTitle(titleString)
		
		matchingNames := {}
		For _,winInfo in this.windows {
			if(winInfo.windowMatchesPieces(exe, class, title)) {
				priority := winInfo.priority
				if(!matchingNames[priority])
					matchingNames[priority] := [winInfo.name]
				else
					matchingNames[priority].push(winInfo.name)
			}
		}
		
		if(DataLib.isNullOrEmpty(matchingNames))
			return ""
		return matchingNames
	}
	;endregion Windows
	
	;region Paths
	;---------
	; DESCRIPTION:    A particular path from this class.
	; PARAMETERS:
	;  key (I,REQ) - The key for the path you want.
	;---------
	path[key] {
		get {
			return (this.paths)[key] ; Parens are so it doesn't try to pass a parameter to the this.paths property.
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
	;endregion Paths
	
	;region Programs
	;---------
	; DESCRIPTION:    Activate the window matching the specified name, running it if it doesn't yet exist.
	; PARAMETERS:
	;  name    (I,REQ) - The name of the window to activate.
	;  runArgs (I,OPT) - If the window doesn't currently exist, we'll run the corresponding program with these parameters.
	;---------
	activateProgram(name, runArgs := "") { ; runArgs are only used if the program's window doesn't already exist (and we're therefore running it).
		HotkeyLib.waitForRelease()
		
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
		HotkeyLib.waitForRelease()
		
		prog := this.program[name]
		if (!prog) {
			Toast.ShowError("Program does not exist", name)
			return
		}
		
		prog.run(args)
	}

	;---------
	; DESCRIPTION:    Get the path for the named program.
	; PARAMETERS:
	;  name (I,REQ) - Name of the program we're interested in.
	; RETURNS:        Full program path
	;---------
	getProgramPath(name) {
		prog := this.program[name]
		if(prog)
			return prog.path
	}
	;endregion Programs
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	; Machines
	static Machine_WorkDesktop := "WORK_DESKTOP" ; Work desktop
	static Machine_WorkVDI     := "WORK_VDI"     ; Work VDI
	static Machine_HomeDesktop := "HOME_DESKTOP" ; Home desktop
	static Machine_HomeLaptop  := "HOME_LAPTOP"  ; Home laptop
	
	; Contexts
	static Context_Work := "WORK" ; Work context
	static Context_Home := "HOME" ; Home context
	
	static initDone        := false ; True once we're done initializing for the first time.
	static rootPath        := ""    ; The root of this set of scripts.
	
	; Private caches (initialized on first use via private properties below)
	static _settings       := ""    ; {NAME: VALUE}
	static _privates       := ""    ; {KEY: VALUE}
	static _windows        := ""    ; {NAME: WindowInfo}
	static _paths          := ""    ; {KEY: PATH}
	static _programs       := ""    ; {NAME: Program}
	
	
	;---------
	; DESCRIPTION:    Get the value for a specific setting from our settings.ini file.
	; PARAMETERS:
	;  key (I,REQ) - The key for the setting in question.
	; SIDE EFFECTS:   Initializes this._settings from the INI file the first time this is called.
	;---------
	setting[key] {
		get {
			if(!this._settings) {
				settingsINIPath := this.getPathInConfigFolder("settings.ini")
				
				this._settings := {}
				this._settings["MACHINE"]      := IniRead(settingsINIPath, "Main", "MACHINE")         ; Which machine this is, from Config.Machine_* constants
				this._settings["CONTEXT"]      := IniRead(settingsINIPath, "Main", "CONTEXT")         ; Which context this is, from Config.Context_* constants
			}
			
			return this._settings[key]
		}
	}
	
	;---------
	; DESCRIPTION:    Get the associative array of private info from our privates.tl file.
	; SIDE EFFECTS:   Initializes this._privates the first time this is called.
	;---------
	privates {
		get {
			if(!this._privates) {
				; This has to be explicit (rather than using this.path["AHK_PRIVATE"] like everywhere else should) because we use privates when we're first getting paths.
			 	privatesPath := FileLib.getParentFolder(this.getRoot()) "\ahkPrivate\privates.tl"
				
			 	this._privates := new TableList(privatesPath).getColumnByColumn("VALUE", "KEY")
			}
			
			return this._privates
		}
	}
	
	;---------
	; DESCRIPTION:    Get the associative array of window info objects from our windows.tl file.
	; SIDE EFFECTS:   Initializes this._windows the first time this is called.
	;---------
	windows {
		get {
			if(!this._windows) {
				this._windows := {}
				
				windowsTable := new TableList(this.getPathInConfigFolder("windows.tl")).getTable()
				For _,row in windowsTable {
					winInfo := new WindowInfo(row)
					name := winInfo.name
					if(name)
						this._windows[name] := winInfo
				}
			}
			
			return this._windows
		}
	}
	
	;---------
	; DESCRIPTION:    Get the associative array of paths from our paths.tl file.
	; SIDE EFFECTS:   Initializes this._paths the first time this is called.
	;---------
	paths {
		get {
			if(!this._paths) {
				pathsAry := new TableList(this.getPathInConfigFolder("paths.tl")).getColumnByColumn("PATH", "KEY")
				
				; Grab special path tags from the system to replace in the ones we just read in.
				systemPathTags := this.getSystemPathTags()
				
				; Replace calculated and private path tags.
				For key,path in pathsAry {
					; Special case: for tags which are exclusively pass-throughs (blank path), just use the matching tag's value (from either path or private).
					path := DataLib.coalesce(path, systemPathTags[key], this.private[key])
					
					path := path.replaceTags(systemPathTags)
					path := this.replacePrivateTags(path)
					
					pathsAry[key] := path ; make sure to store it back in the actual array
				}
				
				this._paths := pathsAry
			}
			
			return this._paths
		}
	}
	
	;---------
	; DESCRIPTION:    Get the Program object corresponding to the given name.
	; PARAMETERS:
	;  name (I,REQ) - The name of the program you want.
	; SIDE EFFECTS:   Initializes this._programs the first time this is called.
	;---------
	program[name] {
		get {
			if(!this._programs) {
				this._programs := {}
				
				; Turn each row into a Program object.
				programsTable := new TableList(this.getPathInConfigFolder("programs.tl")).getRowsByColumn("NAME", "MACHINE")
				For progName,row in programsTable
					this._programs[progName] := new Program(row)
			}
			
			return this._programs[name]
		}
	}
	
	;---------
	; DESCRIPTION:    Get an absolute path to a config file based on its relative path.
	; PARAMETERS:
	;  relativeConfigPath (I,REQ) - The path to the config file, from within the <root>\config\ folder. No leading backslash.
	;---------
	getPathInConfigFolder(relativeConfigPath) {
		return this.getRoot() "\config\" relativeConfigPath
	}
	
	;---------
	; DESCRIPTION:    Figure out the path to the root of this repository.
	; RETURNS:        The absolute path to the repository root (the top-level folder), no trailing backslash.
	;---------
	getRoot() {
		return FileLib.getParentFolder(A_LineFile, 4) ; Root path is 3 levels out, plus one to get out of file itself.
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
		tags["USER_DOCUMENTS"]     := A_MyDocuments                          ; C:\Users\<UserName>\Documents
		tags["USER_TEMP"]          := A_Temp                                 ; C:\Users\<UserName>\AppData\Local\Temp
		tags["USER_APPDATA"]       := A_AppData                              ; C:\Users\<UserName>\AppData\Roaming
		tags["USER_START_MENU"]    := A_StartMenu                            ; C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu
		tags["USER_STARTUP"]       := A_Startup                              ; C:\Users\<UserName>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
		tags["USER_DESKTOP"]       := A_Desktop                              ; C:\Users\<UserName>\Desktop
		tags["PROGRAM_FILES"]      := A_ProgramFiles                         ; C:\Program Files
		tags["PROGRAM_FILES_86"]   := EnvGet("ProgramFiles(x86)")            ; C:\Program Files (x86)
		tags["WINDOWS"]            := A_WinDir                               ; C:\Windows
		tags["CMD"]                := A_ComSpec                              ; C:\Windows\system32\cmd.exe
		tags["USER_ONEDRIVE"]      := EnvGet("ONEDRIVE")                     ; C:\Users\<UserName>\<OneDrive folder>
		
		ahkRoot := this.getRoot()
		tags["AHK_ROOT"] := ahkRoot
		
		; These repos live alongside the main one.
		ahkRootParent := FileLib.getParentFolder(ahkRoot)
		tags["AHK_PRIVATE"] := ahkRootParent "\ahkPrivate"
		tags["AHK_TEST"]    := ahkRootParent "\ahkTest"
		
		tags["EPIC_SOURCE_CURRENT"] := EpicLib.findCurrentVersionSourceFolder()
		tags["EMC2_CURRENT_EXE"]    := EpicLib.findCurrentEMC2Path()
		
		return tags
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
