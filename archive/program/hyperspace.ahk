; Hyperspace main window
#If Hyperspace.isAnyVersionActive()
	$F5::+F5 ; Make F5 work everywhere by mapping it to shift + F5.
	^+t::Hyperspace.login(Config.private["WORK_ID"], Config.private["WORK_PASSWORD"]) ; Login
#If
