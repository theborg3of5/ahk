; Based on https://github.com/pukkandan/My-Startup-Script/blob/master/Lib/ini.ahk

class IniObject {
	__new(file := "settings.ini") {
		this.file := file
	}
	
	get(sect := "", key := "", def := 0) {
		if(sect = "")
			IniRead, val, % this.file
		else if(key="")
			IniRead, val, % this.file, % sect
		else
			IniRead, val, % this.file, % sect, % key, % def
		
		return val
	}
	
	set(sect, key := "", val := "") {
		if(key = "")
			IniWrite, % val, % this.file, % sect
		else
			IniWrite, % val, % this.file, % sect, % key
		
		return
	}
	
	delete(sect := "", key := "") {
		if(sect = "")
			FileDelete, % this.file
		else if(key = "")
			IniDelete, % this.file, % sect
		else
			IniDelete, % this.file, % sect, % key
		
		return
	}
}