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
mergeArrays(default, overrides) {
	if(IsObject(default))
		retAry := default.clone()
	else
		retAry := []
	
	For index,value in overrides {
		if(IsObject(value))
			retAry[index] := mergeArrays(default[index], value)
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

convertObjectToArray(obj) {
	newArray := []
	For _,value in obj
		newArray.push(value)
	
	return newArray
}

; Creates a new table (2D array) with the values of the old, but the rows are indexed by the value of a specific subscript in each row.
; Example:
;   Input:
;      {
;      	1          => {"A" => "HI",       "B" => "THERE"}
;      	2          => {"A" => "BYE",      "B" => "SIR"}
;      	3          => {"A" => "GOOD DAY", "B" => "MADAM"}
;      }
;   Output (with a given subscriptName of "A"):
;      {
;      	"BYE"      => {"A" => "BYE",      "B" => "SIR"}
;      	"GOOD DAY" => {"A" => "GOOD DAY", "B" => "MADAM"}
;      	"HI"       => {"A" => "HI",       "B" => "THERE"}
reIndexTableBySubscript(inputTable, subscriptName) {
	if(subscriptName = "")
		return ""
	
	outTable := []
	For _,row in inputTable {
		newIndex := row[subscriptName]
		if(newIndex = "") ; Throw out rows without a value for our new index.
			Continue
		
		outTable[newIndex] := row.clone()
	}
	
	return outTable
}

; Reduce a table to the value of a single column per row, indexed by the value of another column.
reduceTableToColumn(inputTable, valueColumn, indexColumn := "") {
	if(!inputTable || !valueColumn)
		return ""
	
	outTable := []
	For origIndex,row in inputTable {
		if(indexColumn != "")
			newIndex := row[indexColumn]
		else
			newIndex := origIndex
		
		if(newIndex = "") ; Throw out rows without a value for our new index.
			Continue
		
		outTable[newIndex] := row[valueColumn]
	}
	
	return outTable
}

; Expand lists that can optionally contain numeric ranges.
; Note that ranges with non-numeric values will be ignored (not included in the output array).
; Example:
;  1,2:3,7,6:4 -> [1, 2, 3, 7, 6, 5, 4]
expandList(listString) {
	elementAry := listString.split(",")
	outAry := []
	
	For _,element in elementAry {
		if(element.contains(":")) { ; Treat it as a numeric range and expand it
			rangeAry := expandNumericRange(element) ; If it's not numeric, this will return [] and we'll ignore that element entirely.
			outAry.appendArray(rangeAry)
		} else {
			outAry.push(element)
		}
	}
	
	return outAry
}

; Expands numeric ranges (i.e. 1:5 -> [1, 2, 3, 4, 5]).
expandNumericRange(rangeString) {
	splitAry := rangeString.split(":")
	start := splitAry[1]
	end   := splitAry[2]
	
	; Non-numeric ranges are not allowed.
	if(!start.isNum() || !end.isNum())
		return []
	
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