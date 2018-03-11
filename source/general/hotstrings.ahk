; note to self: this must be in UTF-8 encoding.

#If !MainConfig.windowIsGame()
{ ; Emails.
	:*:emaila::
		Send, % USER_EMAIL
	return
	:*:gemaila::
		Send, % USER_EMAIL_2
	return
	:*:eemaila::
		Send, % EPIC_EMAIL
	return
	:*:oemaila::
		Send, % USER_OUTLOOK_EMAIL
	return
}

{ ; Addresses.
	:*:waddr::
		SendRaw, % madisonAddress
	return
	
	:*:eaddr::
		Send, % epicAddress
	return
	::ezip::
		Send, % epicAddressZip
	return
}

{ ; Logins.
	:*:uname::
		Send, % USER_USERNAME
	return
}

{ ; Phone numbers.
	:*:phoneno::
		Send, % USER_PHONE_NUM
	return
	:*:fphoneno::
		Send, % reformatPhone(USER_PHONE_NUM)
	return
}

{ ; Typo correction.
	::,3::<3
	:*:<#::<3
	:*:<43::<3
	:*::0:::)
	:*:;)_::;)
	:*::)_:::)
	:*::)(:::)
	:*:O<o::O,o
	:*:o<O::o,O
	:*:O<O::O,O
	:*R:^<^::^,^
	:*R:6,6::^,^
	:*R:6,^::^,^
	:*R:^,6::^,^
	:*:*shurgs*::*shrugs*
	:*:mmgm::mmhm
	:*:fwere::fewer
	:*:aew::awe
	:*:teh::the
	:*:tteh::teh
	:*:nayone::anyone
	:*:idneed::indeed
	:*:seriuosly::seriously
	:*:.ocm::.com
	:*:heirarchy::hierarchy
	::previou::previous
	:*:previosu::previous
	:*:dcb::dbc
	:*:h?::oh?
}

{ ; Expansions.
	{ ; General
		:*:gov't::government
		:*:eq'm::equilibrium
		:*:f'n::function
		:*:tech'l::technological
		:*:eq'n::equation
		:*:pop'n::population
		:*:def'n::definition
		:*:int'l::international
		:*:int'e::internationalize
		:*:int'd::internationalized
		:*:int'n::internationalization
		:*:ppt'::powerpoint
		:*:conv'l::conventional
		:*:Au'::Australia
		:*:char'c::characteristic
		:*:intro'd::introduced
		:*:dev't::development
		:*:civ'd::civilized
		:*:ep'n::European
		:*:uni'::university
		:*:sol'n::solution
		:*:sync'd::synchronized
		:*:pos'n::position
		:*:pos'd::positioned
		:*:imp't::implement
		:*:imp'n::implementation
		:*:add'l::additional
		:*:org'n::organization
		:*:doc'n::documentation
		:*:hier'l::hierarchical
		:*:heir'l::hierarchical
		:*:c'i::check-in
		:*:c'o::check-out
		:*:qai::QA Instructions
		:*:acc'n::association
		
		:*:.iai::...I'll allow it
		:*:iai::I'll allow it
		:*:asig::and so it goes, and so it goes, and you're the only one who knows...
	}

	{ ; Billing
		:*:col'n::collection
		:*:coll'n::collection
	}
}
	
{ ; Date and time.
	::idate::
		sendDateTime("M/d/yy")
		
		; Excel special.
		if(WinActive("ahk_class XLMAIN"))
			Send, {Tab}
	return
	
	:*:dashidate::
		sendDateTime("M-d-yy")
	return
	:*:uidate::
		sendDateTime("M_d_yy")
	return
	:*:didate::
		sendDateTime("dddd`, M/d")
	return
	:*:iddate::
		sendDateTime("M/d`, dddd")
	return
	
	:*:itime::
		sendDateTime("h:mm tt")
	return
	
	:*:idatetime::
	:*:itimedate::
		sendDateTime("h:mm tt M/d/yy")
	return
	
	; Arbitrary dates/times, translates
	:*:aidate::
		queryDateAndSend()
	return
	:*:aiddate::
		queryDateAndSend("M/d/yy`, dddd")
	return
	:*:adidate::
		queryDateAndSend("dddd`, M/d/yy")
	return
	queryDateAndSend(format = "M/d/yy") {
		date := queryDate(format)
		if(date)
			SendRaw, % date
	}
	
	:*:aitime::
		queryTimeAndSend() {
			time := queryTime()
			if(time)
				SendRaw, % time
		}
}

{ ; URLs.
	:*:lpv::chrome-extension://hdokiejnpimakedhajhdlcegeplioahd/vault.html
}

{ ; Folders and paths.
	{ ; General
		:*:pff::C:\Program Files\
		:*:xpff::C:\Program Files (x86)\
		
		:*:urf::
			sendFolderPath("USER_ROOT")
		return
		:*:deskf::
			sendFolderPath("USER_ROOT", "Desktop")
		return
		:*:dsf::
			sendFolderPath("USER_ROOT", "Design")
		return
		:*:dlf::
			sendFolderPath("DOWNLOADS")
		return
		:*:devf::
			sendFolderPath("USER_ROOT", "Dev")
		return
	}

	{ ; AHK
		:*:arf::
			sendFolderPath("AHK_ROOT")
		return
		:*:aconf::
			sendFolderPath("AHK_CONFIG")
		return
		:*:alconf::
			sendFolderPath("AHK_LOCAL_CONFIG")
		return
		:*:atf::
			sendFolderPath("AHK_ROOT", "test")
		return
		:*:asf::
			sendFolderPath("AHK_SOURCE")
		return
		:*:acf::
			sendFolderPath("AHK_SOURCE", "common")
		return
		:*:apf::
			sendFolderPath("AHK_SOURCE", "program")
		return
		:*:agf::
			sendFolderPath("AHK_SOURCE", "general")
		return
		:*:astf::
			sendFolderPath("AHK_SOURCE", "standalone")
		return
	}

	{ ; Epic - General
		:*:epf::
			sendFolderPath("EPIC_PERSONAL")
		return
		:*:ssf::
			sendFolderPath("USER_ROOT", "Screenshots")
		return
		:*:enfsf::
			sendFolderPath("EPIC_NFS_3DAY")
		return
		:*:eunfsf::
			sendUnixFolderPath("EPIC_NFS_3DAY_UNIX")
		return
		
		:*:ecompf::
			sendFolderPath("VB6_COMPILE")
		return
	}
	
	{ ; Epic - Source
		:*:esf::
			sendFolderPath("EPIC_SOURCE_S1")
		return
		:*:fesf::
			sendFilePath("EPIC_SOURCE_S1", epicDesktopProject)
		return
	}
}

{ ; AHK.
	:*:dbpop::
		SendRaw, DEBUG.popup(") ; ending quote for syntax highlighting: "
		Send, {Left} ; Get inside parens
	return
}
#IfWinNotActive

; Edits this file.
^!h::
	editScript(A_LineFile)
return
