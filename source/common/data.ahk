; Data-structure-related functions.
global CONTAINS_ANY   := 1
global CONTAINS_BEG   := 2
global CONTAINS_END   := 3
global CONTAINS_EXACT := 4


; Returns the number of keys in an array.
;  Returns 0 for null or non-objects
;  Returns count of both numeric and string indices.
getArraySize(ary) {
	if(!ary | !isObject(ary))
		return 0
	
	; Catches both string (associative arrays) and integer keys.
	size := 0
	For i,v in ary
		size++
	
	return size
}

isEmpty(obj) {
	if(!isObject(obj))
		return true
	
	For i,v in obj
		return false ; We found something, not empty.
	
	return true
}

; If the given object is already an array, return it. Otherwise, return an array with the given object as its only element (index 0).
forceArray(obj) {
	if(IsObject(obj))
		return obj
	
	newArray := []
	newArray[0] := obj
	return newArray
}

forceNumber(data) {
	if(isNum(data))
		return data
	return 0
}

; Inserts an item at the beginning of an array.
insertFront(ByRef arr, new) {
	arr2 := Object()
	arr2.Insert(new)
	; DEBUG.popup(arr2, "Array 2")
	
	arrLen := arr.MaxIndex()
	Loop, %arrLen% {
		arr2.Insert(arr[A_Index])
	}
	
	return arr2
}

; Array contains function. Returns index if it exists, assumes a numerical index starting at 1.
contains(haystack, needle, partialMatch := false) {
	; DEBUG.popup("Hay", haystack, "Needle", needle)
	
	For i, el in haystack {
		; DEBUG.popup("Index", i, "Element", "z" el "Z", "Needle", "z" needle "Z", "Partial", partialMatch, "Element contains needle", stringContains(el, needle), "Elements equals needle", (el = needle))
		
		if( el = needle || (partialMatch && stringContains(needle, el)) )
			return i
	}
	
	return ""
}

; Reverse array contains function - checks if any of array strings are in given string.
containsAnyOf(haystack, needles, match := 1) { ; match = CONTAINS_ANY
	; DEBUG.popup(haystack, "Haystack", needles, "Needles", match, "Match")
	For i, el in needles {
		
		if(match = CONTAINS_ANY) {
			if(stringContains(haystack, el))
				return i
		
		} else if(match = CONTAINS_BEG) {
			if(stringStartsWith(haystack, el))
				return i
		
		} else if(match = CONTAINS_END) {
			if(stringEndsWith(haystack, el))
				return i
			
		} else if(match = CONTAINS_EXACT) {
			if(haystack = el)
				return i
			
		} else {
			DEBUG.popup(match, "Unsupported match method")
		}
	}
	
	return ""
}

; Table contains function.	
tableContains(table, toFind) {
	For i,row in table {
		For j,r in row {
			; debugPrint(r)
			if(r = toFind) {
				return i
			}
		}
	}
}

; Converts decimal numbers to hex ones.
decimalToHex(var) {
	SetFormat, integer, hex
	var += 0
	SetFormat, integer, d
	return var
}

; Contained, single call for multiple equality tests.
matches(compareVars*) {
	varsLen := compareVars.MaxIndex()
	if(mod(varsLen, 2) = 1)
		return -1
	
	for i,v in compareVars {
		if(mod(i, 2) = 1) {
			if(v != compareVars[i+1])
				return false
		}
	}
	
	return true
}

; Maximum of any number of numeric arguments.
max(nums*) {
	; DEBUG.popup("Max", "Start", "Nums", nums)
	max := nums[1]
	For i,n in nums {
		if((max = "") || (max < n))
			max := n
	}
	
	return max
}

; Change a pesky pseudoarray into the real deal.
convertPseudoArrayToObject(arrayName) {
	; DEBUG.popup("Array name", arrayName, "Matched Count", %arrayName%, "First matched entry", %arrayName%1)
	retObj := []
	
	arrayCount := %arrayName%
	Loop, %arrayCount% {
		retObj[A_Index] := %arrayName%%A_Index%
	}
	
	return retObj
}

reIndexArray(inputAry, indexMap) {
	tempAry := []
	
	For i,a in inputAry
		tempAry[indexMap[i]] := a
	
	return tempAry
}

; overrides wins if they both have an index.
mergeArrays(default, overrides) {
	if(IsObject(default))
		retAry := default.clone()
	else
		retAry := []
	
	For i,v in overrides {
		if(IsObject(v))
			retAry[i] := mergeArrays(default[i], v)
		else
			retAry[i] := v
	}
	
	return retAry
}

; Counterpart to strSplit() - puts together all parts of an array with the given delimiter (defaults to "|")
arrayJoin(arrayToJoin, delim := "|") {
	outStr := ""
	
	For index,value in arrayToJoin {
		if(outStr)
			outStr .= delim
		outStr .= value
	}
	
	return outStr
}

; Sets global variables to null.
nullGlobals(baseName, startIndex, endIndex) {
	global
	local i
	
	i := startIndex
	While i <= endIndex {
		; DEBUG.popup("Variable", baseName i, "Before nullify", %baseName%%i%)
		%baseName%%i% := ""
		; DEBUG.popup("Variable", baseName i, "After nullify", %baseName%%i%)
		i++
	}
}
