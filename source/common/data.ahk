; Data-structure-related functions.

isEmpty(obj) {
	return !obj.count() ; Either count() is defined (empty object/array) and returns 0, or it's not (and we get "").
}

; If the given object is already an array, return it. Otherwise, return an array with the given object as its only element (index 0).
forceArray(obj) {
	if(IsObject(obj))
		return obj
	
	newArray := []
	newArray.push(obj)
	return newArray
}

forceNumber(data) {
	if(data.isNum())
		return data
	return 0
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
mergeObjects(baseObject, overrides) {
	if(IsObject(baseObject))
		retAry := baseObject.clone()
	else
		retAry := {}
	
	For index,value in overrides {
		if(IsObject(value))
			retAry[index] := mergeObjects(baseObject[index], value)
		else
			retAry[index] := value
	}
	
	return retAry
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

; Only supports pseudo-arrays where the count is in the base variable (i.e. Var = 5, Var1-Var5 are the data elements).
; Note: you need to declare the pseudo-array's root as a global before calling this, otherwise we can't access the data there.
convertPseudoArrayToArray(pseudoArrayName) {
	resultAry := []
	Loop, % %pseudoArrayName% {
		itemName := pseudoArrayName A_Index
		resultAry.push(%itemName%)
	}
	
	return resultAry
}

convertObjectToArray(obj) {
	newArray := []
	For _,value in obj
		newArray.push(value)
	
	return newArray
}

; Expand lists that can optionally contain numeric ranges.
; Note that ranges with non-numeric values will be ignored (not included in the output array).
; Example:
;  1,2:3,7,6-4 -> [1, 2, 3, 7, 6, 5, 4]
expandList(listString) {
	elementAry := listString.split(",")
	outAry := []
	
	For _,element in elementAry {
		if(element.contains(":") || element.contains("-")) { ; Treat it as a numeric range and expand it
			rangeAry := expandNumericRange(element) ; If it's not numeric, this will return [] and we'll ignore that element entirely.
			outAry.appendArray(rangeAry)
		} else {
			outAry.push(element)
		}
	}
	
	return outAry
}

; Expands numeric ranges (i.e. 1:5 or 1-5 -> [1, 2, 3, 4, 5]).
expandNumericRange(rangeString) {
	splitAry := rangeString.split([":", "-"])
	start := splitAry[1]
	end   := splitAry[2]
	
	; Non-numeric ranges are not allowed.
	if(!start.isNum() || !end.isNum())
		return [rangeString]
	
	if(start = end)
		return [start] ; Single-element range
	
	if(start < end)
		step := 1
	else
		step := -1
	
	numElements := abs(end - start) + 1
	rangeAry := []
	currNum := start
	Loop, %numElements% {
		rangeAry.push(currNum)
		currNum += step
	}
	
	return rangeAry
}

; Bit field operations
bitFieldHasFlag(bitField, flag) {
	return (bitField & flag) > 0
}
bitFieldAddFlag(bitField, flag) {
	return (bitField | flag)
}
bitFieldRemoveFlag(bitField, flag) {
	return (bitField & ~flag)
}

numToInteger(num) {
	return Format("{1:i}", num)
}

numToHex(num) {
	return Format("{1:x}", num)
}

hexToInteger(num) {
	num := "0x" num
	return numToInteger(num)
}