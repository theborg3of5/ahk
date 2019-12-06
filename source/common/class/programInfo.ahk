; Data class to hold information about a specific program.

class ProgramInfo {
	; #PUBLIC#
   
	;---------
	; DESCRIPTION:    Name of the program
	;---------
   name := ""
	;---------
	; DESCRIPTION:    Full filepath to launch the program
	;---------
   path := ""
	
   ;---------
   ; DESCRIPTION:    Creates a new instance of ProgramInfo.
   ; PARAMETERS:
   ;  programAry (I,REQ) - Array of information about the program to store. Format:
   ;                          programAry["NAME"] - Name of the program. Should match a single row
   ;                                               in windows.tl for identification purposes.
   ;                                    ["PATH"] - The full filepath to launch the program.
   ; RETURNS:        Reference to a new ProgramInfo object
   ;---------
   __New(programAry) {
      this.name := programAry["NAME"]
      this.path := programAry["PATH"]
		
		; Replace any path tags
		this.path := Config.replacePathTags(this.path)
   }
   
	
	; #DEBUG#
	
	getDebugTypeName() {
		return "ProgramInfo"
	}
	; #END#
}
