; Notepad++
class NotepadPlusPlus {
	;region ------------------------------ PUBLIC ------------------------------

	openTempText(text) {
		; Stick the text in a file
		tempPath := FileLib.writeToOldestTempFile(text)

		; Open that file in Notepad++
		Config.runProgram("Notepad++", tempPath)
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
