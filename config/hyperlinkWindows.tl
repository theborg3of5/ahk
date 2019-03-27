(	NAME								SET_PATH_METHOD			LINK_POPUP							PATH_FIELD_CONTROL_ID		TAGGED_STRING_BASE

; EMC2 link popup and path field are the same across most EMC2 workflows.
[LINK_POPUP.replaceWith(HyperLink Parameters ahk_class ThunderRT6FormDC)|PATH_FIELD_CONTROL_ID.replaceWith(ThunderRT6TextBox1)]
	EMC2 QAN							POPUP_FIELD
	EMC2 QAN change status		POPUP_FIELD
	EMC2 XDS							POPUP_FIELD
[]
	OneNote							POPUP_FIELD					Link ahk_class NUIDialog		RICHEDIT60W2
	Outlook							POPUP_FIELD					ahk_class bosa_sdm_Mso96		RichEdit20W6
	Word								POPUP_FIELD					ahk_class bosa_sdm_msword		RichEdit20W6
	
	EMC2 PRJ							WEB_FIELD
	EMC2 DLG							WEB_FIELD
	Mattermost						TAGGED_STRING				-										-									[<TEXT>](<PATH>)
