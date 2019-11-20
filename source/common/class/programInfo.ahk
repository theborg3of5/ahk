; Data class to hold information about a specific program.

class ProgramInfo {
	; #PUBLIC#
	
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
      this.programName := programAry["NAME"]
      this.programPath := programAry["PATH"]
		
		; Replace any path tags
		this.programPath := Config.replacePathTags(this.programPath)
   }
   
	;---------
	; DESCRIPTION:    Name of the program
	;---------
   name {
      get {
         return this.programName
      }
   }
	
	;---------
	; DESCRIPTION:    Full filepath to launch the program
	;---------
   path {
      get {
         return this.programPath
      }
   }
	
	
	; #PRIVATE#
	
   programName := ""
   programPath := ""
   
	
	; #DEBUG#
	
	getDebugTypeName() {
		return "ProgramInfo"
	}
	
   debugToString(ByRef builder) {
      builder.addLine("Name", this.name)
      builder.addLine("Path", this.path)
   }
	; #END#
}
