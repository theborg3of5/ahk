; Class that represents a specific program and all the information needed to run it.

class Program {
	; #PUBLIC#
	
	; @GROUP@ Path types (affects how the path is run)
	static PathType_EXE    := "EXE" ; A "normal" path to an executable
	static PathType_WinApp := "APP" ; A windows app (fka universal app)
	static PathType_URL    := "URL" ; A web URL
	; @GROUP-END@
	
	; @GROUP@
	name     := "" ; Name of the program
	path     := "" ; Full filepath to launch the program
	pathType := "" ; The type of path from Program.PathType_*
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    Creates a new instance of Program.
	; PARAMETERS:
	;  programAry (I,REQ) - Array of information about the program to store. Format:
	;                          programAry["NAME"] - Name of the program. Should match a single row
	;                                               in windows.tl for identification purposes.
	;                                    ["PATH"] - The full filepath to launch the program.
	; RETURNS:        Reference to a new Program object
	;---------
	__New(programAry) {
		this.name     := programAry["NAME"]
		this.path     := programAry["PATH"]
		this.pathType := programAry["PATH_TYPE"]
		
		; Replace any path or private tags
		this.path := Config.replacePathTags(this.path)
		this.path := Config.replacePrivateTags(this.path)
	}
	
	;---------
	; DESCRIPTION:    Run this program with the given arguments.
	; PARAMETERS:
	;  args (I,OPT) - The command-line arguments to pass to the program when we run it.
	; RETURNS:        false if we couldn't run the program, true otherwise.
	;---------
	run(args := "") {
		; Safety checks
		if(this.pathType = this.PathType_EXE) {
			if(!FileExist(this.path)) {
				new ErrorToast("Could not run " this.name, "Path does not exist: " this.path).showMedium()
				return false
			}
		}
		
		; Path type determines how we run the path
		Switch this.pathType {
			Case this.PathType_EXE:    RunLib.runAsUser(this.path, args)
			Case this.PathType_URL:    Run(this.path) ; Must be run directly, since it's not a file that exists
			Case this.PathType_WinApp: Run("explorer.exe " this.path) ; Must be run this way, not as user (possibly needs to be as admin)
		}
		
		return true
	}
	; #END#
}
