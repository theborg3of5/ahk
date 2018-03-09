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

; Window sizing/positioning
global TASKBAR_HEIGHT := 30

; Different sets of common hotkeys
global HOTKEY_TYPE_STANDALONE := 0
global HOTKEY_TYPE_MASTER     := 1
global HOTKEY_TYPE_SUB_MASTER := 2

; Title match modes
global TITLE_MATCH_MODE_START   := 1
global TITLE_MATCH_MODE_CONTAIN := 2
global TITLE_MATCH_MODE_EXACT   := 3

