#Include ..\base\actionObjectBase.ahk

/* Class for performing actions based on a code location or DLG in EpicStudio.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectEpicStudio("tagName^routineName")
		MsgBox, ao.getLinkEdit() ; Link in EpicStudio
		ao.openEdit()            ; Open in EpicStudio
		
		ao := new ActionObjectEpicStudio(123456) ; DLG ID
		ao.openEdit() ; Open DLG in EpicStudio
*/

class ActionObjectEpicStudio extends ActionObjectBase {

; ====================================================================================================
; ============================================== PUBLIC ==============================================
; ====================================================================================================
	
	static DescriptorType_Routine := "ROUTINE" ; Server code location, including tag if applicable
	static DescriptorType_DLG     := "DLG"     ; DLG, for opening in EpicStudio
	
	descriptor     := "" ; Reference to object
	descriptorType := "" ; Type of object (from DescriptorType_* constants)
	
	;---------
	; DESCRIPTION:    Create a new reference to a server code object.
	; PARAMETERS:
	;  descriptor     (I,REQ) - Value representing the object
	;  descriptorType (I,OPT) - Type of descriptor, from DescriptorType_* constants. If not given, we'll figure it out
	;                           based on the descriptor format or by prompting the user.
	;---------
	__New(descriptor, descriptorType := "") {
		this.descriptor     := descriptor
		this.descriptorType := descriptorType
		
		if(this.descriptorType = "")
			this.descriptorType := this.determineDescriptorType()
		
		if(!this.selectMissingInfo())
			return ""
	}
	
	;---------
	; DESCRIPTION:    Get a link to the object (server code location or DLG) referenced by
	;                 descriptor in EpicStudio.
	; RETURNS:        Link to EpicStudio for the code location/DLG.
	; NOTES:          There's no web vs. edit version for this, so here's a generic tag that the
	;                 others redirect to.
	;---------
	getLink() {
		if(this.descriptorType = ActionObjectEpicStudio.DescriptorType_Routine) {
			EpicLib.splitServerLocation(this.descriptor, routine, tag)
			environmentId := Config.private["DBC_DEV_ENV_ID"] ; Always use DBC Dev environment
			
			url := Config.private["EPICSTUDIO_URL_BASE_ROUTINE"]
			url := url.replaceTag("ROUTINE",     routine)
			url := url.replaceTag("TAG",         tag)
			url := url.replaceTag("ENVIRONMENT", environmentId)
			
			return url
		}
		
		if(this.descriptorType = ActionObjectEpicStudio.DescriptorType_DLG) {
			url := Config.private["EPICSTUDIO_URL_BASE_DLG"]
			url := url.replaceTag("DLG_ID", this.descriptor)
			return url
		}
		
		return ""
	}
	getLinkWeb() {
		return this.getLink()
	}
	getLinkEdit() {
		return this.getLink()
	}
	
	
; ====================================================================================================
; ============================================== PRIVATE =============================================
; ====================================================================================================
	
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
	
	;---------
	; DESCRIPTION:    Prompt the user for the descriptor type or descriptor if either are missing.
	; SIDE EFFECTS:   Sets .descriptorType/.descriptor based on user inputs.
	;---------
	selectMissingInfo() {
		; Nothing is missing
		if(this.descriptor != "" && this.descriptorType != "")
			return true
		
		s := new Selector("actionObject.tls").SetDefaultOverrides({"VALUE":this.descriptor})
		s.dataTL.filterByColumn("TYPE", ActionObjectRedirector.Type_EpicStudio)
		data := s.selectGui()
		if(!data)
			return false
		if(data["SUBTYPE"] = "" || data["VALUE"] = "") ; Didn't get everything we needed.
			return false
		
		this.descriptorType := data["SUBTYPE"]
		this.descriptor     := data["VALUE"]
		return true
	}
}
