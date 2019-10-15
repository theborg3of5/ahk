; Epic-specific functions.

{ ; Run path/URL-building functions
	buildHyperspaceRunString(versionMajor, versionMinor, environment) {
		runString := Config.private["HYPERSPACE_BASE"]
		
		; Versioning and environment.
		runString := runString.replaceTags({"MAJOR":versionMajor, "MINOR":versionMinor, "ENVIRONMENT":environment})
		
		; Debug.popup("Start string", tempRun, "Finished string", runString, "Major", versionMajor, "Minor", versionMinor, "Environment", environment)
		return runString
	}
	
	buildVDIRunString(vdiId) {
		return Config.private["VDI_BASE"].replaceTag("VDI_ID", vdiId)
	}
}

; Split serverLocation into routine and tag (assume it's just the routine if no ^ included).
; Note that any offset from a tag will be included in the tag return value (i.e. TAG+3^ROUTINE splits into routine=ROUTINE and tag=TAG+3).
splitServerLocation(serverLocation, ByRef routine := "", ByRef tag := "") {
	serverLocation := serverLocation.clean(["$", "(", ")"])
	locationAry := serverLocation.split("^")
	
	maxIndex := locationAry.MaxIndex()
	if(maxIndex > 1)
		tag := locationAry[1]
	routine := locationAry[maxIndex] ; Always the last piece (works whether there was a tag before it or not)
}

; Drop the offset ("+4" in "tag+4^routine") from the given server location (so we'd return "tag^routine").
dropOffsetFromServerLocation(serverLocation) {
	splitServerLocation(serverLocation, routine, tag)
	tag := tag.beforeString("+")
	return tag "^" routine
}
