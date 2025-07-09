#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location in VSCode/EpicCode.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectEpicCode("tagName^routineName")
;		MsgBox, ao.getLinkEdit() ; Link in EpicCode
;		ao.openEdit()            ; Open in EpicCode
;		
;		ao := new ActionObjectEpicCode(123456) ; DLG ID
;		ao.openEdit() ; Open DLG in EpicCode
	
*/

class ActionObjectEpicCode extends ActionObjectBase {
	;region ------------------------------ PUBLIC ------------------------------
	ActionObjectType := ActionObject.Type_EpicCode
	
	;region Descriptor types
	static DescriptorType_Routine    := "ROUTINE"     ; Server code location, including tag if applicable
	static DescriptorType_RoutineCDE := "ROUTINE_CDE" ; Server code location, including tag if applicable - in CDE
	static DescriptorType_Global     := "GLOBAL"      ; Global (in DBC Dev)
	static DescriptorType_GlobalCDE  := "GLOBAL_CDE"  ; Global (in CDE)
	static DescriptorType_DLG        := "DLG"         ; DLG, for opening in EpicCode
	;endregion Descriptor types
	
	descriptor     := "" ; Reference to object
	descriptorType := "" ; Type of object (from DescriptorType_* constants)
	
	;---------
	; DESCRIPTION:    Create a new reference to a server code object.
	; PARAMETERS:
	;  descriptor     (I,REQ) - Value representing the object
	;  descriptorType (I,OPT) - Type of descriptor, from DescriptorType_* constants. If not given, we'll
	;                           figure it out based on the descriptor format or by prompting the user.
	;---------
	__New(descriptor, descriptorType := "") {
		if(descriptorType = "")
			descriptorType := this.determineDescriptorType()
		
		if(!this.selectMissingInfo(descriptor, descriptorType))
			return ""
		
		this.descriptor     := descriptor
		this.descriptorType := descriptorType
	}
	
	;---------
	; DESCRIPTION:    Determine whether the given string must be this type of ActionObject.
	; PARAMETERS:
	;  value          (I,REQ) - The value to evaluate
	;  descriptorType (O,OPT) - If the value is an EpicCode object, the type of descriptor (from ActionObjectEpicCode.DescriptorType_*)
	;  id             (O,OPT) - If the value is an EpicCode object, the ID
	; RETURNS:        true/false - whether the given value must be an EpicCode object.
	;---------
	isThisType(value, ByRef descriptorType := "", ByRef id := "") {
		if(!Config.contextIsWork)
			return false
		
		if(value.startsWith("G ")) {
			descriptorType := this.DescriptorType_Global
			id := value.removeFromStart("G ") ; Remove "G " prefix
			return true
		}
		
		return false
	}
	
	;---------
	; DESCRIPTION:    Get a link to the object (server code location) referenced by descriptor in EpicCode.
	; RETURNS:        Link to EpicCode for the code location.
	;---------
	getLink() {
		url := ""
		
		Switch this.descriptorType {
			Case this.DescriptorType_Routine, this.DescriptorType_RoutineCDE:
				EpicLib.splitServerLocation(this.descriptor, routine, tag)
				
				if(this.descriptorType = this.DescriptorType_Routine)
					environmentId := Config.private["DBC_DEV_ENV_ID"]
				else if(this.descriptorType = this.DescriptorType_RoutineCDE)
					environmentId := Config.private["CDE_ENV_ID"]
				
				url := Config.private["EPICCODE_URL_BASE_ROUTINE"]
				url := url.replaceTag("ROUTINE",     routine)
				url := url.replaceTag("TAG",         tag)
				url := url.replaceTag("ENVIRONMENT", environmentId)
				
			Case this.DescriptorType_Global, this.DescriptorType_GlobalCDE:
				globalName := this.descriptor.removeFromStart("G ") ; Remove "G " prefix if present
				globalName := globalName.prependIfMissing("^") ; Leading caret is required for global names
				
				if(this.descriptorType = this.DescriptorType_Global)
					environmentId := Config.private["DBC_DEV_ENV_ID"]
				else if(this.descriptorType = this.DescriptorType_GlobalCDE)
					environmentId := Config.private["CDE_ENV_ID"]
				
				url := Config.private["EPICCODE_URL_BASE_GLOBAL"]
				url := url.replaceTag("GLONAME",        globalName)
				url := url.replaceTag("ENVIRONMENT", environmentId)
				
			Case this.DescriptorType_DLG:
				url := Config.private["EPICCODE_URL_BASE_DLG"]
				url := url.replaceTag("DLG_ID", this.descriptor)
		}
		
		return url
	}
	;endregion ------------------------------ PUBLIC ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	;---------
	; DESCRIPTION:    Try to figure out what kind of descriptor we've been given based on its format.
	; RETURNS:        Descriptor type from DescriptorType_* constants
	;---------
	determineDescriptorType() {
		; Full server tag^routine (at least one character before/after caret)
		if(this.descriptor.sub(2, -1).contains("^"))
			return ActionObjectEpicCode.DescriptorType_Routine
		
		; DLG IDs are (mostly) numeric, where routines are not.
		if(EpicLib.couldBeEMC2ID(this.descriptor))
			return ActionObjectEpicCode.DescriptorType_DLG

		; Allow a "G" prefix for globals, e.g. "G ^globalName" or "G globalName"
		if(this.descriptor.startsWith("G "))
			return ActionObjectEpicCode.DescriptorType_Global
		
		return ""
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
