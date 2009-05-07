; NSIS extensions needed to compile this script that
;    aren't in the default install:
; FindProcDLL   (don't get the optimized for size version,
; KillProcDLL    I had no luck with that)
; ShutDown
; NSISArray     (And the header that comes with it)
; UserMgr
; You will also need the include header "Advanced Uninstall Log NSIS Header"
;   Make sure you get the modified version that has support for localization

;--------------------------------
;Variables

var currentShell
var hasStartedLS
var username
var langWhereProfiles
var abortWarning
var advancedInstall

;--------------------------------
;Include Modern UI

!include "MUI.nsh"

!include WinMessages.nsh

!define PRODUCT_NAME "LOSI"
!define PRODUCT_VERSION "0.4.5"
!define PRODUCT_PUBLISHER "Tobbe"
!define PRODUCT_WEB_SITE "http://tlundberg.com/LOSI"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\litestep.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_STARTMENU_REGVAL "NSIS:StartMenuDir"

SetCompressor bzip2

;--------------------------------
; Uninstall log
!define INSTDIR_REG_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define INSTDIR_REG_KEY "${PRODUCT_UNINST_KEY}"
!define UNINSTALLOG_LOCALIZE
!include AdvUninstLog.nsh
!insertmacro UNATTENDED_UNINSTALL ;Keep all files we didn't install without asking

;--------------------------------
; NSISArray
!include NSISArray.nsh
${Array} whereprofilesarray 5 ${NSIS_MAX_STRLEN}
${ArrayFunc} Read
${ArrayFunc} Write
${ArrayFunc} Shift
${ArrayFunc} SizeOf
${ArrayFunc} Clear
${ArrayFunc} Debug

${Array} un.whereprofilesarray 5 ${NSIS_MAX_STRLEN}
${ArrayFunc} Read
${ArrayFunc} Write
${ArrayFunc} Shift
${ArrayFunc} SizeOf
${ArrayFunc} Clear
${ArrayFunc} Debug



;--------------------------------
;MUI Settings

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP ".\header.bmp" ; optional
!define MUI_WELCOMEFINISHPAGE_BITMAP ".\welcomefinish.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP ".\welcomefinish.bmp"
!define MUI_ICON ".\installer.ico"
!define MUI_UNICON ".\installer.ico"
!define MUI_CUSTOMFUNCTION_ABORT customOnUserAbort

;--------------------------------
;Reserve Files

;These files should be inserted before other files in the data block
;Keep these lines before any File command
;Only for solid compression (by default, solid compression is enabled for BZIP2 and LZMA)

ReserveFile "ioTypeOfInstall.ini"
ReserveFile "ioHowLS.ini"
ReserveFile "ioWhereProfiles.ini"
ReserveFile "ioPreviousInstall.ini"
ReserveFile "ioFileAssoc.ini"
ReserveFile "ioPreReq.ini"
ReserveFile "test.txt"
ReserveFile "cross.bmp"
ReserveFile "check.bmp"
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
!insertmacro MUI_RESERVEFILE_LANGDLL ;Language selection dialog

;--------------------------------
;General

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"

;Name of installation exe
OutFile "${PRODUCT_NAME}-${PRODUCT_VERSION}.exe"

;Default installation folder
InstallDir "$PROGRAMFILES\LiteStep"

;Get installation folder from registry if available
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""

ShowInstDetails show
ShowUnInstDetails show

;--------------------------------
;Language Selection Dialog Settings

;Remember the installer language
!define MUI_LANGDLL_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_LANGDLL_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "NSIS:Language"

;End Lang. Sel.
;--------------------------------

;--------------------------------
;Pages and Sections

; Here you include the pages and sections you want in the installer.
; If you don't want one of the pages/sections just remove/comment that line.

!include PageWelcome.nsh
!include PageLicense.nsh
!include PagePrerequisites.nsh
!include PageTypeOfInstall.nsh
!include PageDirectory.nsh
!include PagePreviousInstall.nsh
!include SectionCore.nsh
!include SectionTheme.nsh
!include HiddenSectionTheme.nsh
!include PageAndHiddenSectionStartMenu.nsh
!include SectionLOSI.nsh
!include PageHowLS.nsh
!include PageWhereProfiles.nsh
!include PageInstFiles.nsh ; This page is needed to execute any Sections
!include PageAndSectionConfigEvars.nsh
!include PageAndSectionFileAssoc.nsh
!include PageFinish.nsh
!include Uninstaller.nsh

;End Pages and Sections
;--------------------------------

!include "LanguageStrings.nsh"

Function .onInit
	StrCpy $abortWarning "true"
	StrCpy $advancedInstall "true"

	UserInfo::GetName
	Pop $username
	ClearErrors ; UserInfo might genrate an error, but we don't care

	; Set a default profiles directory
	${whereprofilesarray->Init}
	${whereprofilesarray->Shift} "$PROGRAMFILES\LiteStep\Profiles\$username"

	!insertmacro MUI_LANGDLL_DISPLAY

	;Always prepare the log within the .onInit function
	!insertmacro UNINSTALL.LOG_PREPARE_INSTALL

	;Extract InstallOptions INI Files
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioPreReq.ini"
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioPreviousInstall.ini"
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioTypeOfInstall.ini"
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioHowLS.ini"
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioWhereProfiles.ini"
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "ioFileAssoc.ini"
FunctionEnd

Function .onInstSuccess
	;Alwasy create/update log within the .onInstSuccess function
	!insertmacro UNINSTALL.LOG_UPDATE_INSTALL
FunctionEnd

Function .onGUIEnd
	!ifdef PAGE_CONFIG_EVARS
		${EvarNames->Inited} 0 dontDeleteEvarArrays
			${InputHwnds->Delete}
			${EvarNames->Delete}
			${EvarPaths->Delete}
		dontDeleteEvarArrays:
		${whereprofilesarray->Delete}
	!endif
FunctionEnd

Function customOnUserAbort
	StrCmp $abortWarning "false" NoAbortWarning
	MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(ABORT_WARNING)" IDYES NoAbortWarning
		Abort ; causes installer to not quit.
	NoAbortWarning:
FunctionEnd

!ifdef WRITE_UNINSTALLER
	Function un.onUninstSuccess
	    HideWindow
	    MessageBox MB_ICONINFORMATION|MB_OK $(UNINSTALL_SUCCESS)
	FunctionEnd

	Function un.onInit
	    !insertmacro MUI_UNGETLANGUAGE
	    MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 $(UNINSTALL_CONFIRM) IDYES +2
	    Abort
	    !insertmacro UNINSTALL.LOG_BEGIN_UNINSTALL
	FunctionEnd
!endif

;Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!ifdef SECTION_CORE
		!insertmacro MUI_DESCRIPTION_TEXT ${SecCore} $(DESC_SecCore)
    !endif

    !ifdef SECTION_THEME
		!insertmacro MUI_DESCRIPTION_TEXT ${SecTheme} $(DESC_SecTheme)
    !endif

    !ifdef SECTION_LOSI
		!insertmacro MUI_DESCRIPTION_TEXT ${SecLosi} $(DESC_SecLosi)
    !endif

	!ifdef PAGE_FILE_ASSOC
    	!insertmacro MUI_DESCRIPTION_TEXT ${SecFileAssoc} $(DESC_SecFileAssoc)
    !endif

	!ifdef PAGE_CONFIG_EVARS
		!insertmacro MUI_DESCRIPTION_TEXT ${SecConfigEvars} $(DESC_SecConfigEvars)
	!endif
!insertmacro MUI_FUNCTION_DESCRIPTION_END

!include PreFunctions.nsh
!include Kill.nsh