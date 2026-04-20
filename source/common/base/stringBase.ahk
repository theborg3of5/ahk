/* Extension methods for strings, installed on String.Prototype.

	Note: this does not allow you to manipulate the string itself - all functions return the result of the operation.
		For example: appendPiece() returns the new string, so you must capture the return value instead of just calling it (i.e. str := str.appendPiece() instead of just str.appendPiece())

	Example usage:
;		str := "abcd"
;		result := str.contains("b") ; result = 2

*/

class _StringExt {
	;region ------------------------------ PUBLIC ------------------------------
	width(tabWidth := 4) {
		widestWidth := 0
		for _, line in StrSplit(this, "`n") {
			width := StrLen(StrReplace(line, "`t", StringLib.getSpaces(tabWidth)))
			DataLib.updateMax(&widestWidth, width)
		}

		return widestWidth
	}

	isAlpha() {
		return IsAlpha(this)
	}

	isNum() {
		if this = ""
			return false

		if SubStr(this, 1, 2) = "0x"
			return false

		return IsNumber(this)
	}

	isDigits() {
		return IsDigit(this)
	}

	isAlphaNum() {
		return IsAlnum(this)
	}

	isEvenNum() {
		return this.isNum() && Mod(this, 2) = 0
	}

	isOddNum() {
		return this.isNum() && Mod(this, 2) = 1
	}

	charAt(pos) {
		return this.sub(pos, 1)
	}

	replaceCharAt(pos, newChar) {
		return this.sub(1, pos - 1) newChar this.sub(pos + 1)
	}

	firstChar() {
		return this.sub(1, 1)
	}

	lastChar() {
		return this.sub(StrLen(this))
	}

	contains(needle, searchFromEnd := false) {
		if searchFromEnd
			return InStr(this, needle, , 0)
		else
			return InStr(this, needle)
	}

	matchesRegEx(needleRegEx, &outputVar?) {
		return RegExMatch(this, needleRegEx, &outputVar)
	}

	countMatches(needle) {
		StrReplace(this, needle, , , &matchCount)
		return matchCount
	}

	containsAnyOf(needlesAry, &matchedNeedle?) {
		earliestMatchedPos := 0

		for _, needle in needlesAry {
			matchedPos := this.contains(needle)
			if matchedPos {
				if !earliestMatchedPos || matchedPos < earliestMatchedPos {
					earliestMatchedPos := matchedPos
					if IsSet(matchedNeedle)
						matchedNeedle := needle
				}
			}
		}

		return earliestMatchedPos
	}

	isAnyOf(needlesAry) {
		return needlesAry.contains(this)
	}

	startsWith(checkString) {
		return this.sub(1, StrLen(checkString)) = checkString
	}

	endsWith(checkString) {
		return this.sub(StrLen(this) - StrLen(checkString) + 1) = checkString
	}

	startsWithAnyOf(needlesAry, &matchedNeedle?) {
		for _, needle in needlesAry {
			if this.startsWith(needle) {
				if IsSet(matchedNeedle)
					matchedNeedle := needle
				return true
			}
		}

		return false
	}

	sub(startPos, length := "") {
		if length = ""
			return SubStr(this, startPos)
		else
			return SubStr(this, startPos, length)
	}

	replaceSub(replaceWith, startPos, length := "") {
		return this.sub(1, startPos - 1) replaceWith this.sub(startPos + length)
	}

	slice(startPos, stopBeforePos) {
		return this.sub(startPos, stopBeforePos - startPos)
	}

	replaceSlice(replaceWith, startPos, stopBeforePos) {
		return this.sub(1, startPos - 1) replaceWith this.sub(stopBeforePos + 1)
	}

	beforeString(checkString, searchFromEnd := false) {
		checkStringPos := this.contains(checkString, searchFromEnd)
		if !checkStringPos
			return this

		return this.sub(1, checkStringPos - 1)
	}

	afterString(checkString, searchFromEnd := false) {
		checkStringPos := this.contains(checkString, searchFromEnd)
		if !checkStringPos
			return this

		return this.sub(checkStringPos + StrLen(checkString))
	}

	firstBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, false)
	}

	allBetweenStrings(startString, endString) {
		return this.getBetweenStrings(startString, endString, true)
	}

	removeFromStart(toRemove) {
		if !this.startsWith(toRemove)
			return this

		return this.sub(StrLen(toRemove) + 1)
	}

	removeFromEnd(toRemove) {
		if !this.endsWith(toRemove)
			return this

		return this.sub(1, StrLen(this) - StrLen(toRemove))
	}

	prependIfMissing(strToAdd) {
		if this.sub(1, StrLen(strToAdd)) != strToAdd
			return strToAdd this

		return this
	}

	appendIfMissing(strToAdd) {
		if this.sub(-(StrLen(strToAdd) - 1)) != strToAdd
			return this strToAdd

		return this
	}

	firstLine() {
		return this.beforeString("`r").beforeString("`n")
	}

	lastLine() {
		return this.afterString("`n", true)
	}

	withoutWhitespace() {
		return Trim(this)
	}

	prePadToLength(numChars, withChar := " ") {
		outStr := this

		while StrLen(outStr) < numChars
			outStr := withChar outStr

		return outStr
	}

	postPadToLength(numChars, withChar := " ") {
		outStr := this

		while StrLen(outStr) < numChars
			outStr .= withChar

		return outStr
	}

	replace(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith)
	}

	replaceOne(needle, replaceWith) {
		return StrReplace(this, needle, replaceWith, , , 1)
	}

	remove(needle) {
		return this.replace(needle, "")
	}

	replaceRegEx(needleRegEx, replaceWith) {
		return RegExReplace(this, needleRegEx, replaceWith)
	}

	removeRegEx(needleRegEx) {
		return this.replaceRegEx(needleRegEx, "")
	}

	appendPiece(delimiter, pieceToAdd) {
		if pieceToAdd = ""
			return this
		if this = ""
			return pieceToAdd

		return this delimiter pieceToAdd
	}

	appendLine(lineToAdd) {
		return this.appendPiece("`n", lineToAdd)
	}

	containsPiece(needle, delimiter) {
		containerString := delimiter this delimiter
		return this.contains(delimiter needle delimiter)
	}

	piece(delimiter, pieceNum) {
		return this.split(delimiter)[pieceNum]
	}

	repeat(numTimes) {
		return StringLib.duplicate(this, numTimes)
	}

	replaceTag(tagName, replacement) {
		return this.replace("<" tagName ">", replacement)
	}

	replaceTags(tagsAry) {
		outputString := this

		for tagName, replacement in tagsAry
			outputString := outputString.replaceTag(tagName, replacement)

		return outputString
	}

	clean(additionalStringsToRemove := "") {
		outStr := this

		stringsToTrim := []
		stringsToTrim.Push(Chr(10))
		stringsToTrim.Push(Chr(13))
		stringsToTrim.Push(Chr(46))
		stringsToTrim.Push(Chr(160))
		stringsToTrim.Push(Chr(8226) "`t")
		stringsToTrim.Push(Chr(111) "`t")
		stringsToTrim.Push(Chr(61607) "`t")

		for _, string in additionalStringsToRemove
			stringsToTrim.Push(string)

		outStr := StringLib.dropLeadingTrailing(outStr, stringsToTrim)

		stringsToReplace := Map()
		stringsToReplace[Chr(160)] := A_Space

		for toReplace, replaceWith in stringsToReplace
			outStr := outStr.replace(toReplace, replaceWith)

		return outStr
	}

	split(delimiters := "", surroundingCharsToDrop := "") {
		return StrSplit(this, delimiters, surroundingCharsToDrop)
	}
	;endregion ------------------------------ PUBLIC ------------------------------

	;region ------------------------------ PRIVATE ------------------------------
	getBetweenStrings(startString, endString, upToLastEndString) {
		outStr := this.afterString(startString)
		return outStr.beforeString(endString, upToLastEndString)
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}

; Install all methods onto String.Prototype
for name in _StringExt.Prototype.OwnProps() {
	if SubStr(name, 1, 2) != "__"
		String.Prototype.DefineProp(name, _StringExt.Prototype.GetOwnPropDesc(name))
}
