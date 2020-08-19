; Data structure and manipulation functions.

class DataLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Determine whether the provided object is empty, also checking if it's null.
	; PARAMETERS:
	;  obj (I,REQ) - The object/array to check.
	; RETURNS:        true if the provided object is null (including "") or empty (no values inside), false otherwise.
	;---------
	isNullOrEmpty(obj) {
		; All objects/arrays should have a count() function we can check.
		if(IsObject(obj))
			return (obj.count() = 0)
		
		; Handling for strings
		return (obj = "")
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
	; DESCRIPTION:    Find the first non-blank value from those given.
	; PARAMETERS:
	;  params* (I,REQ) - Variadic parameter - as many values as desired.
	; RETURNS:        The first non-blank value.
	;---------
	firstNonBlankValue(params*) {
		For _,param in params {
			if(param != "")
				return param
		}
	}
	
	;---------
	; DESCRIPTION:    Find the numeric maximum of the given numbers.
	; PARAMETERS:
	;  nums* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The numeric maximum of all given numbers.
	;---------
	max(nums*) {
		; Debug.popup("Max", "Start", "Nums", nums)
		max := nums[1]
		For i,n in nums {
			if(!n.isNum()) ; Ignore non-numeric values
				Continue
			
			if((max = "") || (max < n))
				max := n
		}
		
		return max
	}
	
	;---------
	; DESCRIPTION:    Find the numeric sum of all elements.
	; PARAMETERS:
	;  nums* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The total of all elements
	; NOTES:          Any non-numeric indices will be treated as 0.
	;---------
	sum(nums*) {
		total := 0
		For _,n in nums
			total += DataLib.forceNumber(n)
		return total
	}
	
	;---------
	; DESCRIPTION:    Wrapper for max() that updates the first parameter directly.
	; PARAMETERS:
	;  maxValue (IO,REQ) - The current maximum value. Will be updated if newValue is bigger.
	;  newValue  (I,REQ) - The new value to compare to the current maximum.
	;---------
	updateMax(ByRef maxValue, newValue) {
		maxValue := DataLib.max(maxValue, newValue)
	}
	
	;---------
	; DESCRIPTION:    Convert the provided number into an integer.
	; PARAMETERS:
	;  num (I,REQ) - The number to convert
	; RETURNS:        The number as an integer.
	;---------
	numToInteger(num) {
		return Format("{1:i}", num)
	}
	
	;---------
	; DESCRIPTION:    Convert the provided number into a hex code.
	; PARAMETERS:
	;  num (I,REQ) - The number to convert
	; RETURNS:        The number in hex format.
	;---------
	numToHex(num) {
		return Format("{1:x}", num)
	}
	
	;---------
	; DESCRIPTION:    Convert a hex number to an integer.
	; PARAMETERS:
	;  hexNum (I,REQ) - The hex number to convert
	; RETURNS:        The hex number as an integer.
	;---------
	hexToInteger(hexNum) {
		hexNum := "0x" hexNum
		return DataLib.numToInteger(hexNum)
	}
	
	;---------
	; DESCRIPTION:    Check for a particular flag in a bitfield.
	; PARAMETERS:
	;  bitField (I,REQ) - The bitfield to check within
	;  flag     (I,REQ) - The flag to check
	; RETURNS:        true/false
	;---------
	bitFieldHasFlag(bitField, flag) {
		return (bitField & flag) > 0
	}
	;---------
	; DESCRIPTION:    Add a flag to a bitfield.
	; PARAMETERS:
	;  bitField (I,REQ) - The bitfield to update
	;  flag     (I,REQ) - The flag to add
	; RETURNS:        The resulting bitfield
	;---------
	bitFieldAddFlag(bitField, flag) {
		return (bitField | flag)
	}
	;---------
	; DESCRIPTION:    Remove a flag from a bitfield.
	; PARAMETERS:
	;  bitField (I,REQ) - The bitfield to update
	;  flag     (I,REQ) - The flag to remove
	; RETURNS:        The resulting bitfield
	;---------
	bitFieldRemoveFlag(bitField, flag) {
		return (bitField & ~flag)
	}
	
	;---------
	; DESCRIPTION:    Convert a pseudo-array into an actual array.
	; PARAMETERS:
	;  pseudoArrayName (I,REQ) - The name of the pseudo-array. This must be declared as a global prior
	;                            to calling this function.
	; RETURNS:        The resulting array
	; NOTES:          This only supports pseudo-arrays where the count is in the base variable
	;                 (i.e. Var = 5, Var1 is the first element, etc.)
	;---------
	convertPseudoArrayToArray(pseudoArrayName) {
		resultAry := []
		Loop, % %pseudoArrayName% {
			itemName := pseudoArrayName A_Index
			resultAry.push(%itemName%)
		}
		
		return resultAry
	}
	
	;---------
	; DESCRIPTION:    Convert an object to an array.
	; PARAMETERS:
	;  obj (I,REQ) - The object to convert
	; RETURNS:        The resulting array
	; NOTES:          The indices are added in the same order as a For/in loop.
	;---------
	convertObjectToArray(obj) {
		newArray := []
		For _,value in obj
			newArray.push(value)
		
		return newArray
	}
	
	;---------
	; DESCRIPTION:    Flatten an object (including any sub-objects) into a simple array.
	; PARAMETERS:
	;  objectToFlatten (I,REQ) - The object to base our new array on.
	; RETURNS:        An array containing all values from the object, in depth-first order.
	;---------
	flattenObjectToArray(objectToFlatten) {
		if(!isObject(objectToFlatten))
			return objectToFlatten
		
		flatArray := []
		For _,prop in objectToFlatten {
			; If the property is also an object, flatten that and merge it in.
			if(isObject(prop)) {
				flatProp := this.flattenObjectToArray(prop)
				flatArray.appendArray(flatProp)
				Continue
			}
			
			flatArray.push(prop)
		}
		
		return flatArray
	}
	
	;---------
	; DESCRIPTION:    Variadic parameter arrays don't have the same base array as those created
	;                 with [], which means they can't handle things like .contains() - this
	;                 returns an identical version that does.
	; PARAMETERS:
	;  paramAry (I,REQ) - The parameter array (from a parameter ending with * in the function's
	;                     definition line), to fix.
	; RETURNS:        An array with the same values that uses the shared base object.
	;---------
	rebaseVariadicAry(paramAry) {
		return Array(paramAry*)
	}
	
	;---------
	; DESCRIPTION:    Expand lists that can optionally contain numeric ranges (delimited by either
	;                 colons or hyphens). For example:
	;                  1,2:3,7,6-4 => [1, 2, 3, 7, 6, 5, 4]
	; PARAMETERS:
	;  listString (I,REQ) - The list to expand.
	; RETURNS:        The resulting array of expanded values.
	; NOTES:          Ranges with non-numeric values will be ignored (not included in the output array).
	;---------
	expandList(listString) {
		elementAry := listString.split(",")
		outAry := []
		
		For _,element in elementAry {
			if(element.contains(":") || element.contains("-")) { ; Treat it as a numeric range and expand it
				rangeAry := DataLib.expandNumericRange(element) ; If it's not numeric, this will return [] and we'll ignore that element entirely.
				outAry.appendArray(rangeAry)
			} else {
				outAry.push(element)
			}
		}
		
		return outAry
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Expand a numeric range that's delimited by either a colon or a hyphen. For example:
	;                  1:5 or 1-5 => [1, 2, 3, 4, 5]
	; PARAMETERS:
	;  rangeString (I,REQ) - The range to expand
	; RETURNS:        The resulting array of numbers.
	;---------
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
	; #END#
}
