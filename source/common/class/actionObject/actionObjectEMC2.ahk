#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for performing actions on EMC2 objects.
	
	Note that several other operations are also available from the base class (.copyLink*(), .linkSelectedText*()).
	
	Example Usage
		ao := new ActionObjectEMC2("DLG 123456")
		MsgBox, ao.getLinkWeb()      ; Link in web (emc2summary or Nova/Sherlock as appropriate)
		MsgBox, ao.getLinkWebBasic() ; Link in "basic" web (always emc2summary)
		MsgBox, ao.getLinkEdit()     ; Link to edit in EMC2
		ao.openWeb()                 ; Open in web (emc2summary or Nova/Sherlock as appropriate)
		ao.openWebBasic()            ; Open in "basic" web (always emc2summary)
		ao.openEdit()                ; Open to edit in EMC2
		
		ao := new ActionObjectEMC2(123456) ; ID without an INI, user will be prompted for the INI
		ao.openEdit() ; Open object in EMC2
*/

class ActionObjectEMC2 extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	id  := "" ; ID of the object
	ini := "" ; INI for the object, from EMC2 subtypes in actionObject.tl
	
	
	__New(id, ini := "", title := "") {
		this.id    := id
		this.ini   := ini
		this.title := title
		
		; If we don't know the INI yet, assume the ID is a combined string (i.e. "DLG 123456" or
		; "DLG 123456: HB/PB WE DID SOME STUFF") and try to split it into its component parts.
		if(this.ini = "") {
			recordAry := extractEMC2ObjectInfoRaw(this.id)
			this.ini   := recordAry["INI"]
			this.id    := recordAry["ID"]
			this.title := recordAry["TITLE"]
		}
		
		; If INI is set, make sure it's the "true" INI (ZQN -> QAN, Design -> XDS, etc.).
		; Note that selection handles this if they pick/add values in .selectMissingInfo().
		if(this.ini != "")
			this.ini := getTrueEMC2INI(this.ini)
		
		this.selectMissingInfo()
	}
	
	openWebBasic() {
		link := replaceTags(MainConfig.private["EMC2_LINK_WEB_BASE"], {"INI":this.ini, "ID":this.id})
		if(link)
			Run(link)
	}
	
	getLinkWeb() {
		if(this.isSherlockINI())
			link := MainConfig.private["SHERLOCK_BASE"]
		else if(this.isNovaINI())
			link := MainConfig.private["NOVA_RELEASE_NOTE_BASE"]
		else
			link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		
		return replaceTags(link, {"INI":this.ini, "ID":this.id})
	}
	getLinkEdit() {
		return replaceTags(MainConfig.private["EMC2_LINK_EDIT_BASE"], {"INI":this.ini, "ID":this.id})
	}
	
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	title := ""
	
	canViewINIInEMC2() {
		if(this.ini = "DLG")
			return true
		if(this.ini = "QAN")
			return true
		if(this.ini = "XDS")
			return true
		
		return false
	}
	
	isSherlockINI() {
		return (this.ini = "SLG")
	}
	
	isNovaINI() {
		return (this.ini = "DRN")
	}
	
	selectMissingInfo() {
		; Nothing is missing
		if(this.id != "" && this.ini != "")
			return
		
		s := new Selector("actionObject.tls", MainConfig.machineTLFilter)
		data := s.selectGui("", "", {"SUBTYPE": this.ini, "VALUE": this.id})
		if(!data)
			return
		
		this.ini := data["SUBTYPE"]
		this.id  := data["VALUE"]
	}
}
