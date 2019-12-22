#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

#Include autoCompleteClass.ahk
#Include autoCompleteMember.ahk

; Constants we use to pick apart scripts for their component parts.
global Header_StartEnd            := ";---------"
global ScopeStart_Public          := "; #PUBLIC#"
global ScopeStart_NonPublicScopes := ["; #INTERNAL#", "; #PRIVATE#", "; #DEBUG#"]
global ScopeEnd                   := "; #END#"

; [[File paths]] --=
path_CompletionTemplate_AHK := Config.path["AHK_TEMPLATE"] "\notepadPP_AutoComplete_AHK.xml"
path_CompletionTemplate_TL  := Config.path["AHK_TEMPLATE"] "\notepadPP_AutoComplete_TL.xml"
path_CompletionOutput_AHK   := Config.path["AHK_OUTPUT"]   "\notepadPP_AutoComplete_AHK.xml"
path_CompletionOutput_TL    := Config.path["AHK_OUTPUT"]   "\notepadPP_AutoComplete_TL.xml"

path_SyntaxTemplate_AHK := Config.path["AHK_TEMPLATE"] "\notepadPP_SyntaxHighlighting_AHK.xml"
path_SyntaxTemplate_TL  := Config.path["AHK_TEMPLATE"] "\notepadPP_SyntaxHighlighting_TL.xml"
path_SyntaxOutput_AHK   := Config.path["AHK_OUTPUT"]   "\notepadPP_SyntaxHighlighting_AHK.xml"
path_SyntaxOutput_TL    := Config.path["AHK_OUTPUT"]   "\notepadPP_SyntaxHighlighting_TL.xml"

path_SyntaxTemplate_Base  := Config.path["AHK_TEMPLATE"]  "\notepadPP_SyntaxHighlighting_Base.xml" ; Base XML in case the file doesn't exist yet
path_CompletionActive_AHK := Config.path["PROGRAM_FILES"] "\Notepad++\autoCompletion\AutoHotkey.xml"
path_CompletionActive_TL  := Config.path["PROGRAM_FILES"] "\Notepad++\autoCompletion\TableList.xml"
path_SyntaxActive         := Config.path["USER_APPDATA"]  "\Notepad++\userDefineLang.xml" ; This file is for all user-defined languages


; GDB TODO next plans:
;  - Add NPP-RETURNS and NPP-LANG to list of header keywords for indentation and such

global ahkClasses := {} ; {className: AutoCompleteClass}
global tlMembers := {} ; {memberName: AutoCompleteMember}

; [[ Extract data from scripts ]] ---

; Read in and extract all classes from scripts in these folders
addFromFolder(Config.path["AHK_SOURCE"] "\common\base",   "BASE_CLASSES")
addFromFolder(Config.path["AHK_SOURCE"] "\common\class",  "INSTANCE_CLASSES")
addFromFolder(Config.path["AHK_SOURCE"] "\common\lib",    "LIB_CLASSES")
addFromFolder(Config.path["AHK_SOURCE"] "\common\static", "STATIC_CLASSES")
addFromFolder(Config.path["AHK_SOURCE"] "\program",       "PROGRAM_CLASSES", "[Requires program includes]") ; Include program-specific classes, but with a returns prefix.

; Remove empty classes and handle inheritance.
classesToDelete := []
For className,classObj in ahkClasses {
	; Mark any classes with no members for deletion
	if(classObj.members.count() = 0)
		classesToDelete.push(className)
	
	; Handle inheritance: add any parent members (only 1 layer deep) into this class
	if(classObj.parentName != "") {
		For _,member in ahkClasses[classObj.parentName].members
			classObj.addMemberIfNew(member)
	}
}
For _,className in classesToDelete
	ahkClasses.Delete(className)

sortedAHKClasses := getSortedKeywordAry(ahkClasses)
sortedTLMembers := getSortedKeywordAry(tlMembers)


; [[ Auto-complete ]] ---
xmlLines := FileLib.fileLinesToArray(path_CompletionTemplate_AHK)
updateAutoCompleteXML(xmlLines, ahkClasses)
newXML := xmlLines.join("`n")
FileLib.replaceFileWithString(path_CompletionOutput_AHK, newXML)
; FileLib.replaceFileWithString(path_CompletionActive_AHK, newXML)


keywordsXML := ""
For _,member in sortedTLMembers
	keywordsXML := keywordsXML.appendPiece(member.generateXML(), "`n")

templateXML := FileRead(path_CompletionTemplate_TL)
newXML := replaceMarker(templateXML, "KEYWORDS", keywordsXML)

FileLib.replaceFileWithString(path_CompletionOutput_TL, newXML)
; FileLib.replaceFileWithString(path_CompletionActive_TL, newXML)

t := new Toast("Updated both versions of the auto-complete file").show()



; [[ Syntax highlighting ]] ---
; AHK: we can get the class groups we need from the auto complete classes we built above
xmlSyntaxAHK := FileRead(path_SyntaxTemplate_AHK)
updateAHKSyntaxXML(xmlSyntaxAHK, ahkClasses)
FileLib.replaceFileWithString(path_SyntaxOutput_AHK, xmlSyntaxAHK)

; TL: the template file already has exactly what we want to plug in, no processing needed.
xmlSyntaxTL := FileRead(path_SyntaxTemplate_TL)
updateTLSyntaxXML(xmlSyntaxTL, sortedTLMembers)
FileLib.replaceFileWithString(path_SyntaxOutput_TL, xmlSyntaxTL)

; Get the combined XML to update - from either an existing file or the base template.
if(FileExist(path_SyntaxActive))
	activeSyntaxXML := FileRead(path_SyntaxActive)
else
	activeSyntaxXML := FileRead(path_SyntaxTemplate_Base)

; Plug each language into its spot in the XML
updateLangInSyntaxXML(activeSyntaxXML, "AutoHotkey", xmlSyntaxAHK)
updateLangInSyntaxXML(activeSyntaxXML, "TableList",  xmlSyntaxTL)
; FileLib.replaceFileWithString(path_SyntaxActive, activeSyntaxXML)


t.setText("Updated syntax highlighting file for Notepad++ (requires restart)").blockingOn().showMedium()
; =--

ExitApp


;---------
; DESCRIPTION:    Get an array of classes that we care about for auto-completion purposes.
; RETURNS:        An array of AutoCompleteClass instances, in auto-complete sorted order.
;---------
getAutoCompleteClasses() {
	classes := {}
	
	; Read in and extract all classes from scripts in these folders
	; addFromFolder(classes, Config.path["AHK_SOURCE"] "\common\base",   "BASE_CLASSES")
	; addFromFolder(classes, Config.path["AHK_SOURCE"] "\common\class",  "INSTANCE_CLASSES")
	; addFromFolder(classes, Config.path["AHK_SOURCE"] "\common\lib",    "LIB_CLASSES")
	; addFromFolder(classes, Config.path["AHK_SOURCE"] "\common\static", "STATIC_CLASSES")
	; addFromFolder(classes, Config.path["AHK_SOURCE"] "\program",       "PROGRAM_CLASSES", "[Requires program includes]") ; Include program-specific classes, but with a returns prefix.
	
	; Remove empty classes and handle inheritance.
	classesToDelete := []
	For className,classObj in classes {
		; Mark any classes with no members for deletion
		if(classObj.members.count() = 0)
			classesToDelete.push(className)
		
		; Handle inheritance: add any parent members (only 1 layer deep) into this class
		if(classObj.parentName != "") {
			For _,member in classes[classObj.parentName].members
				classObj.addMemberIfNew(member)
		}
	}
	For _,className in classesToDelete
		classes.Delete(className)
	
	; Sort properly (underscores sort last)
	return getAutoCompleteSortedClasses(classes)
}

;---------
; DESCRIPTION:    Add documentation data from the scripts in the given folder to the classes object.
; PARAMETERS:
;  folderPath    (I,REQ) - The full path to the folder to read from.
;  classGroup    (I,REQ) - Which "group" the classes in this folder should have - this determines
;                          how they get syntax-highlighted.
;  returnsPrefix (I,OPT) - The prefix to add to the auto-complete return value of all functions in
;                          all classes in this folder.
;---------
addFromFolder(folderPath, classGroup, returnsPrefix := "") {
	; Loop over all scripts in folder to find classes
	Loop, Files, %folderPath%\*.ahk, RF ; [R]ecursive, [F]iles (not [D]irectories)
	{
		linesAry := FileLib.fileLinesToArray(A_LoopFileLongPath, true)
		
		tlBlockOn := false
		ln := 0 ; Lines start at 1 (and the loop starts by increasing the index).
		while(ln < linesAry.count()) {
			line := linesAry.next(ln)
			
			; There are blocks of headers with no corresponding definition lines, specific to the TableList file format.
			if(line = "; @NPP-TABLELIST")
				tlBlockOn := true
			if(line = "; @NPP-TABLELIST-END")
				tlBlockOn := false
			
			; Block of documentation - read the whole thing in and create a member.
			if(line = Header_StartEnd) {
				; Grab the whole header
				headerLines := [line]
				Loop {
					line := linesAry.next(ln)
					headerLines.push(line)
					
					if(line = Header_StartEnd)
						Break
				}
				
				if(tlBlockOn) {
					; Feed the header to a new member object and add it to the TL members array.
					member := new AutoCompleteMember(headerLines) ; No defLine/returnsPrefix - these headers specify their own.
					tlMembers[member.name] := member
				} else {
					; Get the definition line (first line after the header) too.
					defLine := linesAry.next(ln)
					
					; Feed the data to a new member object and add that to our current class object.
					member := new AutoCompleteMember(headerLines, defLine, returnsPrefix)
					classObj.addMember(member)
				}
				
				Continue
			}
			
			; Block of private/debug scope - ignore everything up until we hit a public/end of scope.
			if(ScopeStart_NonPublicScopes.contains(line)) {
				while(line != ScopeStart_Public && line != ScopeEnd) {
					line := linesAry.next(ln)
				}
				
				Continue
			}
			
			; Class declaration
			if(line.startsWith("class ") && line.endsWith(" {") && line != "class {") {
				classObj := new AutoCompleteClass(line, classGroup)
				ahkClasses[classObj.name] := classObj ; Point to classObj (which is what we'll actually be updating) from classes object
				
				Continue
			}
		}
	}
}

;---------
; DESCRIPTION:    Convert the className-indexed associative array into a normal array, sorted in
;                 auto-complete order.
; PARAMETERS:
;  functionsByClassName (I,REQ) - The associative array of AutoCompleteClass instances. Format:
;                                  functionsByClassName[className] := autoCompleteClassInstance
; RETURNS:        A numeric array, sorted in auto-complete order
; NOTES:          Auto-complete order is case-insensitive alphabetical order, but where underscore
;                 sorts after everything else.
;---------
getAutoCompleteSortedClasses(functionsByClassName) {
	classes := []
	
	; Get the names and sort them
	classNames := functionsByClassName.toKeysArray().join("`n")
	Sort, classNames, F keywordSortsAfter
	
	; Populate new array in correct order
	For _,className in classNames.split("`n")
		classes.push(functionsByClassName[className])
	
	return classes
}

;---------
; DESCRIPTION:    Update the given array of XML lines using the given array of class information.
; PARAMETERS:
;  xmlLines (IO,REQ) - An array of XML lines to update.
;  classes   (I,REQ) - A numeric array of AutoCompleteClass instances. Must be in auto-complete order.
;---------
updateAutoCompleteXML(ByRef xmlLines, classes) {
	; Loop through our sorted classes, inserting their XML in the right place as we go.
	commentOn := false
	ln := 0 ; Lines start at 1 (and the loop starts by increasing the index).
	For _,classObj in classes { ; Sorted class objects
		while(ln < xmlLines.count()) { ; Loop over lines of XML
			line := xmlLines.next(ln).withoutWhitespace()
			
			; Ignore comment blocks
			if(line.startsWith("<!--")) {
				commentOn := true
			}
			if(line.endsWith("-->")) {
				commentOn := false
				Continue
			}
			if(commentOn)
				Continue
			
			; Ignore anything that's not a keyword line
			if(!line.startsWith("<KeyWord name="""))
				Continue
			
			; If the class name sorts after the current keyword, we haven't gone far enough yet.
			keywordName := line.firstBetweenStrings("<KeyWord name=""", """")
			if(keywordSortsAfter(classObj.name, keywordName) > 0)
				Continue
			
			; We've found the right spot - insert our XML.
			classXML := classObj.generateXML()
			xmlLines.InsertAt(ln, classXML) ; This technically puts a bunch of lines of text into one "line", but we're never going to insert something in the middle of the class, so that should be fine.
			ln-- ; Take a step backwards so we check the same line we just checked (which is just after the class XML we just inserted) against the next class.
			Break ; Move onto the next class.
		}
	} ; This will technically fail to add anything that sorts to the very end, but I don't think I'm ever going to create a new class that starts with __ so we should be fine.
}

; GDB TODO
getSortedKeywordAry(toSort) {
	sortedAry := []
	
	namesList := toSort.toKeysArray().join("`n")
	Sort, namesList, F keywordSortsAfter
	
	; Populate new array in sorted order
	For _,name in namesList.split("`n")
		sortedAry.push(toSort[name])
	
	return sortedAry
}

;---------
; DESCRIPTION:    Comparison function for sorting in auto-complete order.
; PARAMETERS:
;  word1 (I,REQ) - The first word to compare
;  word2 (I,REQ) - The second word to compare
; RETURNS:        1 - word1 > word2
;                 0 - word1 = word2
;                -1 - word1 < word2
; NOTES:          Auto-complete order is case-insensitive alphabetical order, but with underscores
;                 sorting after everything else.
;---------
keywordSortsAfter(word1, word2) {
	Loop, Parse, word1
	{
		c1 := A_LoopField
		c2 := word2.charAt(A_Index)
		
		; Same character - keep going
		if(c1 = c2)
			Continue
		
		; Shorter name goes first
		if(c2 = "")
			return 1
		
		; Underscore should sort after everything else
		if(c1 = "_")
			return 1
		if(c2 = "_")
			return -1
		
		; Otherwise we can use normal character comparison
		if(c1 < c2)
			return -1
		if(c1 > c2)
			return 1
	}
	
	; If word1 is shorter, it should come first.
	if(word2.length() > word1.length())
		return -1
	
	return 0
}

;---------
; DESCRIPTION:    Update the given AHK syntax highlighting XML with groups of space-separated class names.
; PARAMETERS:
;  syntaxXML  (IO,REQ) - The XML to update.
;  ahkClasses  (I,REQ) - The array of AutoCompleteClass instances from getAutoCompleteClasses(). ; GDB TODO
;---------
updateAHKSyntaxXML(ByRef syntaxXML, ahkClasses) {
	; Generate the class groups we need from our auto-complete classes
	classGroups := {}
	For _,classObj in ahkClasses {
		names := classGroups[classObj.group]
		names := names.appendPiece(classObj.name, " ")
		classGroups[classObj.group] := names
	}
	
	; Update all replacement markers with the groups
	For groupName,classNames in classGroups
		syntaxXML := replaceMarker(syntaxXML, groupName, classNames)
}


updateTLSyntaxXML(ByRef syntaxXML, tlMembers) {
	; Generate the groups
	memberGroups := {}
	For _,member in tlMembers {
		if(member.returns = "@") {
			group := "SETTINGS"
			name := "@" member.name
		} else {
			group := "MOD_OPERATIONS"
			name := member.name
		}
		
		names := memberGroups[group]
		names := names.appendPiece(name, " ")
		memberGroups[group] := names
	}
	
	; Update replacement markers
	For groupName,memberNames in memberGroups
		syntaxXML := replaceMarker(syntaxXML, groupName, memberNames)
}

;---------
; DESCRIPTION:    Update the given XML with the given language-specific XML.
; PARAMETERS:
;  activeSyntaxXML (IO,REQ) - XML to update with the language.
;  langName         (I,REQ) - The name of the language, should be the name from the <UserLang> tag that we'll replace.
;  langFullXML      (I,REQ) - The full, importable XML for the lanaguage (including the <NotepadPlusPlus> tag)
;---------
updateLangInSyntaxXML(ByRef activeSyntaxXML, langName, langFullXML) {
	; We only need the chunk of XML specific to the language (including the rest of the opening <UserLang> tag, which has file extensions and such)
	langXML := langFullXML.allBetweenStrings("<UserLang name=""" langName """", "</UserLang>")
	
	; Replace the same thing in the active XML.
	xmlToReplace := activeSyntaxXML.firstBetweenStrings("<UserLang name=""" langName """", "</UserLang>")
	activeSyntaxXML := activeSyntaxXML.replace(xmlToReplace, langXML)
}
	
;---------
; DESCRIPTION:    Replace an XML-safe marker ("{{markerName}}") in the given XML string with the
;                 provided replacement.
; PARAMETERS:
;  markerName  (I,REQ) - The name of the tag to replace (no angle brackets)
;  replacement (I,REQ) - The text to replace all instances of the tag with.
; RETURNS:        The updated string.
;---------
replaceMarker(baseString, markerName, replacement) {
	return baseString.replace("{{" markerName "}}", replacement)
}
