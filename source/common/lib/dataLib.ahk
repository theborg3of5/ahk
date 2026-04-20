; Data structure and manipulation functions.

class DataLib {
	;region ------------------------------ PUBLIC ------------------------------
	static isArray(value) {
		return value is Array
	}

	static isMap(value) {
		return value is Map
	}

	static isNullOrEmpty(obj) {
		if obj is Array
			return obj.Length = 0
		if obj is Map
			return obj.Count = 0
		if IsObject(obj)
			return ObjOwnPropCount(obj) = 0
		return obj = ""
	}

	static forceArray(obj) {
		if IsObject(obj)
			return obj

		newArray := []
		newArray.Push(obj)
		return newArray
	}

	static forceNumber(data) {
		if data.isNum()
			return data
		return 0
	}

	static coalesce(params*) {
		for _, param in params {
			if param != ""
				return param
		}
	}

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

	static sum(numbers*) {
		total := 0
		for _, n in numbers
			total += DataLib.forceNumber(n)
		return total
	}

	static updateMax(&maxValue, newValue) {
		maxValue := DataLib.max(maxValue, newValue)
	}

	;region Number conversions
	static numToInteger(num) {
		return Format("{1:i}", num)
	}

	static numToHex(num) {
		return Format("{1:x}", num)
	}

	static hexToInteger(hexNum) {
		hexNum := "0x" hexNum
		return DataLib.numToInteger(hexNum)
	}
	;endregion Number conversions

	;region Bitfield handling
	static bitFieldHasFlag(bitField, flag) {
		return (bitField & flag) > 0
	}

	static bitFieldAddFlag(bitField, flag) {
		return (bitField | flag)
	}

	static bitFieldRemoveFlag(bitField, flag) {
		return (bitField & ~flag)
	}
	;endregion Bitfield handling

	static convertObjectToArray(obj) {
		newArray := []
		for _, value in obj
			newArray.Push(value)
		return newArray
	}

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

	static getPropertyFromArrayChildren(objectsAry, propertyName) {
		propertyValues := []
		for _, child in objectsAry
			propertyValues.Push(child[propertyName])
		return propertyValues
	}

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

	static reverseArray(inputAry) {
		outputAry := []
		for _, el in inputAry
			outputAry.InsertAt(1, el)
		return outputAry
	}

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
