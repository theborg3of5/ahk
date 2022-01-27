#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location or DLG in EpicStudio. =--
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
;		ao := new ActionObjectEpicStudio("tagName^routineName")
;		MsgBox, ao.getLinkEdit() ; Link in EpicStudio
;		ao.openEdit()            ; Open in EpicStudio
;		
;		ao := new ActionObjectEpicStudio(123456) ; DLG ID
;		ao.openEdit() ; Open DLG in EpicStudio
	
*/ ; --=

class ActionObjectEpicStudio extends ActionObjectBase {
	; #PUBLIC#
	
	ActionObjectType := ActionObject.Type_EpicStudio
	
	; @GROUP@ Descriptor types
	static DescriptorType_Routine    := "ROUTINE" ; Server code location, including tag if applicable
	static DescriptorType_RoutineCDE := "ROUTINE_CDE" ; Server code location, including tag if applicable - in CDE
	static DescriptorType_DLG        := "DLG"     ; DLG, for opening in EpicStudio
	; @GROUP-END@
	
	; @GROUP@
	descriptor     := "" ; Reference to object
	descriptorType := "" ; Type of object (from DescriptorType_* constants)
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Create a new reference to a server code object.
	; PARAMETERS:
	;  descriptor     (I,REQ) - Value representing the object
	;  descriptorType (I,OPT) - Type of descriptor, from DescriptorType_* constants. If not given, we'll figure it out
	;                           based on the descriptor format or by prompting the user.
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
	; DESCRIPTION:    Get a link to the object (server code location or DLG) referenced by
	;                 descriptor in EpicStudio.
	; RETURNS:        Link to EpicStudio for the code location/DLG.
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
				
				url := Config.private["EPICSTUDIO_URL_BASE_ROUTINE"]
				url := url.replaceTag("ROUTINE",     routine)
				url := url.replaceTag("TAG",         tag)
				url := url.replaceTag("ENVIRONMENT", environmentId)
				
			Case this.DescriptorType_DLG:
				url := Config.private["EPICSTUDIO_URL_BASE_DLG"]
				url := url.replaceTag("DLG_ID", this.descriptor)
		}
		
		return url
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Try to figure out what kind of descriptor we've been given based on its format.
	; RETURNS:        Descriptor type from DescriptorType_* constants
	;---------
	determineDescriptorType() {
		; Full server tag^routine
		if(this.descriptor.contains("^"))
			return ActionObjectEpicStudio.DescriptorType_Routine
		
		; DLG IDs are (usually) entirely numeric, where routines are not.
		if(this.descriptor.isNum())
			return ActionObjectEpicStudio.DescriptorType_DLG
		
		return ""
	}
	; #END#
}
