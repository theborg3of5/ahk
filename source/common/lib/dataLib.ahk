; Data structure and manipulation functions.

class DataLib {
	;region ------------------------------ PUBLIC ------------------------------
	;---------
	; DESCRIPTION:    Check whether the given value is an array.
	; PARAMETERS:
	;  value (I,REQ) - Value to check
	; RETURNS:        true/false
	;---------
	static isArray(value) {
		return value is Array
	}

	;---------
	; DESCRIPTION:    Check whether the given value is a Map (associative array).
	; PARAMETERS:
	;  value (I,REQ) - Value to check
	; RETURNS:        true/false
	; NOTES:          If you just need to check whether something is an array or object vs. a simple value, just use the
	;                 built-in IsObject().
	;---------
	static isMap(value) {
		return value is Map
	}

	;---------
	; DESCRIPTION:    Determine whether the provided object is empty, also checking if it's null.
	; PARAMETERS:
	;  obj (I,REQ) - The object/array to check.
	; RETURNS:        true if the provided object is null (including "") or empty (no values inside), false otherwise.
	;---------
	static isNullOrEmpty(obj) {
		if obj is Array
			return obj.Length = 0
		if obj is Map
			return obj.Count = 0
		if IsObject(obj)
			return ObjOwnPropCount(obj) = 0
		return obj = ""
	}

	;---------
	; DESCRIPTION:    If the given object is already an array (or object) return it, otherwise turn it into one.
	; PARAMETERS:
	;  obj (I,REQ) - The object to force to be an array.
	; RETURNS:        An array (the obj parameter if it was one, or a new array with obj as the first and only value in it)
	;---------
	static forceArray(obj) {
		if IsObject(obj)
			return obj

		newArray := []
		newArray.Push(obj)
		return newArray
	}

	;---------
	; DESCRIPTION:    Force the given data to be a number.
	; PARAMETERS:
	;  data (I,REQ) - Data to force into a number.
	; RETURNS:        If it's already numeric, the number. Otherwise, 0.
	;---------
	static forceNumber(data) {
		if data.isNum()
			return data
		return 0
	}

	;---------
	; DESCRIPTION:    Find the first non-blank value from those given.
	; PARAMETERS:
	;  params* (I,REQ) - Variadic parameter - as many values as desired.
	; RETURNS:        The first non-blank value.
	;---------
	static coalesce(params*) {
		for _, param in params {
			if param != ""
				return param
		}
	}

	;---------
	; DESCRIPTION:    Find the numeric maximum of the given numbers.
	; PARAMETERS:
	;  numbers* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The numeric maximum of all given numbers.
	;---------
	static max(numbers*) {
		result := ""
		for i, n in numbers {
			if !n.isNum()
				continue
			if result = "" || n > result
				result := n
		}
		return result
	}

	;---------
	; DESCRIPTION:    Find the numeric minimum of the given numbers.
	; PARAMETERS:
	;  numbers* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The numeric minimum of all given numbers.
	;---------
	static min(numbers*) {
		result := ""
		for i, n in numbers {
			if !n.isNum()
				continue
			if result = "" || n < result
				result := n
		}
		return result
	}

	;---------
	; DESCRIPTION:    Find the numeric sum of all elements.
	; PARAMETERS:
	;  numbers* (I,REQ) - Variadic parameter - as many numbers as desired.
	; RETURNS:        The total of all elements
	; NOTES:          Any non-numeric indices will be treated as 0.
	;---------
	static sum(numbers*) {
		total := 0
		for _, n in numbers
			total += DataLib.forceNumber(n)
		return total
	}

	;---------
	; DESCRIPTION:    Wrapper for max() that updates the first parameter directly.
	; PARAMETERS:
	;  maxValue (IO,REQ) - The current maximum value. Will be updated if newValue is bigger.
	;  newValue  (I,REQ) - The new value to compare to the current maximum.
	;---------
	static updateMax(&maxValue, newValue) {
		maxValue := DataLib.max(maxValue, newValue)
	}

	;region Number conversions
	;---------
	; DESCRIPTION:    Convert the provided number into an integer.
	; PARAMETERS:
	;  num (I,REQ) - The number to convert
	; RETURNS:        The number as an integer.
	;---------
	static numToInteger(num) {
		return Format("{1:i}", num)
	}

	;---------
	; DESCRIPTION:    Convert the provided number into a hex code.
	; PARAMETERS:
	;  num (I,REQ) - The number to convert
	; RETURNS:        The number in hex format.
	;---------
	static numToHex(num) {
		return Format("{1:x}", num)
	}

	;---------
	; DESCRIPTION:    Convert a hex number to an integer.
	; PARAMETERS:
	;  hexNum (I,REQ) - The hex number to convert
	; RETURNS:        The hex number as an integer.
	;---------
	static hexToInteger(hexNum) {
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
	static bitFieldHasFlag(bitField, flag) {
		return (bitField & flag) > 0
	}
	;---------
	; DESCRIPTION:    Add a flag to a bitfield.
	; PARAMETERS:
	;  bitField (I,REQ) - The bitfield to update
	;  flag     (I,REQ) - The flag to add
	; RETURNS:        The resulting bitfield
	;---------
	static bitFieldAddFlag(bitField, flag) {
		return (bitField | flag)
	}
	;---------
	; DESCRIPTION:    Remove a flag from a bitfield.
	; PARAMETERS:
	;  bitField (I,REQ) - The bitfield to update
	;  flag     (I,REQ) - The flag to remove
	; RETURNS:        The resulting bitfield
	;---------
	static bitFieldRemoveFlag(bitField, flag) {
		return (bitField & ~flag)
	}
	;endregion Bitfield handling

	;---------
	; DESCRIPTION:    Convert an object to an array.
	; PARAMETERS:
	;  obj (I,REQ) - The object to convert
	; RETURNS:        The resulting array
	; NOTES:          The indices are added in the same order as a For/in loop.
	;---------
	static convertObjectToArray(obj) {
		newArray := []
		for _, value in obj
			newArray.Push(value)
		return newArray
	}

	;---------
	; DESCRIPTION:    Flatten an object (including any sub-objects) into a simple array.
	; PARAMETERS:
	;  objectToFlatten (I,REQ) - The object to base our new array on.
	; RETURNS:        An array containing all values from the object, in depth-first order.
	;---------
	static flattenObjectToArray(objectToFlatten) {
		if !IsObject(objectToFlatten)
			return objectToFlatten

		flatArray := []
		for _, prop in objectToFlatten {
			if IsObject(prop) {
				flatProp := this.flattenObjectToArray(prop)
				flatArray.appendArray(flatProp)
				continue
			}
			flatArray.Push(prop)
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
	static getPropertyFromArrayChildren(objectsAry, propertyName) {
		propertyValues := []
		for _, child in objectsAry
			propertyValues.Push(child[propertyName])
		return propertyValues
	}

	;---------
	; DESCRIPTION:    Sort the provided array of objects by the value of a given property inside those objects.
	; PARAMETERS:
	;  objectsAry   (I,REQ) - Array of objects to sort.
	;  propertyName (I,REQ) - Name of the property use for sorting.
	;  ascending    (I,OPT) - true for ascending order, false for descending. Defaults to ascending.
	; RETURNS:        Sorted array of objects
	;---------
	static sortArrayBySubProperty(objectsAry, propertyName, ascending := true) {
		objectsByProp := Map()

		for _, obj in objectsAry {
			propVal := obj[propertyName]
			if propVal = ""
				propVal := "<BLANK>"

			if !objectsByProp.Has(propVal)
				objectsByProp[propVal] := []

			objectsByProp[propVal].Push(obj)
		}

		aryByProp := DataLib.convertObjectToArray(objectsByProp)
		if !ascending
			aryByProp := DataLib.reverseArray(aryByProp)

		sortedAry := []
		for _, objectsWithValue in aryByProp {
			for _, obj in objectsWithValue {
				sortedAry.Push(obj)
			}
		}

		return sortedAry
	}

	;---------
	; DESCRIPTION:    Reverse the order of elements in the given array.
	; PARAMETERS:
	;  inputAry (I,REQ) - The array to reverse
	; RETURNS:        An array with the same elements, in reverse order.
	;---------
	static reverseArray(inputAry) {
		outputAry := []
		for _, el in inputAry
			outputAry.InsertAt(1, el)
		return outputAry
	}

	;---------
	; DESCRIPTION:    Force the give new value to be unique as compared to all already-existing values.
	; PARAMETERS:
	;  newValue  (I,REQ) - The new value we want to add.
	;  allValues (I,REQ) - An array of all values we've added so far, that the new value must be different from.
	; NOTES:          Counter is more string-based than truly numeric (I think we'll jump from 19 to 110).
	;---------
	static forceUniqueValue(newValue, allValues) {
		while allValues.contains(newValue) {
			lastChar := newValue.charAt(0)
			if lastChar.isNum() {
				newValue := newValue.removeFromEnd(lastChar)
				counter := lastChar + 1
			} else {
				counter := 2
			}
			newValue .= counter
		}
		allValues.Push(newValue)
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
	static expandList(listString) {
		elementAry := listString.split(",")
		outAry := []

		for _, element in elementAry {
			if element.contains(":") || element.contains("-") {
				rangeAry := DataLib.expandNumericRange(element)
				outAry.appendArray(rangeAry)
			} else {
				outAry.Push(element)
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
	static expandNumericRange(rangeString) {
		DataLib.getNumericRangeBits(rangeString, &start, &step, &end)

		if !start.isNum() || !end.isNum()
			return [rangeString]

		if start = end
			return [start]

		numElements := (Abs(end - start) // Abs(step)) + 1
		rangeAry := []
		currNum := start
		Loop numElements {
			rangeAry.Push(currNum)
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
	static getNumericRangeBits(rangeString, &start, &step, &end) {
		if rangeString.contains(":") {
			splitAry := rangeString.split(":")
			start := splitAry[1]
			step  := splitAry[2]
			end   := splitAry[3]

			if end = "" {
				end := step
				step := ""
			}

			if end.startsWith("+")
				end := start + end.removeFromStart("+")
			else if end.startsWith("-")
				end := start - end.removeFromStart("-")
		}

		if rangeString.contains("-") {
			splitAry := rangeString.split("-")
			start := splitAry[1]
			step  := 1
			end   := splitAry[2]
		}

		if end.startsWith("*") {
			suffix := end.afterString("*", true)
			end := start.slice(1, StrLen(start) - StrLen(suffix) + 1) suffix
		}

		if step = "" || step = 0
			step := 1
		if start < end
			step := Abs(step)
		else
			step := Abs(step) * -1
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
