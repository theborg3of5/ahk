; note to self: this must be in UTF-8 encoding.

#IfWinNotActive, ahk_class RiotWindowClass ; Disable for League.
{ ; Emails.
	:*:emaila::
		Send, % USER_EMAIL
	return
	:*:gemaila::
		Send, % USER_EMAIL_2
	return
	:*:eemaila::
		Send, % USER_WORK_EMAIL
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

{ ; Skype.
	:*:ssquirrel::(heidy)
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
		:*:btw::by the way
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
		sendDateTime("dddd`, M/d/yy")
	return
	:*:iddate::
		sendDateTime("M/d/yy`, dddd")
	return
	
	:*:itime::
		sendDateTime("h:mm tt")
	return
	
	:*:idatetime::
	:*:itimedate::
		sendDateTime("h:mm tt M/d/yy")
	return
	
	; Arbitrary dates, translates
	:*:aidate::
		date := queryDate()
		if(date)
			SendRaw, % date
	return
	:*:aiddate::
		date := queryDate("M/d/yy`, dddd")
		if(date)
			SendRaw, % date
	return
	:*:adidate::
		date := queryDate("dddd`, M/d/yy")
		if(date)
			SendRaw, % date
	return
	
	:*:aitime::
		time := queryTime()
		if(time)
			SendRaw, % time
	return
}

{ ; URLs.
	:*c:lpv::chrome-extension://hdokiejnpimakedhajhdlcegeplioahd/vault.html
}

{ ; Folders and paths.
	{ ; General
		:*c:pff::C:\Program Files\
		:*c:xpff::C:\Program Files (x86)\
		:*:.x8:: (x86)\
		
		:*c:auf::
			Send, % userPath
		return
		:*c:dsf::
			Send, % A_Desktop
		return
		:*c:dlf::
			Send, % userPath "Downloads\"
		return
		:*c:ddf::
			Send, % userPath "Dev\"
		return
	}

	{ ; AHK
		:*c:alf::
			Send, % ahkLibPath
		return
		:*c:arf::
			Send, % ahkRootPath
		return
		:*c:aconf::
			Send, % ahkRootPath "config\"
		return
		:*c:asf::
			Send, % ahkRootPath "source\"
		return
		:*c:acf::
			Send, % ahkRootPath "source\common\"
		return
		:*c:apf::
			Send, % ahkRootPath "source\program\"
		return
		:*c:agf::
			Send, % ahkRootPath "source\general\"
		return
		:*c:astf::
			Send, % ahkRootPath "source\standalone\"
		return
		:*c:atf::
			Send, % ahkRootPath "test\"
		return
		:*c:ashf::
			Send, % ahkRootPath "share\"
		return
		
		:*c:aself::
			Send, % ahkRootPath "resources\Selector\"
		return
	}

	{ ; Epic - General
		:*:epf::
			Send, % epicPersonalFolder
		return
		:*:ssf::
			Send, % epicPersonalFolder "Screenshots\"
		return
		:*c:emf::
			Send, % epicMonthlyFolder
		return
		
		:*:ehbf::
			Send, % epicHBFolder
		return
		:*:ehbd::
			Send, % epicHBFolder "Dev\"
		return
		:*:ehbp::
			Send, % epicHBFolder "Dev\Partial Installers\"
		return
		
		:*c:xesf::
			Send, % epicServerDataCDE
		return
	}
	
	{ ; Epic - Source
		:*c:esf::
			Send, % epicSourceCurrentS1
		return
		
		:*c:hesf::
			Send, % epicSourceCurrentS1 epicSourceHBFolder
		return
		:*c:eesf::
			Send, % epicSourceCurrentS1 epicSourceEBFolder
		return
		
		:*c:posf::
			Send, % epicSourceCurrentS1 epicSourceEBFolder "PmtPost\"
		return
		:*c:ciesf::
			Send, % epicSourceCurrentS1 "Cadence\CheckIn\AR Copay\"
		return
		
		:*c:fesf::
			Send, % epicSourceCurrentS1 epicFoundationProject
		return
		:*c:edf::
			Send, % epicSourceCurrentS1 "DLG-"
		return
	}

	{ ; Program-specific
		:*c:ex.::explorer.exe
	}
}

{ ; AHK.
	:*:dbpop::
		SendRaw, DEBUG.popup()
		Send, {Left} ; For right paren
	return
}
#IfWinNotActive

; Edits this file.
^!h::
	editScript(A_LineFile)
return
