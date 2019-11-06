; Functions for running various searches.

class SearchLib {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Run a generic search with the selected text, prompting the user for what kind
	;                 of search it should be.
	;---------
	selectedTextPrompt() {
		text := SelectLib.getCleanFirstLine()
		
		s := new Selector("search.tls").SetDefaultOverrides({"SEARCH_TERM":text})
		data := s.selectGui()
		if(!data)
			return
		
		searchTerm := data["SEARCH_TERM"]
		if(searchTerm = "")
			return
		
		subTypesAry := DataLib.forceArray(data["SUBTYPE"]) ; Force it to be an array so we can always loop over it.
		For _,subType in subTypesAry { ; For searching multiple at once.
			if(data["SEARCH_TYPE"] = "WEB")
				SearchLib.baseURL(subType, searchTerm)
			else if(data["SEARCH_TYPE"] = "CODESEARCH")
				SearchLib.codeSearch(searchTerm, subType, data["APP_KEY"])
			else if(data["SEARCH_TYPE"] = "GURU")
				SearchLib.guru(searchTerm)
			else if(data["SEARCH_TYPE"] = "WIKI") ; Epic wiki search.
				SearchLib.epicWiki(searchTerm, subType)
			else if(data["SEARCH_TYPE"] = "GREPWIN")
				SearchLib.grepWin(searchTerm, subType)
			else if(data["SEARCH_TYPE"] = "EVERYTHING")
				SearchLib.everything(searchTerm)
		}
	}
	
	;---------
	; DESCRIPTION:    Search for a term using the given base URL.
	; PARAMETERS:
	;  searchBaseURL (I,REQ) - The "base" URL (with %s in place of the search term) to search with.
	;  searchTerm    (I,REQ) - The term to search for.
	;---------
	baseURL(searchBaseURL, searchTerm) {
		searchTerm := SearchLib.escapeTermForRunURL(searchTerm)
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
	codeSearch(searchTerm, searchType, appKey := "") {
		if(!searchType) ; Gotta know where to search.
			return ""
		
		searchTerm := SearchLib.escapeTermForRunURL(searchTerm)
		if(appKey = "DBC") ; Only set this whole term if we have a key.
			appCriteria := "&apps=" Config.private["CS_APP_ID_DBC"]
		
		url := Config.private["CS_BASE"]
		url := url.replaceTag("SEARCH_TYPE",  searchType)
		url := url.replaceTag("APP_CRITERIA", appCriteria)
		url := url.replaceTag("SEARCH_TERMS", "&a=" searchTerm)
		
		Run(url)
	}

	;---------
	; DESCRIPTION:    Search Guru for the given text.
	; PARAMETERS:
	;  searchTerm (I,REQ) - Text to search for.
	;---------
	guru(searchTerm) {
		searchTerm := SearchLib.escapeTermForRunURL(searchTerm)
		url := Config.private["GURU_SEARCH_BASE"] searchTerm
		Run(url)
	}

	;---------
	; DESCRIPTION:    Search the Epic wiki for the given term.
	; PARAMETERS:
	;  searchTerm (I,REQ) - Text to search for.
	;  category   (I,OPT) - Category to restrict search results to within the wiki.
	;---------
	epicWiki(searchTerm, category := "") {
		searchTerm := SearchLib.escapeTermForRunURL(searchTerm)
		
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
	grepWin(searchTerm, pathToSearch) {
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
	everything(searchTerm) {
		Config.runProgram("Everything", "-search " searchTerm)
	}
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
	;---------
	; DESCRIPTION:    Escape the given string so it's safe to use when running a URL directly.
	; PARAMETERS:
	;  stringToEscape (I,REQ) - The string to escape.
	; RETURNS:        The string, encoded and with double quotes escaped.
	;---------
	escapeTermForRunURL(stringToEscape) {
		QUOTE := """" ; Double-quote character
		
		encodedString := StringLib.encodeForURL(stringToEscape)
		encodedString := StringLib.escapeCharUsingChar(encodedString, QUOTE, QUOTE QUOTE) ; Escape double-quotes twice - extra to get us past the windows run command stripping them out.
		
		return encodedString
	}
}