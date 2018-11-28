; Data-structure-related functions.


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

; Array contains function. Returns index if it exists.
arrayContains(haystack, needle) {
	; DEBUG.popup("Hay", haystack, "Needle", needle)
	
	For i, el in haystack
		if(el = needle)
			return i
	
	return ""
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

arrayDropEmptyValues(inputAry) {
	outputAry := []
	For i,val in inputAry
		if(val != "")
			outputAry[i] := val
	
	return outputAry
}
