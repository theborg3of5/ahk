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
	!F1::
	#d::          ; Desktop (F1 on remote keyboard)
		switchToSpeakerView()
	return
	!F2::
	#^Backspace:: ; Task view (F2 on remote keyboard)
		switchToGalleryView()
	return
	
	; Easier toggles using extra buttons
	Launch_Media::!a ; Toggle mute
	Browser_Home::toggleView()
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
