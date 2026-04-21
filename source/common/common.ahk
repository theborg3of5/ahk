;region Basic settings for all scripts
#SingleInstance
A_WorkingDir := A_ScriptDir
;endregion Basic settings for all scripts

;region Prototype extensions (self-installing)
#Include %A_LineFile%\..\base
#Include stringBase.ahk
#Include arrayBase.ahk
#Include objectBase.ahk
;endregion Prototype extensions

;region Includes
#Include %A_LineFile%\..\class
	#Include actionObject.ahk
	#Include duration.ahk
	#Include epicRecord.ahk
	#Include flexTable.ahk
	#Include formattedList.ahk
	#Include mousePosition.ahk
	#Include program.ahk
	#Include progressToast.ahk
	#Include relativeDate.ahk
	#Include relativeTime.ahk
	#Include selector.ahk
	#Include tableList.ahk
	#Include tempSettings.ahk
	#Include textPopup.ahk
	#Include textTable.ahk
	#Include toast.ahk
	#Include visualWindow.ahk
	#Include windowInfo.ahk

#Include %A_LineFile%\..\lib
	#Include ahkCodeLib.ahk
	#Include clipboardLib.ahk
	#Include dataLib.ahk
	#Include dateTimeLib.ahk
	#Include epicLib.ahk
	#Include fileLib.ahk
	#Include guiLib.ahk
	#Include hotkeyLib.ahk
	#Include microsoftLib.ahk
	#Include monitorLib.ahk
	#Include mouseLib.ahk
	#Include phoneLib.ahk
	#Include runLib.ahk
	#Include searchLib.ahk
	#Include selectLib.ahk
	#Include stringLib.ahk
	#Include windowLib.ahk

#Include %A_LineFile%\..\program
	#Include chrome.ahk
	#Include ditto.ahk
	#Include emc2.ahk
	#Include excel.ahk
	#Include explorer.ahk
	#Include mSnippets.ahk
	#Include mtPutty.ahk
	#Include notepadPlusPlus.ahk
	#Include onenote.ahk
	#Include onetastic.ahk
	#Include outlook.ahk
	#Include putty.ahk
	#Include snapper.ahk
	#Include telegram.ahk
	#Include vsCode.ahk
	#Include zoom.ahk
	
#Include %A_LineFile%\..\static
	#Include config.ahk
	#Include commonHotkeys.ahk
	#Include debug.ahk
	#Include enums.ahk
	#Include scriptTrayInfo.ahk
	#Include titleMatchMode.ahk
	#Include VA.ahk
	#Include windowActions.ahk
	#Include windowPositions.ahk
;endregion Includes

;region Initialization
Config.Init()
;endregion Initialization