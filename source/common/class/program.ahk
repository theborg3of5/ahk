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
		
		; Replace any path tags
		this.path := Config.replacePathTags(this.path)
   }
   
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "Program"
	}
	; #END#
}
