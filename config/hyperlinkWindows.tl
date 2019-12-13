[	NAME								SET_PATH_METHOD	CLOSE_METHOD	LINK_POPUP							PATH_FIELD_CONTROL_ID	TAGGED_STRING_BASE	]

; EMC2 link popup and path field are the same across most EMC2 workflows.
~LINK_POPUP.replaceWith(HyperLink Parameters ahk_class ThunderRT6FormDC)|PATH_FIELD_CONTROL_ID.replaceWith(ThunderRT6TextBox1) {
	EMC2 DLG/XDS Issue Popup	POPUP_FIELD			ENTER
	EMC2 QAN							POPUP_FIELD			ENTER
	EMC2 QAN change status		POPUP_FIELD			ENTER
	EMC2 XDS							POPUP_FIELD			ENTER
	EMC2 XDS Magnify				POPUP_FIELD			ENTER
}

	OneNote							POPUP_FIELD			ENTER				Link ahk_class NUIDialog		RICHEDIT60W2
	Outlook							POPUP_FIELD			ENTER				ahk_class bosa_sdm_Mso96		RichEdit20W6
	Word								POPUP_FIELD			ENTER				ahk_class bosa_sdm_msword		RichEdit20W6

	EMC2 PRJ Readiness Notes	WEB_FIELD			ALT_A
	EMC2 PRJ							WEB_FIELD			ALT_A
	EMC2 DLG							WEB_FIELD			ALT_A
	Teams								WEB_FIELD			ENTER
	Mattermost						TAGGED_STRING		-					-										-								[<TEXT>](<PATH>)
