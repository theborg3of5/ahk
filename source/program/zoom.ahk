; Zoom hotkeys.
#If Config.isWindowActive("Zoom")
	; Specific views, directly
	F1::Zoom.switchToSpeakerView()
	F2::Zoom.switchToGalleryView()
	
	; Remote keyboard has these extra bindings (via rebound keys):
	; Music - Alt+A (toggle mute)
	!F3::Zoom.toggleView() ; Lock - Alt+F3
	; Power - Alt+V (toggle video)
#If
