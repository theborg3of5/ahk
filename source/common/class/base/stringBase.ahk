/*
	Base class for strings to extend (technically for their base to extend), so we can add these functions directly to strings.
	
	Example usage:
		str := "abcd"
		result := str.contains("b") ; result = 2
*/

/*
	Do
		Functions to replace and remove
			stringContains	=>	.contains
*/

class StringBase {
	length() {
		return StrLen(this)
	}
	
	contains(needle, fromLastInstance := false) {
		if(fromLastInstance)
			return InStr(this, needle, , 0)
		else
			return InStr(this, needle)
	}
}