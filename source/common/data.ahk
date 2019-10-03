; Data-structure-related functions.

;---------
; DESCRIPTION:    Determine whether the provided object/array is empty, also checking if it's null.
; PARAMETERS:
;  obj (I,REQ) - The object/array to check.
; RETURNS:        true if the provided object is null (including "") or empty (no values inside), false otherwise.
;---------
isNullOrEmpty(obj) {
	return !obj.count() ; Either count() is defined (empty object/array) and returns 0, or it's not (and we get "").
}

;---------
; DESCRIPTION:    If the given object is already an array (or object) return it, otherwise turn it into one.
; PARAMETERS:
;  obj (I,REQ) - The object to force to be an array.
; RETURNS:        An array (the obj parameter if it was one, or a new array with obj as the first and only value in it)
;---------
forceArray(obj) {
	if(IsObject(obj))
		return obj
	
	newArray := []
	newArray.push(obj)
	return newArray
}

;---------
; DESCRIPTION:    Force the given data to be a number.
; PARAMETERS:
;  data (I,REQ) - Data to force into a number.
; RETURNS:        If it's already numeric, the number. Otherwise, 0.
;---------
forceNumber(data) {
	if(data.isNum())
		return data
	return 0
}

;---------
; DESCRIPTION:    Find the numberic maximum of the given numbers.
; PARAMETERS:
;  nums* (I,REQ) - Variadic parameter - as many numbers as desired.
; RETURNS:        The numeric maximum of all given numbers.
;---------
max(nums*) {
	; DEBUG.popup("Max", "Start", "Nums", nums)
	max := nums[1]
	For i,n in nums {
		if(!n.isNum()) ; Ignore non-numeric values
			Continue
		
		if((max = "") || (max < n))
			max := n
	}
	
	return max
}

; First non-blank value of the arguments
firstNonBlankValue(params*) {
	For _,param in params {
		if(param != "")
			return param
	}
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
