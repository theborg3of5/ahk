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
	F1::switchToSpeakerView()
	F2::switchToGalleryView()
	
	; Remote keyboard has these extra bindings (via rebound keys):
	; Music - Alt+A (toggle mute)
	!F3::toggleView() ; Lock - Alt+F3
	; Power - Alt+V (toggle video)
#IfWinActive

switchToSpeakerView() {
	global isGalleryView
	
	Send, !{F1}
	isGalleryView := false
}
switchToGalleryView() {
	global isGalleryView
	
	Send, !{F2}
	isGalleryView := true
}

toggleView() {
	global isGalleryView
	
	if(isGalleryView)
		switchToSpeakerView()
	else
		switchToGalleryView()
}
