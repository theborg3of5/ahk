; note to self: this must be in UTF-8 encoding.

#IfWinNotActive, ahk_class RiotWindowClass ; Disable for League.
{ ; Emails.
	:*:emaila::
		Send, % emailAddress
	return
	:*:gemaila::
		Send, % emailAddressGDB
	return
	:*:eemaila::
		Send, % epicEmailAddress
	return
}

{ ; Addresses.
	:*:waddr::
		SendRaw, % madisonAddress
	return
	:*:fwaddr::
		Send, % madisonAddressFill
	return
	:*:lwaddr::
		Send, % madisonAddressLine
	return
	
	:*:eaddr::
		Send, % epicAddress
	return
	:*:feaddr::
		Send, % epicAddressFill
	return
	::ezip::
		Send, % epicAddressZip
	return
}

{ ; Logins.
	:*:uname::
		Send, % userName
	return
	:*:.unixpass::
		Send, % epicDefaultUnixPass
	return
	:*:.ecid::
		Send, % epicComputerName
	return
}

{ ; Phone numbers.
	:*:phoneno::
		Send, % phoneNumber
	return
	:*:fphoneno::
		Send, % phoneNumberFormatted
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
		::qai::QA Instructions
		
		:*:asig::and so it goes, and so it goes, and you're the only one who knows...
	}
	
	{ ; Healthcare
		:*:Med'c::Medicare
		:*:Med'a::Medicaid
		:*:Medi'c::Medicare
		:*:Medi'a::Medicaid
		:*:p't::patient
	}

	{ ; Billing
		:*:col'n::collection
		:*:coll'n::collection
		:*:prebal::previous balance
	}
	
	{ ; Command line/code
		:*:rkhdf::
			sendKHDFCommand("", "", "")
		return
		:*:skhdf::
			sendKHDFCommand("s", "", "")
		return
		; :*:kkhdf::
			; sendKHDFCommand("k", "", "")
		; return
		
		:*:prkhdf::
			sendKHDFCommand("", "", khdfPOS)
		return
		:*:pskhdf::
			sendKHDFCommand("s", "", khdfPOS, "")
		return
		:*:psskhdf::
			sendKHDFCommand("s", "", khdfPOS, khdfPOSSingle)
		return
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

	{ ; Epic
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
		
		:*c:esf::
			Send, % epicSource83St1
		return
		
		:*c:hesf::
			Send, % epicSource83St1 epicSourceHBFolder
		return
		:*c:eesf::
			Send, % epicSource83St1 epicSourceEBFolder
		return
		:*c:cesf::
			Send, % epicSource83St1 epicSourceCadFolder
		return
		
		:*c:fesf::
			Send, % epicSource83St1 epicFoundationProject
		return
		
		:*c:posf::
			Send, % epicSource83St1 epicSourceEBFolder "PmtPost\"
		return
		:*c:ciesf::
			Send, % epicSource83St1 epicSourceCadFolder "CheckIn\AR Copay\"
		return
		
		:*c:pesf::
			Send, % epicProgramFolder82
		return
		:*c:iesf::
			Send, % epicImagesFolder82
		return
		:*c:sfesf::
			Send, % epicSharedFiles82
		return
		
		:*c:tesf::
			Send, % epicTempData
		return
		:*c:xesf::
		:*c:sdesf::
			Send, % epicServerDataCDE
		return
		
		:*c:edf::
			Send, % epicSourceFolder83 "DLG-"
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
