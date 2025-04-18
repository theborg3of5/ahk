#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location in VSCode/EpicCode.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectEpicCode("tagName^routineName")
;		MsgBox, ao.getLinkEdit() ; Link in EpicCode
;		ao.openEdit()            ; Open in EpicCode
	
*/

class ActionObjectEpicCode extends ActionObjectBase {
	;region ------------------------------ PUBLIC ------------------------------
	ActionObjectType := ActionObject.Type_EpicCode
	
	;region Descriptor types
	static DescriptorType_Routine    := "ROUTINE"     ; Server code location, including tag if applicable
	static DescriptorType_RoutineCDE := "ROUTINE_CDE" ; Server code location, including tag if applicable - in CDE
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
		; Full server tag^routine
		if(this.descriptor.contains("^"))
			return ActionObjectEpicCode.DescriptorType_Routine
		
		return ""
	}
	;endregion ------------------------------ PRIVATE ------------------------------
}
