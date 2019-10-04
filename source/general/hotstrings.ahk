; note to self: this must be in UTF-8 encoding.

#If !Config.windowIsGame()
{ ; Emails.
	:X:emaila::Send,  % Config.private["EMAIL"]
	:X:gemaila::Send, % Config.private["EMAIL_2"]
	:X:eemaila::Send, % Config.private["WORK_EMAIL"]
	:X:oemaila::Send, % Config.private["OUTLOOK_EMAIL"]
}

{ ; Addresses.
	:X:waddr::SendRaw, % Config.private["HOME_ADDRESS"]
	:X:eaddr::Send, % Config.private["WORK_ADDRESS"]
	:*0X:ezip::Send, % Config.private["WORK_ZIP_CODE"]
}

{ ; Logins.
	:X:uname::Send, % Config.private["USERNAME"]
}

{ ; Phone numbers.
	:X:phoneno::Send, % Config.private["PHONE_NUM"]
	:X:fphoneno::Send, % reformatPhone(Config.private["PHONE_NUM"])
}

{ ; Typo correction.
	:*0:,3::<3
	::<#::<3
	::<43::<3
	:::0:::)
	::;)_::;)
	:::)_:::)
	:::)(:::)
	::*shurgs*::*shrugs*
	::mmgm::mmhm
	::fwere::fewer
	::aew::awe
	::teh::the
	::tteh::teh
	::nayone::anyone
	::idneed::indeed
	::seriuosly::seriously
	::.ocm::.com
	::heirarchy::hierarchy
	:*0:previou::previous
	::previosu::previous
	::dcb::dbc
	::h?::oh?
	:*0:ndeed::indeed
	::IT"S::IT'S ; "
	::THAT"S::THAT'S ; "
	::scheduleable::schedulable
	::performably::performable
	::isntead::instead
	::overrideable::overridable
	::Tapestery::Tapestry
	::InBasket::In Basket
	::flase::false
}

{ ; Expansions.
	{ ; General
		::gov't::government
		::eq'm::equilibrium
		::f'n::function
		::tech'l::technological
		::eq'n::equation
		::pop'n::population
		::def'n::definition
		::int'l::international
		::int'e::internationalize
		::int'd::internationalized
		::int'n::internationalization
		::ppt'::powerpoint
		::conv'l::conventional
		::Au'::Australia
		::char'c::characteristic
		::intro'd::introduced
		::dev't::development
		::civ'd::civilized
		::ep'n::European
		::uni'::university
		::sol'n::solution
		::pos'n::position
		::pos'd::positioned
		::imp't::implement
		::imp'n::implementation
		::add'l::additional
		::org'n::organization
		::doc'n::documentation
		::hier'l::hierarchical
		::heir'l::hierarchical
		::qai::QA Instructions
		::acc'n::association
		::inf'n::information
		::info'n::information
		::ass'n::association
		
		:?:sync'ly::synchronously
		
		::.iai::...I'll allow it
		::iai::I'll allow it
		::asig::and so it goes, and so it goes, and you're the only one who knows...
	}

	{ ; Billing
		::col'n::collection
		::coll'n::collection
		::auth'n::authorization
	}
	
	{ ; Emoji
		::.shrug::{U+AF}\_({U+30C4})_/{U+AF} ; ¯\_(ツ)_/¯ - 0xAF=¯, 0x30C4=ツ
	}
}

{ ; Date and time.
	:X:idate::Send, % FormatTime(A_Now, "M/d/yy")
	:X:itime::Send, % FormatTime(A_Now, "h:mm tt")
	
	:X:dashidate::Send, % FormatTime(A_Now, "M-d-yy")
	:X:didate::Send, % FormatTime(A_Now, "dddd`, M/d")
	:X:iddate::Send, % FormatTime(A_Now, "M/d`, dddd")
	
	::.tscell::
		Send, % FormatTime(A_Now, "M/d/yy")
		Send, {Tab}
		Send, % FormatTime(A_Now, "h:mm tt")
		Send, {Tab}
	return
	
	; Arbitrary dates/times, translates
	:X:aidate::sendRelativeDate()
	:X:aiddate::sendRelativeDate("M/d`, dddd")
	:X:adidate::sendRelativeDate("dddd`, M/d")
	:X:aitime::sendRelativeTime()
}

{ ; URLs.
	:X:lpv::Send, % "chrome-extension://hdokiejnpimakedhajhdlcegeplioahd/vault.html"
}

{ ; Folders and paths.
	{ ; General
		:X:pff::sendFolderPath("PROGRAM_FILES")
		:X:xpff::sendFolderPath("PROGRAM_FILES_86")
		
		:X:urf::sendFolderPath("USER_ROOT")
		:X:dsf::sendFolderPath("USER_DESKTOP")
		:X:desf::sendFolderPath("USER_ROOT", "Design")
		:X:dlf::sendFolderPath("USER_DOWNLOADS")
		:X:devf::sendFolderPath("USER_DEV")
		
		:X:otmf::sendFolderPath("ONETASTIC_MACROS")
	}

	{ ; AHK
		:X:arf::sendFolderPath("AHK_ROOT")
		:X:aconf::sendFolderPath("AHK_CONFIG")
		:X:atf::sendFolderPath("AHK_ROOT", "test")
		:X:asf::sendFolderPath("AHK_SOURCE")
		:X:acf::sendFolderPath("AHK_SOURCE", "common")
		:X:accf::sendFolderPath("AHK_SOURCE", "common\class")
		:X:acbf::sendFolderPath("AHK_SOURCE", "common\class\base")
		:X:apf::sendFolderPath("AHK_SOURCE", "program")
		:X:agf::sendFolderPath("AHK_SOURCE", "general")
		:X:astf::sendFolderPath("AHK_SOURCE", "standalone")
		:X:asuf::sendFolderPath("AHK_SOURCE", "sub")
	}

	{ ; Epic - General
		:X:epf::sendFolderPath("EPIC_PERSONAL")
		:X:ssf::sendFolderPath("USER_ROOT", "Screenshots")
		:X:enfsf::sendFolderPath("EPIC_NFS_3DAY")
		:X:eunfsf::sendUnixFolderPath("EPIC_NFS_3DAY_UNIX")
		
		:X:ecompf::sendFolderPath("VB6_COMPILE")
	}
	
	{ ; Epic - Source
		:X:esf::sendFolderPath("EPIC_SOURCE_S1")
		:X:fesf::sendFilePath("EPIC_SOURCE_S1", Config.private["EPICDESKTOP_PROJECT"])
	}
}
#If

; Edits this file.
^!h::
	editScript(A_LineFile)
return
