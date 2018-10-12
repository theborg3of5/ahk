; Data class to hold information about a specific path.

class PathInfo {
   
   ; ==============================
   ; == Public ====================
   ; ==============================
   
   ;---------
   ; DESCRIPTION:    Creates a new instance of PathInfo.
   ; PARAMETERS:
   ;  pathAry (I,REQ) - Array of information about the path to store. Format:
   ;                       pathAry["KEY"]  - Key for the path. Will be used to access this info.
   ;                              ["PATH"] - The path in question.
   ; RETURNS:        Reference to a new PathInfo object
   ;---------
   __New(pathAry) {
      this.pathKey  := pathAry["KEY"]
      this.pathPath := pathAry["PATH"]
		
		this.pathPath := replaceTag(this.pathPath, "USER_ROOT", reduceFilepath(A_Desktop,  1))
		this.pathPath := replaceTag(this.pathPath, "AHK_ROOT",  reduceFilepath(A_LineFile, 3)) ; 2 levels out, plus one to get out of file itself.
		
		; Replace any private tags in the path
		this.pathPath := this.replacePrivateTags(this.pathPath)
   }
   
	;---------
	; DESCRIPTION:    Key of the path
	;---------
   key[] {
      get {
         return this.pathKey
      }
   }
	;---------
	; DESCRIPTION:    The path for this object.
	;---------
   path[] {
      get {
         return this.pathPath
      }
   }
   
   
   ; ==============================
   ; == Private ===================
   ; ==============================
   pathKey  := ""
   pathPath := ""
   
   ; Debug info (used by the Debug class)
   debugName := "PathInfo"
   debugToString(debugBuilder) {
      debugBuilder.addLine("Key" , this.key)
      debugBuilder.addLine("Path", this.path)
   }
}