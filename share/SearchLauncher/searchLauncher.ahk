/*
Author: Gavin Borg

Description: Grabs the selected text, asks the user how they want to search from it (codesearch+type or guru), and searches for it.

Installation:
	Copy the containing folder (SearchLauncher) to your local machine and run this script.
	
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	Shift+Alt+F:
		Grab the selected text, ask the user how they want to search it (codesearch+type, or Guru) and launch the search.
	
Notes:
	The INI file is in a tab-separated format:
		Columns must be separated by one or more tabs. Extra tabs are ignored.
		All columns are not required, but because we ignore extra tabs, you must have some non-whitespace character in order to skip a column (for example, the \x for the Guru line) to keep columns aligned.
		Columns are as follows:
			NAME        - Title shown for the given environment in the popup
			ABBREV      - Abbreviation shown for the environment
			SEARCH_TYPE - Type of search, either GURU or CODESEARCH by default
			SUBTYPE     - Currently only used with CODESEARCH, for server/client/records/etc
			ARG1...ARG5 - Strings to search for. Only ARG1 is filled in with selection, but others are available in the popup
		
		You can separate blocks of environments with titles using rows that begin with the # character.
		There are other special features available for the INI file, see selector.ahk if you're curious.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
	
	; File to read list of search types from.
	filePath := "search.ini"
}


; --------------------------------------------------
; - Setup, Includes, Constants ---------------------
; --------------------------------------------------
{
	#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
	#SingleInstance Force        ; Running this script while it's already running just replaces the existing instance.
	SendMode Input               ; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
	
	#Include Includes/
		#Include _trayHelper.ahk
		
		; For Selector use
		#Include data.ahk
		#Include io.ahk
		#Include selector.ahk
		#Include selectorRow.ahk
		#Include string.ahk
		#Include tableList.ahk
		#Include tableListMod.ahk
		#Include debug.ahk        ; For debug mode (i.e., using "+d val" in the input field, see selectorActions.ahk for details)
	
	; Constants
	global codeSearchBase := "http://codesearch/.NET/SearchModules/"
	global codeSearchEnd  := "/Results.aspx?versionid="
	global guruSearchBase := "http://guru/Search.aspx?search="
	global CODESEARCH_SERVER  := "Server"
	global CODESEARCH_CLIENT  := "Client"
	global CODESEARCH_RECORDS := "Records"
	global CODESEARCH_OTHER   := "ProgPoints"
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "SearchLauncher"
	description := "Takes the selected text and searches for it in one of several places based on the user's choice. See script header for details."
	
	hotkeys     := []
	hotkeys.Push(["Launch search popup",  "Shift + Alt + F"])
	hotkeys.Push(["Emergency exit", "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{	
	; Takes the selected text and searches for it based on the user's choice.
	+!f::
		text := gatherText(TEXT_SOURCE_SEL_CLIP)
		
		data := Selector.select(filePath, "RET_DATA", "", "", {"ARG1": text})
		searchType := data["SEARCH_TYPE"]
		searchTypes := StrSplit(data["SUBTYPE"], "|") ; In case multiple post types, pipe-delimited.
		
		criteria := []
		Loop, 5 {
			criteria[A_Index] := data["ARG" A_Index]
		}
		
		if(searchType = "CODESEARCH") {
			For i,st in searchTypes {
				url := buildCodeSearchURL(st, criteria)
				if(url)
					Run, % url
			}
		} else if(searchType = "GURU") {
			url := buildGuruURL(criteria[1])
			if(url)
				Run, % url
		}
	return
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
	buildCodeSearchURL(searchType, criteria = "", appID = 0, inline = false, exact = false, logic = "", case = false, nameFilter = 0, nameFilterText = "", perPage = 50) {
		versionID := 10
		showAll := 0 ; Whether to show every single matched line per result shown.
		
		; Gotta have some sort of criteria to open a search.
		if(!criteria || (searchType = ""))
			return ""
		
		; Basic URL, without parameters
		outURL := codeSearchBase searchType	codeSearchEnd versionID
		
		; Add the search criteria.
		i := 97 ; start at 'a'
		For j,c in criteria {
			Transform, letter, Chr, %i%
			outURL .= "&" letter "=" c
			i++
		}
		
		; Add on parameters.
		outURL .= "&applicationid="  appID
		outURL .= "&inline="         inline
		outURL .= "&exact="          exact
		outURL .= "&logic="          logic
		outURL .= "&case="           case
		outURL .= "&namefilter="     nameFilter
		outURL .= "&namefiltertext=" nameFilterText
		outURL .= "&perPage="        perpage
		outURL .= "&showall="        showall
		
		return outURL
	}

	buildGuruURL(criteria) {
		outURL := guruSearchBase
		
		return outURL criteria
	}
	
	; Return data array, for when we want more than just one value back.
	RET_DATA(actionRow) {
		if(actionRow.isDebug) ; Debug mode.
			actionRow.debugResult := actionRow.data
		
		return actionRow.data
	}
}


; --------------------------------------------------
; - Emergency exit ---------------------------------
; --------------------------------------------------
~^+!#r::ExitApp
