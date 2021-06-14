; Represents an entire class that we want to add auto-complete info for.
class AutoCompleteClass {
	; #INTERNAL#
	
	name       := "" ; The class' name
	parentName := "" ; The name of the class' parent (if it extends another class)
	group      := "" ; The group (used for syntax highlighting)
	members    := {} ; {.memberName: AutoCompleteMember}
	
	;---------
	; DESCRIPTION:    Create a new class representation.
	; PARAMETERS:
	;  defLine (I,REQ) - The definition line for the class - the one that starts with "class ".
	;  group   (I,REQ) - The group this class should be part of, for syntax highlighting purposes.
	;---------
	__New(defLine, group) {
		this.name := defLine.firstBetweenStrings("class ", " ") ; Break on space instead of end bracket so we don't end up including the "extends" bit for child classes.
		if(defLine.contains(" extends "))
			this.parentName := defLine.firstBetweenStrings(" extends ", " {")
		
		this.group := group
	}
	
	;---------
	; DESCRIPTION:    Add the given member to this class.
	; PARAMETERS:
	;  member (I,REQ) - The member to add.
	;---------
	addMember(member) {
		if(member.name = "")
			return
		
		dotName := "." member.name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
		this.members[dotName] := member
	}
	;---------
	; DESCRIPTION:    Add the given member to this class, but only if a member with the same name
	;                 doesn't already exist.
	; PARAMETERS:
	;  member (I,REQ) - The member to add.
	;---------
	addMemberIfNew(member) {
		if(member.name = "")
			return
		
		dotName := "." member.name ; The index is the name with a preceding dot - otherwise we start overwriting things like <array>.contains with this array, and that breaks stuff.
		if(this.members.HasKey(dotName))
			return
		
		this.members[dotName] := member
	}
	
	;---------
	; DESCRIPTION:    Get the member with the given name.
	; PARAMETERS:
	;  name (I,REQ) - The name of the member to retrieve.
	; RETURNS:        An AutoCompleteMember instance representing the member.
	;---------
	getMember(name) {
		dotName := "." name
		return this.members[dotName]
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this class and all of its members.
	; RETURNS:        The generated XML
	;---------
	generateXML() {
		xml := ""
		For _,member in this.members
			xml := xml.appendLine(member.generateXML(this.name))
		return xml
	}
	; #END#
}
