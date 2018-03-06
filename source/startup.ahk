; Startup, auto-execute sections for all scripts.

; @Lock fixing.
	SetCapsLockState, AlwaysOff
	SetScrollLockState, AlwaysOff
; @End Lock fixing.

; @KDE Mover-Sizer.
	SnapOnSizeEnabled := 1
	SnapOnMoveEnabled := 1
	SnapOnResizeMagnetic := 0
	DoRestoreOnResize := 1
	SnappingDistance := 10
	WinDelay := 2

	SetWinDelay, %WinDelay%
	CoordMode, Mouse, Screen

	MayToggle := true
; @End KDE Mover-Sizer.
