#Include %A_LineFile%\..\actionObjectBase.ahk

/* Class for ***
	
	***
*/

class ActionObjectEMC2 extends ActionObjectBase {
	; ==============================
	; == Public ====================
	; ==============================
	
	; Named property equivalents for the base generic variables, so base functions still work.
	id[] {
		get {
			return this.value
		}
		set {
			this.value := value
		}
	}
	ini[] {
		get {
			return this.subType
		}
		set {
			this.subType := value
		}
	}
	
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
	
	getLink(linkType := "") {
		if(!this.ini || !this.id)
			return ""
		
		; Default to web link
		if(linkType = "")
			linkType := ActionObjectBase.SUBACTION_Web
		
		; Pick one of the types of links - edit in EMC2 or view in web (summary or Sherlock/Nova).
		if(linkType = ActionObjectBase.SUBACTION_Edit) {
			link := MainConfig.private["EMC2_LINK_EDIT_BASE"]
		} else if(linkType = ActionObjectBase.SUBACTION_Web) {
			if(this.isSherlockINI())
				link := MainConfig.private["SHERLOCK_BASE"]
			else if(this.isNovaINI())
				link := MainConfig.private["NOVA_RELEASE_NOTE_BASE"]
			else
				link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		} else if(linkType = ActionObjectBase.SUBACTION_WebBasic) {
			link := MainConfig.private["EMC2_LINK_WEB_BASE"]
		}
		
		link := replaceTags(link, {"INI":this.ini, "ID":this.id})
		
		return link
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
		
		s := new Selector("actionObject2.tls", MainConfig.machineTLFilter)
		data := s.selectGui("", "", {"SUBTYPE": this.ini, "VALUE": this.id})
		if(!data)
			return
		
		this.ini := data["SUBTYPE"]
		this.id  := data["VALUE"]
	}
}
