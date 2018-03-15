; Window status codes
global WS_EX_CONTROLPARENT = 0x10000
global WS_EX_APPWINDOW     = 0x40000
global WS_EX_TOOLWINDOW    = 0x80
global WS_DISABLED         = 0x8000000
global WS_POPUP            = 0x80000000

; SysGet command numbers, from https://autohotkey.com/docs/commands/SysGet.htm
SM_CXBORDER    := 5  ; For non-3D windows (which should be most), the width of the border on the left and right.
SM_CYBORDER    := 6  ; For non-3D windows (which should be most), the width of the border on the top and bottom.
SM_CXMAXIMIZED := 61 ; Width of a maximized window on the primary monitor. Includes any weird offsets.
SM_CYMAXIMIZED := 62 ; Height of a maximized window on the primary monitor. Includes any weird offsets.

; Delimiters and special characters.
global QUOTES := """"

; Different sets of common hotkeys
global HOTKEY_TYPE_Standalone := 0 ; One-off scripts, not connected to master script
global HOTKEY_TYPE_Master     := 1 ; Master script
global HOTKEY_TYPE_SubMaster  := 2 ; Standalone scripts that the master script starts and that run alongside the master script

; Title match modes
global TITLE_MATCH_MODE_Start   := 1
global TITLE_MATCH_MODE_Contain := 2
global TITLE_MATCH_MODE_Exact   := 3

