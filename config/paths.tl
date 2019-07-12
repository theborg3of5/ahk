; These are all of the path tags that will be replaced when using MainConfig.replacePathTags().

(	NAME									KEY									PATH													MACHINE
	
	; Pass-throughs - paths which are retrieved/calculated in MainConfig.loadPaths(). These can also be used in this file.
	User Root							USER_ROOT
	Program Data						PROGRAM_DATA
	AppData Local						APPDATA_LOCAL
	Temp									TEMP
	AppData (Remote)					APPDATA
	Start Menu							START_MENU
	Startup								STARTUP
	Desktop								DESKTOP
	Program Files						PROGRAM_FILES
	Program Files (x86)				PROGRAM_FILES_86
	Windows (System Root)			WINDOWS
	Command prompt path				CMD
	AHK Root								AHK_ROOT
	
[MACHINE.replaceWith(EPIC_LAPTOP)]
	; Private pass-throughs - private tags to replace in folder paths
	Epic Personal						EPIC_PERSONAL
	Epic NFS 3 Day						EPIC_NFS_3DAY
	Epic NFS 3 Day (Unix)			EPIC_NFS_3DAY_UNIX
	Epic NFS Ask						EPIC_NFS_ASK
	Epic Net Home						EPIC_NET_HOME
	Epic Source S1						EPIC_SOURCE_S1
	Epic Source S2						EPIC_SOURCE_S2
	Epic DBC Design					EPIC_DBC_DESIGN
[]
	
	; General
	AHK Config							AHK_CONFIG							<AHK_ROOT>\config
	AHK Source							AHK_SOURCE							<AHK_ROOT>\source
	Downloads							DOWNLOADS							<USER_ROOT>\Downloads
	User Dev								USER_DEV								<USER_ROOT>\Dev
	
	; Dev
	Onetastic Macros					ONETASTIC_MACROS					<USER_ROOT>\OnetasticMacros
	Onetastic Functions				ONETASTIC_FUNCTIONS				<USER_ROOT>\OnetasticMacros\Functions
	
[MACHINE.replaceWith(EPIC_LAPTOP)]
	; Epic
	VB6 Compile							VB6_COMPILE							<USER_ROOT>\Dev\Temp\Compile
	Transaction Diff					TX_DIFF								C:\Program Files\TransactionDiff
	Transaction Diff Results		TX_DIFF_OUTPUT						<USER_ROOT>\Dev\TransactionDiffOutput
	EpicStudio Global Highlights	EPICSTUDIO_GLOBAL_HIGHLIGHTS	<USER_ROOT>\EpicStudioGlobalHighlights
	Epic Personal AHK					EPIC_PERSONAL_AHK					<EPIC_PERSONAL>\ahk
[]
