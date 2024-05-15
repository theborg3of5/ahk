; Functions for running various searches.

class SearchLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Run a generic search with the selected text, prompting the user for what kind
	;                 of search it should be.
	;---------
	selectedTextPrompt() {
		text := SelectLib.getCleanFirstLine()
		
		s := new Selector("search.tls").setDefaultOverrides({"SEARCH_TERM":text})
		destinations := s.promptMulti() ; Each element is a search destination, but the search term is on each of them.
		For _, dest in destinations {
			searchTerm := dest["SEARCH_TERM"]
			if(searchTerm = "")
				return
			
			subTypesAry := DataLib.forceArray(dest["SUBTYPE"]) ; Force it to be an array so we can always loop over it.
			For _,subType in subTypesAry { ; For searching multiple at once.
				Switch dest["SEARCH_TYPE"] {
					Case "WEB":        SearchLib.urlBase(subType, searchTerm)
					Case "CODESEARCH": Run(SearchLib.buildCodeSearchURL(subType, searchTerm, dest["TYPE_FILTER"], dest["APP_KEY"]))
					Case "GURU":       SearchLib.guru(searchTerm)
					Case "HUBBLE":     SearchLib.hubble(searchTerm, subType, dest["APP_KEY"])
					Case "WIKI":       SearchLib.epicWiki(searchTerm, subType) ; Epic wiki search.
					Case "GREPWIN":    SearchLib.grepWin(searchTerm, subType)
					Case "EVERYTHING": SearchLib.everything(searchTerm)
				}
			}
		}
	}
	
	;---------
	; DESCRIPTION:    Search for a term using the given base URL.
	; PARAMETERS:
	;  searchBaseURL (I,REQ) - The "base" URL (with <QUERY> in place of the search term) to search with.
	;  searchTerm    (I,REQ) - The term to search for.
	;---------
	urlBase(searchBaseURL, searchTerm) {
		searchTerm := SearchLib.escapeTermForRunURL(searchTerm)
		url := searchBaseURL.replaceTag("QUERY", searchTerm)
		Run(url)
	}

	;---------
	; DESCRIPTION:    Build a CodeSearch URL for the given term, type, app, etc.
	; PARAMETERS:
	;  searchType          (I,REQ) - Type of search (routine/client/records/other)
	;  searchTerm          (I,OPT) - Text to search for.
	;  clientSearchSubType (I,OPT) - If the type of search is client, the subtype (number that filters to only scripts, only C#, etc.)
	;  appKey              (I,OPT) - App key (goes on the end of CS_APP_ID_ for a private value) to search only
	;                                within that app's code. Defaults to all apps (no filter).
	;  action              (I,OPT) - If you're doing something other than searching, enter the action (param=x) here.
	;                                Defaults to "search=1" for running searches.
	;  nameFilter          (I,OPT) - File name to filter by (will be searched as "contains").
	;---------
	buildCodeSearchURL(searchType, searchTerm, clientSearchSubType := "", appKey := "", action := "", nameFilter := "") {
		if(!searchType) ; Gotta know how to search.
			return ""
		
		if(action = "")
			action := "search=1"
		
		params := ""
		if(searchTerm != "")
			params .= "&a=" SearchLib.escapeTermForRunURL(searchTerm) ; Actual query
		if(clientSearchSubType != "")
			params .= "&showall=" clientSearchSubType ; Subtype of files to filter to for client searches
		if(appKey = "DBC")
			params .= "&apps=" Config.private["DBC_APP_ID"] ; Apps to limit ownership to
		if(nameFilter != "")
			params .= "&namefilter=2&namefiltertext=" nameFilter ; Name filter (when searching by filename)
		
		url := Config.private["CS_BASE"]
		url := url.replaceTag("ACTION",       action)
		url := url.replaceTag("SEARCH_TYPE",  searchType)
		url := url.replaceTag("OTHER_PARAMS", params)
		
		return url
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
	; DESCRIPTION:    Search Hubble for the given text.
	; PARAMETERS:
	;  searchTerm (I,REQ) - Text to search for
	;  searchType (I,REQ) - Type of search (basically the tab)
	;  appKey     (I,OPT) - The app to restrict the search to
	; SIDE EFFECTS:   Will also add additional filters depending on the tab
	;---------
	hubble(searchTerm, searchType, appKey := "") {
		searchTerm := SearchLib.escapeTermForRunURL(searchTerm)
		
		url := Config.private["HUBBLE_SEARCH_BASE"]
		url := url.replaceTag("QUERY", searchTerm)
		
		if(searchType = "QAN") {
			url := url.replaceTag("SEARCH_TYPE", "zqn")
			
			filters := Config.private["HUBBLE_QAN_ACTIVE_FILTER"]
			if(appKey = "DBC")
				filters := filters.appendPiece(",", "'PrimaryApplicationID':!*('" Config.private["DBC_APP_ID"] "')*!")
			url := url.replaceTag("FILTERS", filters)
		}
		
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
		args .= " /searchfor:"  QUOTE searchTerm       QUOTE
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
	
	
	; #PRIVATE#
	
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
	; #END#
}
