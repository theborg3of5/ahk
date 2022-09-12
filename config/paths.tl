; These are all of the path tags that will be replaced when using Config.replacePathTags().

[	NAME										KEY										PATH																			CONTEXT	]

	; Pass-throughs - paths which are retrieved/calculated in Config.getSystemPathTags(). These can also be used in this file.
	AHK Root									AHK_ROOT
	AppData (Roaming)						USER_APPDATA
	AppData Local							USER_APPDATA_LOCAL
	Command prompt path					CMD
	Desktop									USER_DESKTOP
	EMC2 executable (Current)			EMC2_CURRENT_EXE
	EpicSource (Current Version)		EPIC_SOURCE_CURRENT
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
	Epic VDI Settings						EPIC_VDI_SETTINGS
	Epic Environment TraceX Files		EPIC_HSWEB_TRACE
	Epic Shared UX Resources			EPIC_UX_SHARED
	Epic OneDrive Root					EPIC_ONEDRIVE_ROOT
}

	; General
	AHK Config								AHK_CONFIG								<AHK_ROOT>\config
	AHK Source								AHK_SOURCE								<AHK_ROOT>\source
	AHK Output								AHK_OUTPUT								<AHK_ROOT>\output
	AHK Templates							AHK_TEMPLATE							<AHK_ROOT>\template
	AHK Test									AHK_TEST									<AHK_ROOT>\test
	Downloads								USER_DOWNLOADS							<USER_ROOT>\Downloads

	; Dev
	Onetastic Macros						ONETASTIC_MACROS						<USER_ROOT>\OnetasticMacros
	Onetastic Functions					ONETASTIC_FUNCTIONS					<USER_ROOT>\OnetasticMacros\Functions

~CONTEXT.replaceWith(WORK) {
	; Work
	Epic Source								EPIC_SOURCE								C:\EpicSource
	Epic Source Current S1				EPIC_SOURCE_S1							<EPIC_SOURCE_CURRENT>\App St1
	User Dev									USER_DEV									<USER_ROOT>\OneDrive - Epic\Dev
	NotepadPlusPlus Sessions			NOTEPAD_PP_SESSIONS					<USER_ROOT>\OneDrive - Epic\Dev\NotepadPlusPlus Sessions
	VB6 Compile								VB6_COMPILE								<EPIC_SOURCE_CURRENT>\Compile
	Transaction Diff						TX_DIFF									C:\Program Files\TransactionDiff
	Transaction Diff Results			TX_DIFF_OUTPUT							<USER_ROOT>\OneDrive - Epic\Dev\TransactionDiffOutput
	EpicStudio Global Highlights		EPICSTUDIO_GLOBAL_HIGHLIGHTS		<EPIC_PERSONAL>\EpicStudioGlobalHighlights
	Epic Personal AHK						EPIC_PERSONAL_AHK						<EPIC_PERSONAL>\ahk
	Specifics								USER_SPECIFICS							<USER_ROOT>\OneDrive - Epic\Specifics
}
