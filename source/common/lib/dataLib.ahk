; Data structure and manipulation functions.

class DataLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Check whether the given value is an array, by checking whether its base class is ArrayBase (set in
	;                 this script library in arrayBase.ahk).
	; PARAMETERS:
	;  value (I,REQ) - Value to check
	; RETURNS:        true/false
	;---------
	isArray(value) {
		return value.__Class = "ArrayBase"
	}
	
	;---------
	; DESCRIPTION:    Check whether the given value is an object (versus an array), by checking whether its base class is
	;                 ObjectBase (set in this script library in objectBase.ahk).
	; PARAMETERS:
	;  value (I,REQ) - Value to check
	; RETURNS:        true/false
	; NOTES:          If you just need to check whether something is an array or object vs. a simple value, just use the
	;                 built-in IsObject().
	;---------
	isObject(value) {
		return value.__Class = "ObjectBase"
	}
	
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
	coalesce(params*) {
		For _,param in params {
			if(param != "")
				return param
		}
	}
	
	;---------
	; DESCRIPTION:    Find the numeric maximum of the given numbers.
	; PARAMETERS:
	;  numbers* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The numeric maximum of all given numbers.
	;---------
	max(numbers*) {
		; Debug.popup("Max", "Start", "Numbers", numbers)
		For i,n in numbers {
			if(!n.isNum()) ; Ignore non-numeric values
				Continue
			
			if((max = "") || (n > max))
				max := n
		}
		
		return max
	}
	
	;---------
	; DESCRIPTION:    Find the numeric minimum of the given numbers.
	; PARAMETERS:
	;  numbers* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The numeric minimum of all given numbers.
	;---------
	min(numbers*) {
		; Debug.popup("Min", "Start", "Numbers", numbers)
		For i,n in numbers {
			if(!n.isNum()) ; Ignore non-numeric values
				Continue
			
			if((min = "") || (n < min))
				min := n
		}
		
		return min
	}
	
	;---------
	; DESCRIPTION:    Find the numeric sum of all elements.
	; PARAMETERS:
	;  numbers* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The total of all elements
	; NOTES:          Any non-numeric indices will be treated as 0.
	;---------
	sum(numbers*) {
		total := 0
		For _,n in numbers
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
	
	;region Number conversions
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
	;endregion Number conversions
	
	;region Bitfield handling
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
	;endregion Bitfield handling
	
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
	; DESCRIPTION:    Get a property value from all objects in a given array.
	; PARAMETERS:
	;  objectsAry   (I,REQ) - Array of objects.
	;  propertyName (I,REQ) - Name of the property to get.
	; RETURNS:        Array of found property values (including blanks).
	;---------
	getPropertyFromArrayChildren(objectsAry, propertyName) {
		propertyValues := []
		
		For _,child in objectsAry
			propertyValues.push(child[propertyName])
		
		return propertyValues
	}

	;---------
	; DESCRIPTION:    Sort the provided array of objects by the value of a given property inside those objects.	; DESCRIPTION:    Sort the provided array of objects by the value of a given property inside those objects.
	; PARAMETERS:
	;  objectsAry   (I,REQ) - Array of objects to sort.
	;  propertyName (I,REQ) - Name of the property use for sorting.
	;  ascending    (I,OPT) - true for ascending order, false for descending. Defaults to ascending.
	; RETURNS:        Sorted array of objects
	;---------
	sortArrayBySubProperty(objectsAry, propertyName, ascending := true) {
		objectsByProp := {} ; { propVal: [obj1, obj2, ...] }

		For _, obj in objectsAry {
			propVal := obj[propertyName]
			if (propVal = "")
				propVal := "<BLANK>"

			if (!objectsByProp[propVal])
				objectsByProp[propVal] := []

			objectsByProp[propVal].push(obj)
		}

		aryByProp := DataLib.convertObjectToArray(objectsByProp) ; Builds array in ascending order
		if (!ascending)
			aryByProp := DataLib.reverseArray(aryByProp)
		
		sortedAry := []
		For _, objectsWithValue in aryByProp {
			For _, obj in objectsWithValue {
				sortedAry.push(obj)
			}
		}
		
		; Debug.popup("objectsAry",objectsAry, "objectsByProp",objectsByProp, "aryByProp",aryByProp, "sortedAry",sortedAry)
		return sortedAry
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
	; DESCRIPTION:    Reverse the order of elements in the given array.
	; PARAMETERS:
	;  inputAry (I,REQ) - The array to reverse
	; RETURNS:        An array with the same elements, in reverse order.
	;---------
	reverseArray(inputAry) {
		outputAry := []
		
		For _,el in inputAry
			outputAry.insertAt(1, el)

		return outputAry
	}

	;---------
	; DESCRIPTION:    Force the give new value to be unique as compared to all already-existing values.
	; PARAMETERS:
	;  newValue  (I,REQ) - The new value we want to add.
	;  allValues (I,REQ) - An array of all values we've added so far, that the new value must be different from.
	; NOTES:          Counter is more string-based than truly numeric (I think we'll jump from 19 to 110).
	;---------
	forceUniqueValue(newValue, allValues) {
		; Add a counter to the new value if needed.
		while(allValues.contains(newValue)) {
			lastChar := newValue.charAt(0)
			if(lastChar.isNum()) {
				newValue := newValue.removeFromEnd(lastChar)
				counter := lastChar + 1
			} else {
				counter := 2 ; If the last character isn't a number, just add 2 to the end.
			}
			newValue .= counter
		}
		allValues.push(newValue)

		return newValue
	}
	
	;---------
	; DESCRIPTION:    Expand comma-separated lists that can optionally contain numeric ranges.
	;                 The ranges can be delimited by colons or hypens and can include other advanced operators (+/-/*, see getNumericRangeBits). Examples:
	;                 	1:3			=> [1, 2, 3]
	;                 	6-4			=> [6, 5, 4]
	;                 	1:2:7		=> [1, 3, 5, 7]
	;                 	5:1:+6		=> [5, 6, 7, 8, 9, 10, 11]
	;                 	130:5:*45	=> [130, 135, 140, 145]
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
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	;---------
	; DESCRIPTION:    Expand a numeric range that's delimited by either colon(s) or a hyphen. Supported formats:
	;                 	start-end
	;                 	start:[step:]end
	;                 See getNumericRangeBits for details.
	; PARAMETERS:
	;  rangeString (I,REQ) - The range to expand
	; RETURNS:        The resulting array of numbers.
	;---------
	expandNumericRange(rangeString) {
		DataLib.getNumericRangeBits(rangeString, start, step, end)
		
		; Non-numeric ranges are not allowed.
		if(!start.isNum() || !end.isNum())
			return [rangeString]

		; Special case: single-element range
		if(start = end)
			return [start] ; Single-element range
		
		numElements := (abs(end - start) // abs(step)) + 1
		rangeAry := []
		currNum := start
		Loop, %numElements% {
			rangeAry.push(currNum)
			currNum += step
		}
		
		return rangeAry
	}

	;---------
	; DESCRIPTION:    Pick out the parts of a potential numeric range.
	;                 	Supported formats:
	;                 		start-end
	;                 		start:[step:]end
	;                 	Pieces:
	;                 		start	- Numeric start of the range.
	;                 		step	- How much to increment each time. Defaults to 1.
	;                 					step direction is always calculated based on start/end (positive if begin is smaller than end, etc.)
	;                 		end		- Any of:
	;                 					numeric		- Just a number
	;                 					[+/-]num	- (not supported for hyphenated ranges) start +/- a number (+5 to specify start+5)
	;                 					*num		- Replace the last few digits of start with the new one (*53 will be start with its last two digits replaced with 53)
	; PARAMETERS:
	;  rangeString  (I,REQ) - The string representing the range.
	;  start       (IO,REQ) - The numeric start of the range.
	;  step        (IO,REQ) - The step (increment/decrement value).
	;  end         (IO,REQ) - The numeric end of the range (inclusive).
	;---------
	getNumericRangeBits(rangeString, ByRef start, ByRef step, ByRef end) {
		; Advanced support for colon ranges: start:[step:]end
		if(rangeString.contains(":")) {
			splitAry := rangeString.split(":")
			start := splitAry[1]
			step  := splitAry[2]
			end   := splitAry[3]

			; If there's only 2 parts then the second part is actually the end.
			if(end = "") {
				end := step
				step := ""
			}

			; End can start with a +/- to be relative to the start.
			if(end.startsWith("+"))
				end := start + end.removeFromStart("+")
			else if(end.startsWith("-"))
				end := start - end.removeFromStart("-")
		}
		
		; Basic support for hyphenated range: start-end
		if (rangeString.contains("-")) {
			splitAry := rangeString.split("-")
			start := splitAry[1]
			step  := 1 ; We don't support a step value for hyphenated ranges, only start/end.
			end   := splitAry[2]
		}
		
		; End can also start with * to mean "replace the end of start with these numbers", i.e. 220:1:*35 => 220:1:235
		if(end.startsWith("*")) {
			suffix := end.afterString("*", true)
			end := start.slice(1, start.length() - suffix.length() + 1) suffix
		}
		
		; Default step is 1 (direction determined below)
		if( (step = "") || (step = 0) )
			step := 1
		; Determine step direction based on start/end
		if(start < end)
			step := abs(step)
		else
			step := abs(step) * -1
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
