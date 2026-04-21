class Zoom {
	;region ------------------------------ INTERNAL ------------------------------
	;---------
	; DESCRIPTION:    Swap between gallery and speaker views.
	;---------
	static toggleView() {
		if(this.isGalleryView)
			this.switchToSpeakerView()
		else
			this.switchToGalleryView()
	}
	
	;---------
	; DESCRIPTION:    Swap to specific views.
	;---------
	static switchToSpeakerView() {
		Send(this.Hotkey_SpeakerView)
		this.isGalleryView := false
	}
	static switchToGalleryView() {
		Send(this.Hotkey_GalleryView)
		this.isGalleryView := true
	}
	;endregion ------------------------------ INTERNAL ------------------------------
	
	;region ------------------------------ PRIVATE ------------------------------
	static isGalleryView := true ; Most rooms I frequent start in gallery view.
	
	; Hotkeys configured in Zoom
	static Hotkey_SpeakerView := "!{F1}"
	static Hotkey_GalleryView := "!{F2}"
	
	;endregion ------------------------------ PRIVATE ------------------------------
}
