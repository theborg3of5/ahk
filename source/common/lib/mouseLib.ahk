; Mouse-related helper functions.

class MouseLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Click at the specified coordinates, optionally with a specific coordinate mode.
	; PARAMETERS:
	;  x         (I,REQ) - X coordinate to click at.
	;  y         (I,REQ) - Y coordinate to click at.
	;  coordMode (I,OPT) - The CoordMode to use for the click. If not specified, uses the current CoordMode.
	;---------
	static clickAndReturn(x, y, coordMode := "") {
		MouseGetPos(&startX, &startY)

		settings := ""
		if coordMode
			settings := TempSettings().coordMode("Mouse", coordMode)

		MouseMove(x, y)
		Click()

		if settings
			settings.restore()

		MouseMove(startX, startY)
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
