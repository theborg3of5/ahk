; ===== Inclusion of all AHK scripts for Main. ===== ;

; Common functions, hotkeys, and other such setup.
#Include <autoInclude>

; Standalone scripts. Must be first to execute so they can spin off and be on their own.
standaloneFolder := A_ScriptDir "\standalone\"
Run, % standaloneFolder "vimBindings\vimBindings.ahk"
if(MainConfig.isMachine(MACHINE_EPIC_LAPTOP)) { ; Not needed except on Epic machine.
	Run, % standaloneFolder "killUAC.ahk"
	Run, % standaloneFolder "tortoiseFillerDLG\tortoiseFillerDLG.ahk"
	Run, % standaloneFolder "dlgNumTracker\dlgNumTracker.ahk"
} else if(MainConfig.isMachine(MACHINE_HOME_DESKTOP)) {
	Run, % standaloneFolder "psxEmulatorController\psxEmulatorController.ahk"
}

#Include setup.ahk ; Setup for this script.
#Include startup.ahk ; Setup for rest of scripts. (Variables, etc.) Includes all auto-executing code.

#Include %A_ScriptDir%\general\ ; General hotkeys.
#Include hotstrings.ahk ; Must go after startup, but before hotkeys begin.
#Include input.ahk
#Include kdeMoverSizer.ahk
#Include launch.ahk
#Include screen.ahk
#Include volume.ahk

#Include %A_ScriptDir%\program\ ; Program-specific hotkeys.
#Include chrome.ahk
#Include ciscoAnyConnect.ahk
#Include ditto.ahk
#Include emc2.ahk
#Include epicStudio.ahk
#Include excel.ahk
#Include explorer.ahk
#Include fastStoneImageViewer.ahk
#Include foobar.ahk
#Include hyperspace.ahk
#Include kdiff.ahk
#Include launchy.ahk
#Include league.ahk
#Include notepad++.ahk
#Include onenote.ahk
#Include outlook.ahk
#Include oxygenXML.ahk
#Include pidgin.ahk
#Include powerpoint.ahk
#Include putty.ahk
#Include quickDial.ahk
#Include remoteDesktop.ahk
#Include skype.ahk
#Include sumatraPDF.ahk
#Include tortoiseGit.ahk
#Include tortoiseSVN.ahk
#Include vb6.ahk
#Include vlc.ahk
#Include word.ahk
#Include yEd.ahk

; Universal suspend, reload, and exit hotkeys.
#Include %A_ScriptDir%\common\commonHotkeys.ahk
