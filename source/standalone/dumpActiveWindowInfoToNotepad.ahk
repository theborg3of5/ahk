; Dump a bunch of info about the active window into a temporary file and open that in Notepad++.

#Include <includeCommon>

; Give the target window a chance to regain focus (it presumably lost it when we launched the script).
Sleep, 500

info := []
info.push("ID",                 WinGet("ID", "A"))
info.push("Name",               Config.findWindowInfo("A").name)
info.push("EXE",                WinGet("ProcessName", "A"))
info.push("Class",              WinGetClass("A"))
info.push("Title",              WinGetTitle("A"))
info.push("Tooltip Text",       WindowLib.getTooltipText())
info.push("Current Control ID", ControlGetFocus("A"))
info.push("VisualWindow",       new VisualWindow("A"))

Debug.tempFile(info*)

ExitApp
