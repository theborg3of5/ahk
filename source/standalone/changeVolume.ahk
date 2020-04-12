; Change the volume by a specific amount and show a toast with the new volume. Applies to the local machine even if remote desktop is fullscreen.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#NoTrayIcon

#Include <includeCommon>

#SingleInstance, Off ; Allow multiple instances of this script, so I can quickly turn the volume up/down multiple steps.
changeAmount = %1% ; Input from command line - handles both numbers and numbers with a +/- at the start.
changeAmount := DataLib.forceNumber(changeAmount)
if(changeAmount = 0)
	ExitApp

SoundSet, % changeAmount

currentLevel := Round(SoundGet(), 0)

styles := {}
styles["BACKGROUND_COLOR"] := "000000" ; Black
styles["FONT_COLOR"]       := "CCCCCC" ; Light gray
styles["FONT_SIZE"]        := 20
styles["FONT_NAME"]        := "Segoe UI"
styles["MARGIN_X"]         := 40
styles["MARGIN_Y"]         := 20

t := new Toast("Volume: " currentLevel "%", styles)
t.blockingOn()
t.showForSeconds(1, VisualWindow.X_LeftEdge "+50", VisualWindow.Y_TopEdge "+30")

ExitApp
