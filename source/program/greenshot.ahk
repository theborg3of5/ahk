; Greenshot image editor
#If Config.isWindowActive("Greenshot Image Editor")
	; Copy to clipboard
	^c::^+c
#If

; Greenshot capture overlay
#If Config.isWindowActive("Greenshot Capture")
	; Launch standalone script for moving the mouse with arrow keys
	ScrollLock::Run(Config.path["AHK_SOURCE"] "\standalone\preciseMouse\preciseMouse.ahk")
#If
