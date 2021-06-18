; Various Epic utility functions.

class EpicLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Run Hyperspace locally for the given version and environment.
	; PARAMETERS:
	;  versionMajor (I,REQ) - Major version (before the dot in dotted version)
	;  versionMinor (I,REQ) - Minor version (last digit, after the dot in dotted version)
	;  environment  (I,OPT) - EpicComm ID for the environment to connect to.
	;---------
	runHyperspace(versionMajor, versionMinor, environment) {
		Run(Config.private["HYPERSPACE_BASE"].replaceTags({"MAJOR":versionMajor, "MINOR":versionMinor, "ENVIRONMENT":environment}))
	}
	
	;---------
	; DESCRIPTION:    Open a VDI matching the given ID.
	; PARAMETERS:
	;  vdiId (I,REQ) - The ID of the VDI to open.
	;---------
	runVDI(vdiId) {
		Run(Config.private["VDI_BASE"].replaceTag("VDI_ID", vdiId))
	}
	
	;---------
	; DESCRIPTION:    Split the given server location into tag and routine.
	; PARAMETERS:
	;  serverLocation (I,REQ) - The location in server code to split.
	;  routine        (O,OPT) - The routine
	;  tag            (O,OPT) - The tag. May include offset, see notes below.
	; NOTES:          Any offset from a tag will be included in the tag return value (i.e.
	;                 TAG+3^ROUTINE splits into routine=ROUTINE and tag=TAG+3).
	;---------
	splitServerLocation(serverLocation, ByRef routine := "", ByRef tag := "") {
		serverLocation := serverLocation.clean(["$", "(", ")"])
		locationAry := serverLocation.split("^")
		
		maxIndex := locationAry.MaxIndex()
		if(maxIndex > 1)
			tag := locationAry[1]
		routine := locationAry[maxIndex] ; Always the last piece (works whether there was a tag before it or not)
	}
	
	;---------
	; DESCRIPTION:    Drop the offset ("+4" in "tag+4^routine", can also be negative) from the
	;                 given server (so we'd return "tag^routine").
	; PARAMETERS:
	;  serverLocation (I,REQ) - The server location to drop the offset from.
	; RETURNS:        The updated server code location.
	;---------
	dropOffsetFromServerLocation(serverLocation) {
		EpicLib.splitServerLocation(serverLocation, routine, tag)
		tag := tag.beforeString("+").beforeString("-")
		return tag "^" routine
	}
	
	;---------
	; DESCRIPTION:    Given a file path, convert it to a "source-relative" path - that is, the relative path between the
	;                 source root folder (DLG-* or App *) and the given location.
	; PARAMETERS:
	;  path (I,REQ) - The path to convert.
	; RETURNS:        Relative path with leading backslash.
	;---------
	convertToSourceRelativePath(path) {
		path := FileLib.cleanupPath(path)
		
		sourceRoot := Config.private["EPIC_SOURCE"] "\"
		if(!path.startsWith(sourceRoot)) {
			ClipboardLib.setAndToastError(path, "path", "Could not copy source-relative path", "Path is not in source root")
			return ""
		}
		path := path.removeFromStart(sourceRoot)
		
		; Strip off one more parent - it's either one of the main folders (App *) or a DLG folder (DLG-*)
		path := "\" path.afterString("\") ; Keep the leading backslash
		
		return path
	}
	; #END#
}


