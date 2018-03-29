; Optional file of private variables.
#Include *i %A_LineFile%/../../../config/private/privateVariables.ahk

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
	static multiDelim := "|"
	static defaultSettings := {}
	static settings := []
	static windows  := []
	static folders  := [] ; abbrev => path ; GDB TODO update this, using KEY => PATH now?
	static programs := []
	static games    := []
	static privates := [] ; KEY => VALUE
	
	; init(settingsFile, windowsFile, pathsFile, programsFile, gamesFile, privateFile) {
	init(settingsFile, windowsFile, foldersFile, programsFile, gamesFile, privatesFile) {
		; All config files are expected to live in config/ folder under the root of this repo.
		ahkRootPath := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
		configFolder := ahkRootPath "\config"
		
		settingsPath := configFolder "\" settingsFile
		windowsPath  := configFolder "\" windowsFile
		foldersPath  := configFolder "\" foldersFile
		; pathsPath    := configFolder "\" pathsFile
		programsPath := configFolder "\" programsFile
		gamesPath    := configFolder "\" gamesFile
		privatesPath := configFolder "\" privatesFile
		
		this.privates := this.loadPrivates(privatesPath) ; This should be loaded before everything else, so the tags defined there can be used by other config files as needed.
		
		this.settings := this.loadSettings(settingsPath)
		this.windows  := this.loadWindows(windowsPath)
		this.folders  := this.loadFolders(foldersPath)
		; this.paths    := this.loadPaths(pathsPath)
		this.programs := this.loadPrograms(programsPath)
		this.games    := this.loadGames(gamesPath)
		
		; DEBUG.popup("MainConfig", "End of init", "Settings", this.settings, "Window settings", this.windows, "Program info", this.programs)
	}
	
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
		value := iniObj.get("Main", configName)
		; DEBUG.popup("Filepath", filePath, "Config name", configName, "Value", value)
		
		; Multi-entry value, put into an array.
		if(stringContains(value, this.multiDelim))
			return StrSplit(value, this.multiDelim)
		
		; Single value, use it as-is.
		else if(value)
			return value
		
		; Empty value, use default.
		return this.defaultSettings[configName]
	}
	
	loadWindows(filePath) {
		tl := new TableList(filePath)
		return tl.getFilteredTable("MACHINE", MainConfig.getMachine())
	}
	
	loadFolders(filePath) {
		; Tags that can be used in folders.tl
		systemTags := []
		systemTags["AHK_ROOT"]           := reduceFilepath(A_LineFile, 3) ; 2 levels out, plus one to get out of file itself.
		systemTags["USER_ROOT"]          := reduceFilepath(A_Desktop,  1)
		systemTags["EPIC_PERSONAL"]      := epicPersonal
		systemTags["EPIC_NFS_3DAY_UNIX"] := epicNFS3DayUnix
		systemTags["EPIC_NFS_3DAY"]      := epicNFS3Day
		systemTags["EPIC_NFS_ASK"]       := epicNFSAsk
		systemTags["EPIC_NET_HOME"]      := epicNetHome
		systemTags["EPIC_SOURCE_S1"]     := epicSourceCurrentS1
		systemTags["EPIC_SOURCE_S2"]     := epicSourceCurrentS2
		systemTags["EPIC_USERNAME"]      := epicUsername
		systemTags["EPIC_DBC_DESIGN"]    := epicDBCDesign
		
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
		
		; DEBUG.popup("mainConfig.loadFolders","finish", "Folders",folderPaths)
		return folderPaths
	}
	
	loadPrograms(filePath) {
		tl := new TableList(filePath)
		uniquePrograms := tl.getFilteredTableUnique("NAME", "MACHINE", this.getMachine())
		; DEBUG.popup("MainConfig", "loadPrograms", "Unique table", uniquePrograms)
		
		; Index it by name and machine.
		programsAry := []
		For i,pAry in uniquePrograms {
			name := pAry["NAME"] ; Identifying name of this entry (which this.programs will be indexed by)
			
			if(!IsObject(programsAry[name])) ; Initialize the array.
				programsAry[name] := []
			
			programsAry[name] := pAry
		}
		; DEBUG.popup("MainConfig", "loadPrograms", "Finished programs", programsAry)
		
		return programsAry
	}
	
	loadGames(filePath) {
		tl := new TableList(filePath)
		return tl.getTable()
	}
	
	
	
	; Note that this will return an array of values if that's what's in settings.
	getSetting(settingName = "") {
		if(settingName)
			return this.settings[settingName]
		else
			return this.settings
	}
	setSetting(settingName, value) {
		this.settings[settingName] := value
	}
	
	getPrivate(key) {
		if(!key)
			return ""
		return this.privates[key]
	}
	replacePrivateTags(inputString) {
		return replaceTags(inputString, this.privates)
	}
	
	getWindow(name = "", exe = "", ahkClass = "", title = "", text = "") {
		retWindow := ""
		if(!name && !exe && !ahkClass && !title && !text)
			return ""
		
		For i,w in this.windows {
			; DEBUG.popup("Against settings",w, "Name",name, "EXE",exe, "Class",ahkClass, "Title",title, "Text",text)
			if(name && w["NAME"] && (name != w["NAME"]))
				Continue
			if(exe && w["EXE"] && (exe != w["EXE"]))
				Continue
			if(ahkClass && w["CLASS"] && (ahkClass != w["CLASS"]))
				Continue
			if(title && w["TITLE"]) {
				if(stringStartsWith(w["TITLE"], "{REGEX}")) {
					regexNeedle := SubStr(w["TITLE"], StrLen("{REGEX}") + 1)
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
		
		; DEBUG.popup("MainConfig","getWindow", "Found window",retWindow)
		
		return retWindow
	}
	
	getFolder(abbrev) { ; GDB TODO update "abbrev"
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
		ahkExe := WinGet("ProcessName", titleString)
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
