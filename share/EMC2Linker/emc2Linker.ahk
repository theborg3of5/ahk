/*
Author: Gavin Borg

Description: Allows semi-universal opening of a variety of different objects via selected text.

Installation:
	Copy the containing folder (UniversalLinker) to your local machine and run this script.
	If you would like it to persist through reboots, add a shortcut to your local copy of this script to your startup folder.

Shortcuts:
	Ctrl+Alt+Win+O:
		Open the selected string as whatever we can, or ask the user with a popup if we can't tell.
		Examples:
			If you select "DLG 123456" and press this, that DLG will open in EMC2 in edit mode.
			If you select "123456" and press this, you'll get a popup asking you what sort of object this is, and it will open in EMC2 once you answer.
		
	Ctrl+Alt+Win+Shift+O:
		Same as Ctrl+Alt+Win+O, but we open the object as a web page wherever possible rather than in edit mode.
		
	Ctrl+Shift+Alt+L:
		Copy a link to the object that the selected text points to, or ask the user with a popup if we can't tell what kind it is.
		Examples:
			If you select "DLG 123456" and press this, you'll get a link to open that DLG in EMC2 in edit mode on the clipboard.
			If you select "123456" and press this, you'll get a popup asking you what sort of object this is, and will get the link once you answer.
	
	Ctrl+Alt+Win+Shift+L:
		Same as Ctrl+Alt+Win+L, but we copy a link to the object as a web page wherever possible rather than in edit mode.
		
Notes:
	You can select and take action on the following:
		EMC2 Objects
			We need 2 major pieces of info here: the INI (DLG, QAN, XDS, etc) and the ID (DLG num, etc).
			You can select either of those two pieces, or both together, separated by a space. ("DLG", "123456", and "DLG 123456" are all fine.)
			If you select both pieces, the object will be opened.
			If you select only one, you will see a popup that asks what sort of thing you're trying to act on.
		EPICSTUDIO tags/routines
			Select tag^routine or just routine.
		Filepaths/URLs:
			Select the whole thing.
*/


; --------------------------------------------------
; - Configuration ----------------------------------
; --------------------------------------------------
{
	; Icon to show in the system tray for this script.
	iconPath := "emc2link.ico" ; Comment out to use the default AHK icon.
	; #NoTrayIcon  ; Uncomment to hide the tray icon instead.
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
		
		; For ActionObject use
		#Include actionObject.ahk
		#Include epic.ahk
		#Include runCommands.ahk
		#Include window.ahk
	
	; Constants
	global TEXT_SOURCE_PASSED   := "PASS"
	global TEXT_SOURCE_SEL_CLIP := "SELECTION/CLIPBOARD"
	global TEXT_SOURCE_TITLE    := "TITLE"
	global pLaunchPath_EMC2 := "C:\Program Files (x86)\Epic\v8.1\EMC2\Shared Files\EpicD81.exe EMC2Update env=TRACKAPPTCP"
	global emc2LinkBase     := "emc2://TRACK/"
	global emc2LinkBaseWeb  := "https://emc2summary/GetSummaryReport.ashx/TRACK/"
	
	; Tray setup for double-click help popup, icon, etc.
	title       := "EMC2 Opener/Linker"
	description := "Allows semi-universal opening of a variety of different objects via selected text. `n`nTo use, select the text you want to act upon (say, 'DLG 302309') and press one of these hotkeys. If it doesn't recognize what you're trying to do, the script will ask you."
	hotkeys     := []
	hotkeys.Push(["Open in edit mode",      "Ctrl + Alt + Win + O"])
	hotkeys.Push(["Open in web mode",       "Ctrl + Alt + Shift + Win + O"])
	hotkeys.Push(["Copy link to edit mode", "Ctrl + Alt + Win + L"])
	hotkeys.Push(["Copy link to web mode",  "Ctrl + Alt + Shift + Win + L"])
	hotkeys.Push(["Emergency exit",         "Ctrl + Shift + Alt + Win + R"])
	
	setupTray(title, description, hotkeys, iconPath)
	scriptLoaded := true
}


; --------------------------------------------------
; - Main -------------------------------------------
; --------------------------------------------------
{
	; Generic opener - opens a variety of different things based on the selected/clipboard text.
	^!#o::
		KeyWait, Ctrl
		KeyWait, LWin
		KeyWait, Alt
		text := getSelectedText()
		ActionObject.do(text)
	return
	; Open web version
	^!#+o::
		text := getSelectedText()
		ActionObject.do(text, , , , SUBACTION_WEB)
	return

	; Generic linker - will allow coming from clipboard or selected text, or input entirely. Puts the link on the clipboard.
	^!#l::
		text := getSelectedText()
		link := ActionObject.do(text, , ACTION_LINK)
		if(link)
			clipboard := link
	return
	; Get link to web version
	^!#+l::
		text := getSelectedText()
		link := ActionObject.do(text, , ACTION_LINK, , SUBACTION_WEB)
		if(link)
			clipboard := link
	return
}


; --------------------------------------------------
; - Supporting functions ---------------------------
; --------------------------------------------------
{
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
