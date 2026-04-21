; Change the volume by a specific amount and show a toast with the new volume.
; Applies to the local machine even if remote desktop is fullscreen.

#Include <includeCommon>
#SingleInstance Off ; Allow multiple instances of this script, so I can quickly turn the volume up/down multiple steps.
#NoTrayIcon

changeAmount := A_Args.Has(1) ? A_Args[1] : "" ; Input from command line - handles both numbers and numbers with a +/- at the start.
changeAmount := DataLib.forceNumber(changeAmount)
if(changeAmount = 0)
	ExitApp

SoundSetVolume(changeAmount)

currentLevel := Round(SoundGetVolume(), 0)

styles := Map()
styles["BACKGROUND_COLOR"] := "000000" ; Black
styles["FONT_COLOR"]       := "CCCCCC" ; Light gray
styles["FONT_SIZE"]        := 20
styles["FONT_NAME"]        := "Segoe UI"
styles["MARGIN_X"]         := 40
styles["MARGIN_Y"]         := 20

t := Toast("Volume: " currentLevel "%", styles).blockingOn()
t.showForSeconds(1, VisualWindow.X_LeftEdge "+50", VisualWindow.Y_TopEdge "+30")

ExitApp
