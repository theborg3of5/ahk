; These are all of the path tags that will be replaced when using Config.replacePathTags().

[	NAME										KEY										PATH														CONTEXT	]

	; Pass-throughs - paths which are retrieved/calculated in Config.loadPaths(). These can also be used in this file.
	AHK Root									AHK_ROOT
	AppData (Roaming)						USER_APPDATA
	AppData Local							USER_APPDATA_LOCAL
	Command prompt path					CMD
	Desktop									USER_DESKTOP
	Program Data							PROGRAM_DATA
	Program Files							PROGRAM_FILES
	Program Files (x86)					PROGRAM_FILES_86
	Start Menu								USER_START_MENU
	Startup									USER_STARTUP
	Temp										USER_TEMP
	User Root								USER_ROOT
	Windows (System Root)				WINDOWS

~CONTEXT.replaceWith(WORK) {
	; Private pass-throughs - private tags to replace in folder paths
	Epic DBC Design						EPIC_DBC_DESIGN
	Epic DBC Partial Installers		EPIC_DBC_PARTIAL_INSTALLERS
	Epic Net Home							EPIC_NET_HOME
	Epic NFS 3 Day							EPIC_NFS_3DAY
	Epic NFS 3 Day (Unix)				EPIC_NFS_3DAY_UNIX
	Epic NFS Ask							EPIC_NFS_ASK
	Epic Temp Daily						EPIC_TEMP_DAILY
	Epic Personal							EPIC_PERSONAL
	Epic Source S1							EPIC_SOURCE_S1
	Epic VDI Settings						EPIC_VDI_SETTINGS
	Epic Environment TraceX Files		EPIC_HSWEB_TRACE
}

	; General
	AHK Config								AHK_CONFIG								<AHK_ROOT>\config
	AHK Source								AHK_SOURCE								<AHK_ROOT>\source
	AHK Output								AHK_OUTPUT								<AHK_ROOT>\output
	AHK Templates							AHK_TEMPLATE							<AHK_ROOT>\template
	Downloads								USER_DOWNLOADS							<USER_ROOT>\Downloads

	; Dev
	User Dev									USER_DEV									<USER_ROOT>\Dev
	NotepadPlusPlus Sessions			NOTEPAD_PP_SESSIONS					<USER_ROOT>\Dev\NotepadPlusPlus Sessions
	Onetastic Macros						ONETASTIC_MACROS						<USER_ROOT>\OnetasticMacros
	Onetastic Functions					ONETASTIC_FUNCTIONS					<USER_ROOT>\OnetasticMacros\Functions

~CONTEXT.replaceWith(WORK) {
	; Work
	VB6 Compile								VB6_COMPILE								<USER_ROOT>\Dev\Temp\Compile
	Transaction Diff						TX_DIFF									C:\Program Files\TransactionDiff
	Transaction Diff Results			TX_DIFF_OUTPUT							<USER_ROOT>\Dev\TransactionDiffOutput
	EpicStudio Global Highlights		EPICSTUDIO_GLOBAL_HIGHLIGHTS		<USER_ROOT>\EpicStudioGlobalHighlights
	Epic Personal AHK						EPIC_PERSONAL_AHK						<EPIC_PERSONAL>\ahk
}
