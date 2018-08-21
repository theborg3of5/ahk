
class ProgramInfo {
	
	; ==============================
	; == Public ====================
	; ==============================
	__New(programAry) {
		this.programName    := programAry["NAME"]
		this.programPath    := programAry["PATH"]
		this.programArgs    := programAry["ARGS"]
		this.programMachine := programAry["MACHINE"]
	}
	
	name[] {
		get {
			return this.programName
		}
	}
	path[] {
		get {
			return this.programPath
		}
	}
	args[] {
		get {
			return this.programArgs
		}
	}
	machine[] {
		get {
			return this.programMachine
		}
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	programName    := ""
	programPath    := ""
	programArgs    := ""
	programMachine := ""
	
	; Debug info (used by the Debug class)
	debugName := "ProgramInfo"
	debugToString(debugBuilder) {
		debugBuilder.addLine("Name"   , this.name)
		debugBuilder.addLine("Path"   , this.path)
		debugBuilder.addLine("Args"   , this.args)
		debugBuilder.addLine("Machine", this.machine)
	}
}