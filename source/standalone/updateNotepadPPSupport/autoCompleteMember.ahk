; Represents a single class member that we want to add auto-complete info for.
class AutoCompleteMember {
	; #INTERNAL#
	
	name        := ""
	returns     := ""
	description := ""
	paramsAry   := []
	
	;---------
	; DESCRIPTION:    Create a new member.
	; PARAMETERS:
	;  headerLines   (I,REQ) - An array of lines making up the full header for this member.
	;  defLine       (I,OPT) - The definition line for the member - that is, its first line
	;                          (function definition, etc.). Ignored if there's a NPP-DEF-LINE line
	;                          in the header.
	;---------
	__New(headerLines, defLine := "") {
		this.handleHeader(headerLines, defLine) ; Can replace defLine based on header
		
		; Properties get special handling to call them out as properties (not functions), since you have to use an open paren to get the popup to display.
		if(!this.isFunction(defLine))
			this.returns := this.ReturnValue_Property
		
		; Extract info from the definition line
		AHKCodeLib.getDefLineParts(defLine, name, paramsAry)
		this.name      := name
		this.paramsAry := paramsAry
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this member.
	; PARAMETERS:
	;  className (I,OPT) - The class that this member belongs to.
	; RETURNS:        The XML for this member.
	;---------
	generateXML(className := "") {
		xml := this.BaseXML_Keyword
		
		xml := xml.replaceTag("FULL_NAME",   this.generateFullName(className))
		xml := xml.replaceTag("RETURNS",     this.returns)
		xml := xml.replaceTag("DESCRIPTION", this.description)
		xml := xml.replaceTag("PARAMS_XML",  this.generateParamsXML())
		
		return xml
	}
	
	
	; #PRIVATE#
	
	static ReturnValue_Property := "[Property]"
	; <PARAMS_XML> has no indent/newline so each line of the params can indent itself the same.
	; Always func="yes", because that allows us to get a popup with the info.
	static BaseXML_Keyword := "
		(
        <KeyWord name=""<FULL_NAME>"" func=""yes"">
            <Overload retVal=""<RETURNS>"" descr=""<DESCRIPTION>""><PARAMS_XML>
            </Overload>
        </KeyWord>
		)"
	static BaseXML_Param := "
		(
                <Param name=""<PARAM_NAME>"" />
		)"
	static Indent_Header := StringLib.getTabs(7) ; We can indent with tabs and it's ignored - cleaner XML and result looks the same.
	
	;---------
	; DESCRIPTION:    Go through the header and update this class as needed.
	; PARAMETERS:
	;  headerLines (I,REQ) - An array of header lines
	;  defLine     (O,REQ) - Will be replaced with a new definition line if one is defined in the
	;                        header (NPP-DEF-LINE).
	;---------
	handleHeader(headerLines, ByRef defLine) {
		; Check the header for any NPP-* overrides
		linesToDelete := []
		For ln,line in headerLines {
			line := line.removeFromStart("; ")
			if(line.startsWith("NPP-DEF-LINE:")) {
				linesToDelete.push(ln)
				defLine := line.removeFromStart("NPP-DEF-LINE:").withoutWhitespace()
			}
			if(line.startsWith("NPP-RETURNS:")) {
				linesToDelete.push(ln)
				retVal := line.removeFromStart("NPP-RETURNS:").withoutWhitespace()
				this.returns := this.returns.appendPiece(" ", retVal)
			}
		}
		; Remove the lines for the NPP-* overrides as well
		For _,ln in linesToDelete
			headerLines.delete(ln)
		
		; The description is the actual function header, indented nicely.
		this.description := this.formatHeaderAsDescription(headerLines)
	}
	
	;---------
	; DESCRIPTION:    Turn the array of documentation lines into a single, indented, XML-safe string.
	; PARAMETERS:
	;  headerLines (I,REQ) - An array of lines containing the header for this member.
	; RETURNS:        The header string to plug into the XML description for the member.
	;---------
	formatHeaderAsDescription(headerLines) {
		; Put the lines back together
		headerText := headerLines.join("`n")
		
		; Replace double-quotes with their XML-safe equivalent
		headerText := headerText.replace("""", "&quot;")
		
		; Add a newline at the start to separate the header from the definition line in the popup
		headerText := "`n" headerText
		
		; Indent the whole thing with tabs (which appear in the XML but are ignored in the popup)
		headerText := headerText.replace("`n", "`n" this.Indent_Header)
		
		return headerText
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given definition line represents a function, based on
	;                 whether it contains an open paren.
	; PARAMETERS:
	;  defLine (I,REQ) - The definition line
	; RETURNS:        true/false - is it a function?
	;---------
	isFunction(defLine) {
		; Strip off the first quote onward - by the time we hit a value or parameter default we should have already found an open paren.
		defLine := defLine.beforeString("""")
		
		; Strip off the first comment character onward - comments have no bearing here.
		defLine := defLine.beforeString(";")
		
		; If there's an open paren, it's a function.
		return defLine.contains("(")
	}
	
	;---------
	; DESCRIPTION:    Determine the full name of this member.
	; PARAMETERS:
	;  className (I,REQ) - The name of the class this member is part of.
	; RETURNS:        Either className.memberName, or just className for constructors.
	;---------
	generateFullName(className) {
		; Special case: constructors are just <className>
		if(this.name = "__New")
			return className
		
		; Full name is <class>.<member> or just <member> if no class
		if(className != "")
			return className "." this.name
		return this.name
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this member's parameters (if any).
	; RETURNS:        The generated XML
	;---------
	generateParamsXML() {
		if(DataLib.isNullOrEmpty(this.paramsAry))
			return ""
		
		paramsXML := ""
		For _,paramName in this.paramsAry {
			paramName := paramName.replace("""", "&quot;") ; Replace double-quotes with their XML-safe equivalent.
			xml := this.BaseXML_Param.replaceTag("PARAM_NAME", paramName)
			
			paramsXML .= "`n" xml ; Start with an extra newline to put the params block on a new line
		}
		
		return paramsXML
	}
	
	
	; #DEBUG#
	
	Debug_ToString(ByRef table) {
		table.addLine("Name",        this.name)
		table.addLine("Returns",     this.returns)
		table.addLine("Parameters",  this.paramsAry)
		table.addLine("Description", this.description)
	}
	; #END#
}
