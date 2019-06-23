; Greenshot image editor
#If MainConfig.isWindowActive("Greenshot Image Editor")
	; Copy to clipboard
	^c::^+c
#If

; Greenshot capture overlay
#If MainConfig.isWindowActive("Greenshot Capture")
	; Launch standalone script for moving the mouse with arrow keys
	ScrollLock::Run(MainConfig.path["AHK_SOURCE"] "\standalone\preciseMouse\preciseMouse.ahk")
#If
