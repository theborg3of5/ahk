; Various global hotstrings.

#If !Config.windowIsGame()
;region Personal info
:X:emaila:: Send, % Config.private["EMAIL"]
:X:gemaila::Send, % Config.private["EMAIL_2"]
:X:eemaila::Send, % Config.private["WORK_EMAIL"]
:X:oemaila::Send, % Config.private["OUTLOOK_EMAIL"]

:X:phoneno:: Send, % Config.private["PHONE_NUM"]
:X:fphoneno::Send, % PhoneLib.formatNumber(Config.private["PHONE_NUM"])

:X:waddr::   SendRaw, % Config.private["HOME_ADDRESS"]
:X:eaddr::   Send,    % Config.private["WORK_ADDRESS"]
:*0X:wzip::  Send,    % Config.private["HOME_ZIP_CODE_FULL"]
:*0X:ezip::  Send,    % Config.private["WORK_ZIP_CODE"]

:X?:ecompnum::Send, % Config.private["WORK_COMPUTER_NUM"]

:X:uname::Send, % Config.private["USERNAME"]
;endregion Personal info

;region Typo correction
:*0:,3::<3
::<#::<3
::<43::<3
:*0::0:::)
::;)_::;)
:::)_:::)
:::)(:::)
::*shurgs*::*shrugs*
::mmgm::mmhm
::fwere::fewer
::teh::the
::nayone::anyone
::idneed::indeed
:*0:ndeed::indeed
::seriuosly::seriously
::.ocm::.com
::heir::hier
:*0:previou::previous
::previosu::previous
::isntead::instead
::dcb::dbc
::h?::oh?
::it"s::it's ; "
::that"s::that's ; "
::scheduleable::schedulable
::createable::creatable
::performably::performable
::resizeable::resizable
::overrideable::overridable
::Tapestery::Tapestry
::InBasket::In Basket
::flase::false
::associt::associat
::assocait::associat
::associatied::associated
::valiation::validation
::verpleedag::verpleegdag
::precendence::precedence
::abcense::absence
::voilates::violates
::timeframe::time frame
::cahrge::charge
::fitler::filter
::hotsting::hotstring
::propertly::properly
::everythign::everything
;endregion Typo correction
	
#If !["EpicStudio", "Visual Studio", "VSCode", "VB6"].contains(Config.findWindowName("A"))
	::helptext::help text
#If

;region Expansions
::f'n::function
::def'n::definition
::int'l::international
::int'd::internationalized
::int'n::internationalization
::sol'n::solution
::pos'n::position
::add'l::additional
::hier'l::hierarchical
::heir'l::hierarchical
::auth'n::authorization
::qai::QA Instructions
::cache''::Caché
::snuuz::snüz
::med'n::medication

::ass'n::association
::assoc'n::association
::ass'd::associated
::assoc'd::associated
::aass'n::auto-association
::aassoc'n::auto-association
::aass'd::auto-associated
::aassoc'd::auto-associated
:*0:ade::associated DBC episode

:?:sync's::synchronous ; Allow in other words for asynchronously

::.asig::and so it goes, and so it goes, and you're the only one who knows...

::.shrug::¯\_(ツ)_/¯
;endregion Expansions

;region Date and time
:X:idate::Send, % FormatTime(A_Now, "M/d/yy")
:X:itime::Send, % FormatTime(A_Now, "h:mm tt")

:X:dashidate::Send, % FormatTime(A_Now, "M-d-yy")
:X:didate::   Send, % FormatTime(A_Now, "dddd`, M/d")
:X:iddate::   Send, % FormatTime(A_Now, "M/d`, dddd")

::.tscell::
	Send, % FormatTime(A_Now, "M/d/yy")
	Send, {Tab}
	Send, % FormatTime(A_Now, "h:mm tt")
	Send, {Tab}
return

; Relative dates/times
:X:aidate:: sendArbitraryDate("M/d/yy")
:X:aiddate::sendArbitraryDate("M/d`, dddd")
:X:adidate::sendArbitraryDate("dddd`, M/d")
:X:aitime:: sendArbitraryTime("h:mm tt")
;endregion Date and time

;region Folders and paths
; General
:X:pff:: sendFolderPath("PROGRAM_FILES")
:X:xpff::sendFolderPath("PROGRAM_FILES_86")

:X:urf::  sendFolderPath("USER_ROOT")
:X:dsf::  sendFolderPath("USER_DESKTOP")
:X:specf::sendFolderPath("USER_SPECIFICS")
:X:devf:: sendFolderPath("USER_DEV")
:X:zrzlf::sendFolderPath("USER_DEV", "zrzl")
	
#If !WinActive("ahk_class AutoHotkeyGUI") ; Don't do this in Selector popups (yes this catches more than that)
	:X:dlf::  sendFolderPath("USER_DOWNLOADS")
#If

:X:otmf::sendFolderPath("ONETASTIC_MACROS")
:X:npsf::sendFolderPath("NOTEPAD_PP_SESSIONS")

; AHK
:X:arf::   sendFolderPath("AHK_ROOT")
:X:aconf:: sendFolderPath("AHK_CONFIG")
:X:atf::   sendFolderPath("AHK_TEST")
:X:apf::   sendFolderPath("AHK_SOURCE", "program")
:X:agf::   sendFolderPath("AHK_SOURCE", "general")
:X:astf::  sendFolderPath("AHK_SOURCE", "standalone")
:X:asubf:: sendFolderPath("AHK_SOURCE", "sub")
:X:acf::   sendFolderPath("AHK_SOURCE", "common\class")
:X:abf::   sendFolderPath("AHK_SOURCE", "common\base")
:X:alf::   sendFolderPath("AHK_SOURCE", "common\lib")
:X:acpf::  sendFolderPath("AHK_SOURCE", "common\program")
:X:asf::   sendFolderPath("AHK_SOURCE", "common\static")

; Epic - General
:X:epf::   sendFolderPath("EPIC_PERSONAL")
:X:ssf::   sendFolderPath("USER_ROOT", "Screenshots")
:X:enfsf:: sendFolderPath("EPIC_NFS_3DAY")
:X:eunfsf::sendUnixFolderPath("EPIC_NFS_3DAY_UNIX")

; Epic - Source
:X:esf::sendFolderPath("EPIC_SOURCE_CURRENT")

; URLs
:X:lpv::Send, % "chrome-extension://hdokiejnpimakedhajhdlcegeplioahd/vault.html"
;endregion Folders and paths

;region Useful strings
:X:.tens::
	sendTenString() {
		length := InputBox("Insert Ten-String", "How long can your text be?")
		if(!length)
			return
		
		ClipboardLib.send(StringLib.getTenString(length))
	}
;endregion Useful strings
#If ; gdbtodo this isn't closing anything anymore - other "if" above is superceding it

;region Helper functions
sendArbitraryDate(format) {
	QUOTE := """"
	
	title := "Insert date in " QUOTE format.remove("`") QUOTE " format:"
	dateString := InputBox(title, "Enter a relative date string to insert that date in the above format.", , 425, 125)
	if(dateString = "")
		return ""
	
	new RelativeDate(dateString).sendInFormat(format)
}
sendArbitraryTime(format) {
	QUOTE := """"
	
	title := "Insert date in " QUOTE format.remove("`") QUOTE " format:"
	timeString := InputBox(title, "Enter a relative time string to insert that time in the above format.", , 425, 125)
	if(timeString = "")
		return ""
	
	new RelativeTime(timeString).sendInFormat(format)
}

sendFilePath(folderName, subPath := "") {
	FileLib.sendPath(folderName, subPath)
}
sendFolderPath(folderName, subPath := "") {
	FileLib.sendPath(folderName, subPath, "\", true)
}
sendUnixFolderPath(folderName, subPath := "") {
	FileLib.sendPath(folderName, subPath, "/", true)
}
;endregion Helper functions
