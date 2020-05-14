; Hotkeys for using Zoom with a remote keyboard/mouse combo.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>
CommonHotkeys.Init(CommonHotkeys.ScriptType_Standalone)

global isGalleryView := true ; Default is gallery view, at least in the meetings I frequent

#IfWinActive, ahk_exe Zoom.exe ahk_class ZPContentViewWndClass
	; Specific views, directly
	F1::
		Send, !{F1}
		isGalleryView := false
	return
	F2::
		Send, !{F2}
		isGalleryView := true
	return

	; Easier toggles with extra buttons
	Launch_Media::toggleView()
	Browser_Home::!a ; Toggle mute
#IfWinActive

toggleView() {
	global isGalleryView
	isGalleryView := !isGalleryView
	
	if(isGalleryView)
		Send, !F1
	else
		Send, !F2
}
