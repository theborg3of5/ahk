; [[ Standard base replacement ]] --=
#Include %A_LineFile%\..\base
	#Include stringBase.ahk
	#Include arrayBase.ahk
	#Include objectBase.ahk

; Strings (technically all non-objects, since they all share a base class - see https://www.autohotkey.com/docs/Objects.htm#Pseudo_Properties )
"".base.base := StringBase ; Can't replace the base itself, but can give the base a new base instead.

; Arrays and Objects (based on https://autohotkey.com/board/topic/83081-ahk-l-customizing-object-and-array/ )
; Redefine Array() to use our new ArrayBase base class
Array(params*) {
	; Since params is already an array of the parameters, just give it a
	; new base object and return it. Using this method, ArrayBase.__New()
	; is not called and any instance variables are not initialized.
	params.base := ArrayBase
	return params
}
; Redefine Object() to use our new ObjectBase base class
Object(params*) {
	; Create a new object derived from ObjectBase.
	objectInstance := new ObjectBase
	
	; For each pair of parameters, store the key-value pair.
	Loop, % params.MaxIndex() // 2 {
		key   := params[A_Index * 2 - 1]
		value := params[A_Index * 2]
		objectInstance[key] := value
	}
	
	; Return the new object.
	return objectInstance
}
; =--

; [[ Includes ]] --=
#Include %A_LineFile%\..\class
	#Include actionObject.ahk
	#Include duration.ahk
	#Include epicRecord.ahk
	#Include errorToast.ahk
	#Include flexTable.ahk
	#Include formattedList.ahk
	#Include mousePosition.ahk
	#Include program.ahk
	#Include relativeDate.ahk
	#Include relativeTime.ahk
	#Include selector.ahk
	#Include tableList.ahk
	#Include tempSettings.ahk
	#Include textTable.ahk
	#Include toast.ahk
	#Include visualWindow.ahk
	#Include windowInfo.ahk

#Include %A_LineFile%\..\external
	#Include commandFunctions.ahk
	#Include HTTPRequest.ahk
	
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
	#Include epicStudio.ahk
	#Include excel.ahk
	#Include explorer.ahk
	#Include hyperspace.ahk
	#Include internetExplorer.ahk
	#Include mSnippets.ahk
	#Include notepad.ahk
	#Include notepadPlusPlus.ahk
	#Include onenote.ahk
	#Include onetastic.ahk
	#Include outlook.ahk
	#Include putty.ahk
	#Include snapper.ahk
	#Include soundSwitch.ahk
	#Include spotify.ahk
	#Include telegram.ahk
	#Include vb6.ahk
	
#Include %A_LineFile%\..\static
	#Include config.ahk
	#Include commonHotkeys.ahk
	#Include debug.ahk
	#Include enums.ahk
	#Include hyperlinker.ahk
	#Include scriptTrayInfo.ahk
	#Include titleMatchMode.ahk
	#Include windowActions.ahk
; =--

; [[ Initialization ]] --=
Config.Init()
WindowActions.Init()
Hyperlinker.Init()
; =--