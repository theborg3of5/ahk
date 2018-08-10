; note to self: this must be in UTF-8 encoding.

#If !MainConfig.windowIsGame()
{ ; Emails.
	:X:emaila::Send,  % MainConfig.getPrivate("EMAIL")
	:X:gemaila::Send, % MainConfig.getPrivate("EMAIL_2")
	:X:eemaila::Send, % MainConfig.getPrivate("WORK_EMAIL")
	:X:oemaila::Send, % MainConfig.getPrivate("OUTLOOK_EMAIL")
}

{ ; Addresses.
	:X:waddr::SendRaw, % MainConfig.getPrivate("HOME_ADDRESS")
	:X:eaddr::Send, % MainConfig.getPrivate("WORK_ADDRESS")
	:*0X:ezip::Send, % MainConfig.getPrivate("WORK_ZIP_CODE")
}

{ ; Logins.
	:X:uname::Send, % MainConfig.getPrivate("USERNAME")
}

{ ; Phone numbers.
	:X:phoneno::Send, % MainConfig.getPrivate("PHONE_NUM")
	:X:fphoneno::Send, % reformatPhone(MainConfig.getPrivate("PHONE_NUM"))
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
	::isntead::instead
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
		::sync'd::synchronized
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
		
		::.iai::...I'll allow it
		::iai::I'll allow it
		::asig::and so it goes, and so it goes, and you're the only one who knows...
	}

	{ ; Billing
		::col'n::collection
		::coll'n::collection
		::auth'n::authorization
	}
}

{ ; Date and time.
	:X:idate::sendDateTime("M/d/yy")
	:X:itime::sendDateTime("h:mm tt")
	
	:X:dashidate::sendDateTime("M-d-yy")
	:X:didate::sendDateTime("dddd`, M/d")
	:X:iddate::sendDateTime("M/d`, dddd")
	
	::.tscell::
		sendDateTime("M/d/yy")
		Send, {Tab}
		sendDateTime("h:mm tt")
		Send, {Tab}
	return
	
	; Arbitrary dates/times, translates
	:X:aidate::queryDateAndSend()
	:X:aiddate::queryDateAndSend("M/d`, dddd")
	:X:adidate::queryDateAndSend("dddd`, M/d")
	queryDateAndSend(format = "M/d/yy") {
		date := queryDate(format)
		if(date)
			SendRaw, % date
	}
	
	::aitime::
		queryTimeAndSend() {
			time := queryTime()
			if(time)
				SendRaw, % time
		}
}

{ ; URLs.
	::lpv::chrome-extension://hdokiejnpimakedhajhdlcegeplioahd/vault.html
}

{ ; Folders and paths.
	{ ; General
		::pff::C:\Program Files\
		::xpff::C:\Program Files (x86)\
		
		:X:urf::sendFolderPath("USER_ROOT")
		:X:deskf::sendFolderPath("USER_ROOT", "Desktop")
		:X:dsf::sendFolderPath("USER_ROOT", "Design")
		:X:dlf::sendFolderPath("DOWNLOADS")
		:X:devf::sendFolderPath("USER_ROOT", "Dev")
	}

	{ ; AHK
		:X:arf::sendFolderPath("AHK_ROOT")
		:X:aconf::sendFolderPath("AHK_CONFIG")
		:X:atf::sendFolderPath("AHK_ROOT", "test")
		:X:asf::sendFolderPath("AHK_SOURCE")
		:X:acf::sendFolderPath("AHK_SOURCE", "common")
		:X:apf::sendFolderPath("AHK_SOURCE", "program")
		:X:agf::sendFolderPath("AHK_SOURCE", "general")
		:X:astf::sendFolderPath("AHK_SOURCE", "standalone")
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
		:X:fesf::sendFilePath("EPIC_SOURCE_S1", MainConfig.getPrivate("EPICDESKTOP_PROJECT"))
	}
}
#IfWinNotActive

; Edits this file.
^!h::
	editScript(A_LineFile)
return
