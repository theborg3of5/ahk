; Search hotkeys and tools.

; Generic search for selected text.
!+f::
	selectSearch() {
		text := getSelectedText().firstLine().clean()
		
		s := new Selector("search.tls").SetDefaultOverrides({"SEARCH_TERM":text})
		data := s.selectGui()
		if(!data)
			return
		
		searchTerm := data["SEARCH_TERM"]
		if(searchTerm = "")
			return
		
		subTypesAry := forceArray(data["SUBTYPE"]) ; Force it to be an array so we can always loop over it.
		For _,subType in subTypesAry { ; For searching multiple at once.
			if(data["SEARCH_TYPE"] = "WEB")
				searchWithURL(subType, searchTerm)
			else if(data["SEARCH_TYPE"] = "CODESEARCH")
				searchCodeSearch(searchTerm, subType, data["APP_KEY"])
			else if(data["SEARCH_TYPE"] = "GURU")
				searchGuru(searchTerm)
			else if(data["SEARCH_TYPE"] = "WIKI") ; Epic wiki search.
				searchEpicWiki(searchTerm, subType)
			else if(data["SEARCH_TYPE"] = "GREPWIN")
				searchWithGrepWin(searchTerm, subType)
			else if(data["SEARCH_TYPE"] = "EVERYTHING")
				searchWithEverything(searchTerm)
		}
	}

;---------
; DESCRIPTION:    Search for a term using the given base URL.
; PARAMETERS:
;  searchBaseURL (I,REQ) - The "base" URL (with %s in place of the search term) to search with.
;  searchTerm    (I,REQ) - The term to search for.
;---------
searchWithURL(searchBaseURL, searchTerm) {
	searchTerm := escapeForRunURL(searchTerm)
	url := searchBaseURL.replace("%s", searchTerm)
	Run(url)
}

;---------
; DESCRIPTION:    Search for the given term/type/app with CodeSearch.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;  searchType (I,REQ) - Type of search, from: Server, Client, Records, ProgPoint
;  appKey     (I,OPT) - App key (goes on the end of CS_APP_ID_ for a private value) to search only
;                       within that app's code. Defaults to all apps (no filter).
;---------
searchCodeSearch(searchTerm, searchType, appKey := "") {
	if(!searchType) ; Gotta know w here to search.
		return ""
	
	searchTerm := escapeForRunURL(searchTerm)
	
	url := Config.private["CS_BASE"]
	url := url.replaceTag("SEARCH_TYPE", searchType)
	url := url.replaceTag("APP_ID",      getEpicAppIdFromKey(appKey))
	url := url.replaceTag("CRITERIA",    "a=" searchTerm)
	
	Run(url)
}

;---------
; DESCRIPTION:    Turn the given app key into its numeric ID for CodeSearch.
; PARAMETERS:
;  appKey (I,REQ) - App key (goes on the end of CS_APP_ID_ for a private value).
; RETURNS:        The numeric ID for the given app, 0 if no match (including blank appKey).
;---------
getEpicAppIdFromKey(appKey) {
	if(appKey = "")
		return 0
	return Config.private["CS_APP_ID_" appKey]
}

;---------
; DESCRIPTION:    Search Guru for the given text.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;---------
searchGuru(searchTerm) {
	searchTerm := escapeForRunURL(searchTerm)
	url := Config.private["GURU_SEARCH_BASE"] searchTerm
	Run(url)
}

;---------
; DESCRIPTION:    Search the Epic wiki for the given term.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;  category   (I,OPT) - Category to restrict search results to within the wiki.
;---------
searchEpicWiki(searchTerm, category := "") {
	searchTerm := escapeForRunURL(searchTerm)
	
	url := Config.private["WIKI_SEARCH_BASE"]
	url := url.replaceTag("QUERY", searchTerm)
	
	if(category) {
		filters := Config.private["WIKI_SEARCH_FILTERS"]
		filters := filters.replaceTag("CATEGORIES", "'" category "'")
		url .= filters
	}
	
	Run(url)
}

;---------
; DESCRIPTION:    Run a search with grepWin in the given path.
; PARAMETERS:
;  searchTerm   (I,REQ) - Text to search for.
;  pathToSearch (I,REQ) - Where to search files for the given term.
;---------
searchWithGrepWin(searchTerm, pathToSearch) {
	QUOTE := """" ; Double-quote character
	
	pathToSearch := Config.replacePathTags(pathToSearch) ; Escape any quotes in the search string
	searchTerm := StringLib.escapeCharUsingChar(searchTerm, QUOTE)
	
	args := "/regex:no"
	args .= " /searchpath:" QUOTE pathToSearch " " QUOTE ; Extra space after path, otherwise trailing backslash escapes ending double quote
	args .= " /searchfor:"  QUOTE searchTerm QUOTE
	args .= " /execute" ; Run it immediately if we got what to search for
	
	; Debug.popup("Path to search",pathToSearch, "To search",searchTerm, "Args",args)
	Config.runProgram("GrepWin", args)
}

;---------
; DESCRIPTION:    Run a search with Everything.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;---------
searchWithEverything(searchTerm) {
	Config.runProgram("Everything", "-search " searchTerm)
}

;---------
; DESCRIPTION:    Escape the given string so it's safe to use when running a URL directly.
; PARAMETERS:
;  stringToEscape (I,REQ) - The string to escape.
; RETURNS:        The string, encoded and with double quotes escaped.
;---------
escapeForRunURL(stringToEscape) {
	QUOTE := """" ; Double-quote character
	
	encodedString := StringLib.encodeForURL(stringToEscape)
	encodedString := StringLib.escapeCharUsingChar(encodedString, QUOTE, QUOTE QUOTE) ; Escape double-quotes twice - extra to get us past the windows run command stripping them out.
	
	return encodedString
}

