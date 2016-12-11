; Launch various programs, URLs, etc.

; General programs.
#f::  activateProgram("Everything")
#b::  activateProgram("Foobar")
!`::  activateProgram("ProcessExplorer")
!+b::      runProgram("VMWarePlayer")
!+o:: activateProgram("OxygenXML")
!+v::      runProgram("VMWareView")
^+!g::activateProgram("Chrome")
^+!o::activateProgram("OneNote")
^+!x::activateProgram("Launchy")
^+!n::activateProgram("Notepad++")
^+!s::activateProgram("EpicStudio")
^+!u::activateProgram("Thunder")
^+!e::activateProgram("EMC2")
^!#e::activateProgram("Outlook")
^!#n::     runProgram("Notepad")
^!#/::activateProgram("WinSpy")
^!#s::activateProgram("Snapper")

!+g::
	progInfo := MainConfig.getProgram("GitHub")
	RunCommand(progInfo["PATH"])
return

#If !MainConfig.isMachine(EPIC_DESKTOP)
	!+l::activateProgram("League")
#If

#If MainConfig.isMachine(EPIC_DESKTOP)
	; VB - have to not have shift held down when it actually opens.
	^+!v::
		KeyWait, Shift
		activateProgram("VB6")
	return
	
	; Selector launchers
	#p::  Selector.select("local/phone.tl",            "CALL")
	^+!h::Selector.select("local/epicEnvironments.tl", "DO_HYPERSPACE",     , "C:\Program Files (x86)\Epic\v8.3\Shared Files\EpicD83.exe")
	^+!r::Selector.select("local/epicEnvironments.tl", "DO_THUNDER",        , "C:\Program Files (x86)\PuTTY\putty.exe")
	^+!t::Selector.select("local/outlookTLG.tl",       "OUTLOOK_TLG")

	; Themes
	^+!d::Selector.select("theme.tl", "CHANGE_THEME",  "dw")
	^+!l::Selector.select("theme.tl", "CHANGE_THEME",  "lw")
#If
	
; Resize window
#!r::Selector.select("resize.tl", "RESIZE")

; Folders
!+a::openFolder("ahkRoot")
!+m::openFolder("music")
!+x::openFolder("ahkConfig")
!+d::openFolder("downloads")

; TrueCrypt
#IfWinNotExist, ahk_class CustomDlg
	^+#o::
	^+#Delete::
		activateProgram("TrueCrypt")
	return
#IfWinExist

#If MainConfig.isMachine(EPIC_DESKTOP)
	; Launch CodeSearch.
	!+f::
		text := gatherText(TEXT_SOURCE_SEL_CLIP)
		
		data := Selector.select("search.tl", "RET_DATA", "", "", {"ARG1": text})
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
#If

; ; Take the selected number, show a popup that takes what math to do on it (i.e., +25), and put the result back in place.
; !+c::
	; text := GetSelectedText()
	; outText := mathPopup(text)
	; if(outText)
		; sendTextWithClipboard(outText)
; return

; Generic opener - opens a variety of different things based on the selected/clipboard text.
^!#o::
	KeyWait, Ctrl
	KeyWait, LWin
	KeyWait, Alt
	text := gatherText(TEXT_SOURCE_SEL_CLIP)
	ActionObject.do(text)
return
^!#+o::
	text := gatherText(TEXT_SOURCE_SEL_CLIP)
	ActionObject.do(text, , , , SUBACTION_WEB)
return

; Generic linker - will allow coming from clipboard or selected text, or input entirely. Puts the link on the clipboard.
^!#l::
	text := gatherText(TEXT_SOURCE_SEL_CLIP)
	link := ActionObject.do(text, , ACTION_LINK)
	if(link)
		clipboard := link
return
^!#+l::
	text := gatherText(TEXT_SOURCE_SEL_CLIP)
	link := ActionObject.do(text, , ACTION_LINK, , SUBACTION_WEB)
	if(link)
		clipboard := link
return

; Folder List - Open
^+!w::openFolder()

; Query this machine's folders TL file (prompt the user if nothing given) and open it.
openFolder(folderName = "") {
	global configFolder
	
	tableListSettings := []
	tableListSettings["FILTER", "COLUMN"] := "MACHINE"
	tableListSettings["FILTER", "INCLUDE", "VALUE"]  := MainConfig.getMachine()
	folderPath := Selector.select(configFolder "folders.tl", "RET", folderName, , , , tableListSettings)
	
	; Replace any special tags with real paths.
	folderPath := StrReplace(folderPath, "<AHKROOT>", SubStr(ahkRootPath, 1, -1)) ; Assuming that global path vars have a \ on the end that we don't want.
	folderPath := StrReplace(folderPath, "<USERROOT>", SubStr(userPath, 1, -1))
	
	if(folderPath && FileExist(folderPath))
		Run, % folderPath
}
