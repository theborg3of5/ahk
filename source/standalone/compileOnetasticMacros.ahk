#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.
#LTrim                       ; Trim left padding from continuation sections so they can be indented nicely for code.

#Include <includeCommon>


; Cache of function objects for performance
global allFunctionObjects := {} ; {name: OnetasticFunction}

; XML templates to build compiled XML from
global TemplateXML_Macro := "
	(
		<?xml version=""1.0"" encoding=""utf-16""?>
		<Macro name=""<MAC_NAME>"" category=""<MAC_CATEGORY>"" description=""<MAC_DESCRIPTION>"" version=""27"">
		<MAC_CODE>
		<MAC_DEPENDENCIES>
		</Macro>
	)"
global TemplateXML_Function := "
	(
		<Function name=""<FUNC_NAME>"">
		<FUNC_PARAMS>
		<FUNC_CODE>
		</Function>
	)"
global TemplateXML_Parameter := "<Param byref=""<PRM_IS_BYREF>"" name=""<PRM_NAME>"" />"




; Start in the relevant folder.
SetWorkingDir, % Config.path["ONETASTIC_MACROS"]

; Loop over the macro XML files (containing their inner XML) and compile them into full, importable macro XMLs
pt := new ProgressToast("Compiling Onetastic macros")
Loop, Files, % "*.xml"
{
	if(A_LoopFileName.startsWith("."))
		Continue
	
	pt.nextStep(A_LoopFileName)
	macroInnerXML := FileRead(A_LoopFileName)
	macro := new OnetasticMacro(macroInnerXML)
	FileLib.replaceFileWithString(Config.path["ONETASTIC_MACROS"] "\output\" A_LoopFileName, macro.generateXML())
}
pt.blockingOn().finish()


ExitApp


;---------
; DESCRIPTION:    Given a macro's XML and the name of a block of comments, pull out the individual comment lines
;                 inside as an array.
; PARAMETERS:
;  xml         (I,REQ) - XML that includes the comment block.
;  sectionName (I,REQ) - Name of the section
; RETURNS:        Array of text lines inside the comment block, with any leading/trailing whitespace removed.
; NOTES:          The blocks this function works with begin with a comment containing only the section name, and end
;                 with an empty comment. For example:
;                   <Comment text="DEPENDENCIES" />
;                   <Comment text=" functionA" />
;                   <Comment text=" functionB" />
;                   <Comment text="" />
;                 Would give you ["functionA", "functionB"]
;---------
getDocSectionLines(xml, sectionName) {
	if(!xml.contains("<Comment text=""" sectionName """ />"))
		return ""
	
	xml := xml.firstBetweenStrings("<Comment text=""" sectionName """ />", "<Comment text="""" />") ; <Comment text="" />
	xmlLines := xml.split("`r`n")
	
	lines := []
	For _,xmlLine in xmlLines
		lines.push(getXMLCommentText(xmlLine))
	
	lines.removeEmpties()
	return lines
}

;---------
; DESCRIPTION:    Given a line of XML representing a comment in a Onetastic macro, extract the text inside.
; PARAMETERS:
;  xmlCommentLine (I,REQ) - Comment line of XML.
; RETURNS:        Text inside the comment, minus any leading/trailing whitespace.
;---------
getXMLCommentText(xmlCommentLine) {
	line := xmlCommentLine.firstBetweenStrings("<Comment text=""", """ />") ; Get the inner string
	return line.withoutWhitespace() ; Drop any leading/trailing whitespace
}

;---------
; DESCRIPTION:    Get the function object for a given name, reading from a file if needed.
; PARAMETERS:
;  name (I,REQ) - Name of the function to retrieve.
; RETURNS:        OnetasticFunction object matching the given name.
; SIDE EFFECTS:   Caches results in global allFunctionObjects object.
;---------
getFunction(name) {
	if(!allFunctionObjects[name]) {
		filepath := Config.path["ONETASTIC_FUNCTIONS"] "\" name ".xml"
		if(!FileExist(filepath)) {
			new ErrorToast("Could not load function: " name, "File does not exist: " filepath).showMedium()
			return ""
		}
		
		allFunctionObjects[name] := new OnetasticFunction(FileRead(filepath))
	}
	
	return allFunctionObjects[name]
}


; Represents a single Onetastic macro.
class OnetasticMacro {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Create a new object representing a Onetastic macro.
	; PARAMETERS:
	;  innerXML (I,REQ) - Inner XML of the macro (that you'd get by grabbing its XML from the editor)
	;---------
	__New(innerXML) {
		this.innerXML := innerXML
		
		this.loadMetadata(innerXML)
		this.loadDependencies(innerXML)
	}
	
	;---------
	; DESCRIPTION:    Generates the full "outer" XML for this macro, ready for importing.
	;---------
	generateXML() {
		dependenciesOuterXML := ""
		For _,name in this.dependencyNames {
			fn := getFunction(name)
			dependenciesOuterXML := dependenciesOuterXML.appendLine(fn.generateXML())
		}
		
		xml := TemplateXML_Macro.replaceTags({"MAC_NAME":this.name, "MAC_CATEGORY":this.category, "MAC_DESCRIPTION":this.description, "MAC_CODE":this.innerXML, "MAC_DEPENDENCIES":dependenciesOuterXML})
		
		xml := StringLib.dropEmptyLines(xml)
		return xml
	}
	
	
	; #PRIVATE#
	
	name            := ""
	category        := "" ; Which menu the macro appears under
	description     := ""
	innerXML        := "" ; XML of macro contents (doesn't include <Macro> or dependency <Function> tags)
	dependencyNames := "" ; [string]
	
	;---------
	; DESCRIPTION:    Load various script information from the METADATA comment block at the top of the macro.
	; PARAMETERS:
	;  innerXML (I,REQ) - Inner XML of the macro (that you'd get by grabbing its XML from the editor)
	; SIDE EFFECTS:   Populates this.name, this.category, and this.description
	;---------
	loadMetadata(innerXML) {
		metadataLines := getDocSectionLines(innerXML, "METADATA")
		this.name        := metadataLines[1]
		this.category    := metadataLines[2]
		this.description := metadataLines[3]
	}
	
	;---------
	; DESCRIPTION:    Load the names of all dependencies of this macro - those that it calls directly, that those dependencies call, etc.
	; PARAMETERS:
	;  innerXML (I,REQ) - Inner XML of the macro (that you'd get by grabbing its XML from the editor)
	; SIDE EFFECTS:   Populates this.dependencyNames
	;---------
	loadDependencies(innerXML) {
		macroDependencyNames := getDocSectionLines(innerXML, "DEPENDENCIES")
		
		allDependencyNames := []
		allDependencyNames.appendArray(macroDependencyNames)
		For _,name in macroDependencyNames
			allDependencyNames.appendArray(getFunction(name).dependencyNames)
		allDependencyNames.removeDuplicates()
		
		this.dependencyNames := allDependencyNames
	}
	; #END#
}


; Represents a single function in a Onetastic macro.
class OnetasticFunction {
	; #PUBLIC#
	
	dependencyNames := "" ; [string] Names of all function dependencies (recursively - what this function calls, what those called functions call, etc.)
	
	;---------
	; DESCRIPTION:    Create a new Onetastic macro function object.
	; PARAMETERS:
	;  innerXML (I,REQ) - Inner XML of the function (that you'd get by grabbing its XML from the editor)
	;---------
	__New(innerXML) {
		this.innerXML := innerXML
		
		signature := getXMLCommentText(innerXML.firstLine()) ; We assume first line is signature
		this.name := signature.beforeString("(")
		this.loadParameters(signature)
		
		this.loadDependencies(innerXML)
	}
	
	;---------
	; DESCRIPTION:    Generate the full "outer" XML (including <Function> tags and such) for this function.
	;---------
	generateXML() {
		paramsXML := ""
		For _,param in this.parameters
			paramsXML := paramsXML.appendLine(param.generateXML())
		
		code := this.innerXML.replaceTag("CURRENT_MACHINE", Config.machine) ; Replace special CURRENT_MACHINE tag (which allows us to act differently on different machines with the same code)
		
		xml := TemplateXML_Function.replaceTags({"FUNC_NAME":this.name, "FUNC_PARAMS":paramsXML, "FUNC_CODE":code})
		
		xml := StringLib.dropEmptyLines(xml) ; Ensure there's no empty lines, as that'd cause the import to fail.
		return xml
	}
	
	
	; #PRIVATE#
	
	name := "" ; Name of this function
	innerXML := "" ; XML of function contents (doesn't include <Function> or <Parameter> tags)
	parameters := "" ; [OnetasticFunctionParameter]
	
	;---------
	; DESCRIPTION:    Load the parameter definitions from the function signature.
	; PARAMETERS:
	;  signature (I,REQ) - Signature of the function (i.e. functionName(paramName1, byref paramName2) )
	; SIDE EFFECTS:   Populates this.parameters
	;---------
	loadParameters(signature) {
		paramsList := signature.allBetweenStrings("(", ")")
		if(paramsList = "") ; No parameters
			return
		
		this.parameters := []
		For _,paramText in paramsList.split(",", A_Space)
			this.parameters.push(new OnetasticFunctionParameter(paramText))
	}
	
	;---------
	; DESCRIPTION:    Load the list of dependency names from the DEPENDENCIES comment block in the XML.
	; PARAMETERS:
	;  innerXML (I,REQ) - Inner XML of the function.
	; SIDE EFFECTS:   Populates this.dependencyNames
	;---------
	loadDependencies(innerXML) {
		directDependencyNames := getDocSectionLines(innerXML, "DEPENDENCIES")
		
		allDependencyNames := []
		allDependencyNames.appendArray(directDependencyNames)
		For _,name in directDependencyNames
			allDependencyNames.appendArray(getFunction(name).dependencyNames)
		allDependencyNames.removeDuplicates()
		
		this.dependencyNames := allDependencyNames
	}
	; #END#
}


; Represents a single parameter in a Onetastic macro function.
class OnetasticFunctionParameter {
	; #PUBLIC#
	
	name    := ""
	isByRef := ""
	
	;---------
	; PARAMETERS:
	;  paramText (I,REQ) - Text of the parameter from the function signature, including the "byref" prefix if applicable.
	;---------
	__New(paramText) {
		this.name := paramText.afterString("$")
		this.isByRef := paramText.startsWith("byref ")
	}
	
	;---------
	; DESCRIPTION:    Generate the XML for this parameter.
	;---------
	generateXML() {
		byRefText := this.isByRef ? "true" : "false"
		return TemplateXML_Parameter.replaceTags({"PRM_NAME":this.name, "PRM_IS_BYREF":byRefText})
	}
	; #END#
}
