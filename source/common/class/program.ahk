; Class that represents a specific program and all the information needed to run it.

class Program {
	;region ------------------------------ PUBLIC ------------------------------
	
	;region Path types (affect how the path is run)
	static PathType_COMMAND := "COMMAND" ; A command
	static PathType_EXE     := "EXE"     ; A "normal" path to an executable
	static PathType_WinApp  := "APP"     ; A windows app (fka universal app)
	static PathType_URL     := "URL"     ; A web URL
	;endregion Path types (affect how the path is run)
	
	name     := "" ; Name of the program
	path     := "" ; Full filepath to launch the program
	pathType := "" ; The type of path from Program.PathType_*
	
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
	;  args (I,OPT) - The command-line arguments to pass to the program when we run it. Only used for EXE-type paths (not
	;                 windows apps or URLs).
	; RETURNS:        false if we couldn't run the program, true otherwise.
	;---------
	run(args := "") {
		; Safety checks
		if(this.pathType = this.PathType_EXE) {
			if(!FileExist(this.path)) {
				Toast.ShowError("Could not run " this.name, "Path does not exist: " this.path)
				return false
			}
		}
		
		; Path type determines how we run the path
		Switch this.pathType {
			Case this.PathType_COMMAND, this.PathType_EXE, this.PathType_URL:
				Run(this.path.appendPiece(" ", args))
			
			; Windows apps - path is the logical path, found using instructions here:
			; https://answers.microsoft.com/en-us/windows/forum/windows_10-windows_store/starting-windows-10-store-app-from-the-command/836354c5-b5af-4d6c-b414-80e40ed14675)
			Case this.PathType_WinApp:
				Run("explorer.exe " this.path)        ; Must be run this way, not as user (possibly needs to be as admin)
		}
		
		return true
	}
	;endregion ------------------------------ PUBLIC ------------------------------
}
