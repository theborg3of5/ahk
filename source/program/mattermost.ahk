#If MainConfig.isWindowActive("Mattermost")
	^k::
		Send, []()
		Send, {Left 3} ; Get back into the link title slot (between the brackets).
	return
#If
