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

; Basically an easier-to-read ternary operator.
processOverride(defaultVal, overrideVal) {
	if(overrideVal || IsObject(overrideVal))
		return overrideVal
	else
		return defaultVal
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
contains(haystack, needle, partialMatch = false) {
	; DEBUG.popup("Hay", haystack, "Needle", needle)
	
	For i, el in haystack {
		; DEBUG.popup("Index", i, "Element", "z" el "Z", "Needle", "z" needle "Z", "Partial", partialMatch, "Element contains needle", stringContains(el, needle), "Elements equals needle", (el = needle))
		
		if( el = needle || (partialMatch && stringContains(needle, el)) )
			return i
	}
	
	return ""
}

; Reverse array contains function - checks if any of array strings are in given string.
containsAnyOf(haystack, needles, match = 1) { ; match = CONTAINS_ANY
	; DEBUG.popup(haystack, "Haystack", needles, "Needles", match, "Match")
	For i, el in needles {
		
		if(match = CONTAINS_ANY) {
			; DEBUG.popup(match, "Match mode", haystack, "Haystack", el, "Needle", stringContains(haystack, el), "Result")
			
			if(stringContains(haystack, el))
				return i
		
		} else if(match = CONTAINS_BEG) {
			chunk := SubStr(haystack, 1, StrLen(el))
			if(chunk = el)
				return i
		
		} else if(match = CONTAINS_END) {
			chunk := SubStr(haystack, (1 - StrLen(el)))
			if(chunk = el)
				return i
			
		} else if(match = CONTAINS_EXACT) {
			if(haystack = el)
				return i
			
		} else {
			DEBUG.popup(match, "Unsupported match method")
		}
	}
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
mergeArrays(base, overrides) {
	if(IsObject(base))
		retAry := base.clone()
	else
		retAry := []
	
	For i,v in overrides {
		if(IsObject(v))
			retAry[i] := mergeArrays(base[i], v)
		else
			retAry[i] := v
	}
	
	return retAry
}

; Counterpart to SplitStr - puts together all parts of an array with the given delimiter (defaults to "|")
arrayJoin(arrayToJoin, delim = "|") {
	outStr := ""
	
	For index,value in arrayToJoin
		outStr .= delim value
	
	return SubStr(outStr, StrLen(delim) + 1) ; Trim off the leading delimiter.
}



; Eval() function and helpers - turn a numeric expression in a string into a result.
; From http://www.autohotkey.com/board/topic/15675-monster-evaluate-math-expressions-in-strings/?p=231869 .
Eval(x) {   ; Evaluate arithmetic expression with numbers, + - / * ( )
   Return Eval#(RegExReplace(x,"-","#")) ; # = subtraction, to distinguish from sign
}

Eval#(x) {  ; Evaluate expression with numbers, + #(subtract) / * ( ). Recurse into (..)
   Return RegExMatch(x,"(.*)\(([^\(\)]+)\)(.*)",y) ? Eval#(y1 . Eval@(y2) . y3) : Eval@(x)
}

Eval@(x) {  ; Evaluate expression with numbers, + #(subtract) / *
   RegExMatch(x,"(.*)(\+|#)(.*)",y)    ; last + or -
   IfEqual y2,+, Return Eval@(y1) + Eval@(y3)
   IfEqual y2,#, Return Eval@(y1) - Eval@(y3)

   RegExMatch(x,"(.*)(\*|/)(.*)",y)    ; last * or /
   IfEqual y2,*, Return Eval@(y1) * Eval@(y3)
   IfEqual y2,/, Return Eval@(y1) / Eval@(y3)

   Return x ? x : 0                    ; empty expression: 0, number: unchanged
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
