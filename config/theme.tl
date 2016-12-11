=Select a theme to apply:

+TrayIcon=C:\\Users\\gborg\\System Tools\\Themes\\ThemeSwitcher.exe

(	NAME				ABBREV	ACTIONTYPE		FROMFILE			TOFILE			FROMFOLDER	TOFOLDER
;	Name				Abbrev	"COPY"|"MOVE"	FromFile			ToFile			FromFolder	ToFolder
;	Name				Abbrev	"RUN"				RunFile			"MOUSEFIX"		OtherKey1	OtherKey2

# Windows Theme
[+1|{FROMFILE}b:C:\\Users\\gborg\\System Tools\\Themes\\ThemeSwitcher.exe "|{FROMFILE}e:"]
	Dark 				dw			RUN				Dark 2			\x					\x				dv
	Super Dark 		sdw		RUN				Dark 2			MOUSEFIX			\x				dv
	Light 			lw			RUN				Light 2			\x					\x				lv
	Super Light 	slw		RUN				SuperLight 2	MOUSEFIX			\x				lv
	; Dark 				dw			RUN				Dark 2			\x					des			dv
	; Super Dark 		sdw		RUN				Dark 2			MOUSEFIX			des			dv
	; Light 			lw			RUN				Light 2			\x					les			lv
	; Super Light 	slw		RUN				SuperLight 2	MOUSEFIX			les			lv
[-1]

# VB Theme
[+2|{FROMFILE}b:C:\\Windows\\regedit.exe /S "C:\\Users\\gborg\\System Tools\\Themes\\vbColors|{FROMFILE}e:.reg"]
	Dark				dv			RUN				Dark
	Light				lv			RUN				Light
[-2]

# EpicStudio Theme
[+3|{TOFILE}b:Settings.xml|{FROMFOLDER}b:C:\\Users\\gborg\\AppData\\Local\\Epic Systems Corporation\\EpicStudio]
	Dark				des		COPY				Settings_Dark.xml
	Light				les		COPY				Settings_Light.xml
	Original			oes		COPY				Settings_Original.xml
[-3]
