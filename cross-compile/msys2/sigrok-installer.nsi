##
## This file is part of the sigrok-util project.
##
## Copyright (C) 2013-2020 Uwe Hermann <uwe@hermann-uwe.de>
## Copyright (C) 2026 Steve Markgraf <steve@steve-m.de>
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, see <http://www.gnu.org/licenses/>.
##

#
# Combined sigrok Windows installer (PulseView + sigrok-cli).
# Adapted from pulseview_cross.nsi.in and sigrok-cli_cross.nsi.in
# for the MSYS2 UCRT64 native build (dynamic linking).
#
# This .nsi file is placed alongside the gathered release files at build
# time and references them via relative paths. No template processing needed.
#
# Build with: makensis -DPE64=1 -DVERSION=<version> sigrok-installer.nsi
#

!include "MUI2.nsh"
!include "FileAssociation.nsh"

# Version is passed via -DVERSION=xxx on the makensis command line.
!ifndef VERSION
	!define VERSION "unknown"
!endif


# --- Global stuff ------------------------------------------------------------

Name "sigrok"
OutFile "sigrok-${VERSION}-installer.exe"

!ifdef PE64
	InstallDir "$PROGRAMFILES64\sigrok"
!else
	InstallDir "$PROGRAMFILES\sigrok"
!endif

RequestExecutionLevel admin

!define REGSTR "Software\Microsoft\Windows\CurrentVersion\Uninstall\sigrok"

# Defines for WinAPI SHChangeNotify call.
!define SHCNE_ASSOCCHANGED 0x8000000
!define SHCNF_IDLIST 0


# --- MUI interface configuration ---------------------------------------------

!define MUI_ICON "pulseview.ico"
!define MUI_HEADERIMAGE
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_ABORTWARNING
!define MUI_LICENSEPAGE_BUTTON $(^NextBtn)
!define MUI_LICENSEPAGE_TEXT_BOTTOM "Click Next to continue."


# --- Functions/Macros --------------------------------------------------------

Function register_sr_files
	${registerExtension} "$INSTDIR\pulseview.exe" ".sr" "sigrok session file"
	System::Call 'Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)'
FunctionEnd

!Macro "CreateURL" "URLFile" "URLSite" "URLDesc"
	WriteINIStr "$INSTDIR\${URLFile}.URL" "InternetShortcut" "URL" "${URLSite}"
	CreateShortCut "$SMPROGRAMS\sigrok\${URLFile}.lnk" "$INSTDIR\${URLFile}.url" "" \
		"$INSTDIR\pulseview.exe" 0 "SW_SHOWNORMAL" "" "${URLDesc}"
!MacroEnd


# --- MUI pages ---------------------------------------------------------------

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "COPYING"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

# Register .sr file extension checkbox on finish page.
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_SHOWREADME_CHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Register .sr files with PulseView"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION register_sr_files

!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH


# --- MUI language files ------------------------------------------------------

!insertmacro MUI_LANGUAGE "English"


# --- Default section ---------------------------------------------------------

Section "sigrok (required)" Section1
	SectionIn RO

	SetOutPath "$INSTDIR"

	# License file.
	File "COPYING"

	# PulseView and sigrok-cli executables.
	File "pulseview.exe"
	File "sigrok-cli.exe"

	# All required DLLs (dynamically linked UCRT64 build).
	File "*.dll"

	# Zadig (used for installing WinUSB drivers).
	File "zadig.exe"

	# PulseView icon (for file association).
	File "pulseview.ico"

	# Qt6 plugins.
	SetOutPath "$INSTDIR\platforms"
	File /r "platforms\*.*"

	SetOutPath "$INSTDIR\styles"
	File /r "styles\*.*"

	SetOutPath "$INSTDIR\iconengines"
	File /r "iconengines\*.*"

	# Python runtime.
	SetOutPath "$INSTDIR\lib"
	File /r "lib\*.*"

	# Protocol decoders.
	SetOutPath "$INSTDIR\share"
	File /r /x "__pycache__" /x "*.pyc" "share\libsigrokdecode"

	# Firmware files.
	File /r "share\sigrok-firmware"

	# Generate the uninstaller executable.
	WriteUninstaller "$INSTDIR\Uninstall.exe"

	# Create start menu shortcuts.
	CreateDirectory "$SMPROGRAMS\sigrok"

	SetOutPath "$INSTDIR"

	# PulseView shortcuts.
	CreateShortCut "$SMPROGRAMS\sigrok\PulseView.lnk" \
		"$INSTDIR\pulseview.exe" "" "$INSTDIR\pulseview.exe" \
		0 SW_SHOWNORMAL \
		"" "Open-source, portable sigrok GUI"

	CreateShortCut "$SMPROGRAMS\sigrok\PulseView (Safe Mode).lnk" \
		"$INSTDIR\pulseview.exe" "-c -D" "$INSTDIR\pulseview.exe" \
		0 SW_SHOWNORMAL \
		"" "PulseView (Safe Mode)"

	CreateShortCut "$SMPROGRAMS\sigrok\PulseView (Debug).lnk" \
		"$INSTDIR\pulseview.exe" "-l 5" "$INSTDIR\pulseview.exe" \
		0 SW_SHOWNORMAL \
		"" "PulseView (debug log level)"

	# sigrok-cli shortcut (opens a command prompt).
	CreateShortCut "$SMPROGRAMS\sigrok\sigrok command-line tool.lnk" \
		"$SYSDIR\cmd.exe" \
		"/K echo For instructions run sigrok-cli --help." \
		"$SYSDIR\cmd.exe" 0 \
		SW_SHOWNORMAL "" "Run sigrok-cli"

	# Zadig shortcut.
	CreateShortCut "$SMPROGRAMS\sigrok\Zadig (USB driver installer).lnk" \
		"$INSTDIR\zadig.exe" "" "$INSTDIR\zadig.exe" 0 \
		SW_SHOWNORMAL "" "Zadig USB driver installer"

	# Uninstaller shortcut.
	CreateShortCut "$SMPROGRAMS\sigrok\Uninstall sigrok.lnk" \
		"$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0 \
		SW_SHOWNORMAL "" "Uninstall sigrok"

	# URL shortcut to online manual.
	!InsertMacro "CreateURL" "PulseView HTML manual" \
		"https://sigrok.org/doc/pulseview/unstable/manual.html" \
		"PulseView HTML manual"

	# Create registry keys for "Add/remove programs" in the control panel.
	WriteRegStr HKLM "${REGSTR}" "DisplayName" "sigrok"
	WriteRegStr HKLM "${REGSTR}" "UninstallString" \
		"$\"$INSTDIR\Uninstall.exe$\""
	WriteRegStr HKLM "${REGSTR}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "${REGSTR}" "DisplayIcon" \
		"$\"$INSTDIR\pulseview.ico$\""
	WriteRegStr HKLM "${REGSTR}" "Publisher" "sigrok"
	WriteRegStr HKLM "${REGSTR}" "HelpLink" \
		"https://sigrok.org/wiki/PulseView"
	WriteRegStr HKLM "${REGSTR}" "URLUpdateInfo" \
		"https://sigrok.org/wiki/Downloads"
	WriteRegStr HKLM "${REGSTR}" "URLInfoAbout" "https://sigrok.org"
	WriteRegStr HKLM "${REGSTR}" "DisplayVersion" "${VERSION}"
	WriteRegStr HKLM "${REGSTR}" "Contact" \
		"sigrok-devel@lists.sourceforge.org"
	WriteRegStr HKLM "${REGSTR}" "Comments" \
		"sigrok logic analyzer suite (PulseView + sigrok-cli)"

	# Display "Remove" instead of "Modify/Remove" in the control panel.
	WriteRegDWORD HKLM "${REGSTR}" "NoModify" 1
	WriteRegDWORD HKLM "${REGSTR}" "NoRepair" 1
SectionEnd


# --- Uninstaller section -----------------------------------------------------

Section "Uninstall"
	# Always delete the uninstaller first.
	Delete "$INSTDIR\Uninstall.exe"

	# Delete executables and DLLs.
	Delete "$INSTDIR\COPYING"
	Delete "$INSTDIR\pulseview.exe"
	Delete "$INSTDIR\sigrok-cli.exe"
	Delete "$INSTDIR\*.dll"
	Delete "$INSTDIR\zadig.exe"
	Delete "$INSTDIR\pulseview.ico"

	# Delete Qt6 plugins.
	RMDir /r "$INSTDIR\platforms"
	RMDir /r "$INSTDIR\styles"
	RMDir /r "$INSTDIR\iconengines"

	# Delete Python runtime.
	RMDir /r "$INSTDIR\lib"

	# Delete protocol decoders and firmware.
	RMDir /r "$INSTDIR\share\libsigrokdecode"
	RMDir /r "$INSTDIR\share\sigrok-firmware"
	RMDir "$INSTDIR\share"

	# Delete URL files.
	Delete "$INSTDIR\PulseView HTML manual.url"

	# Delete the install directory.
	RMDir "$INSTDIR"

	# Delete start menu shortcuts.
	Delete "$SMPROGRAMS\sigrok\PulseView.lnk"
	Delete "$SMPROGRAMS\sigrok\PulseView (Safe Mode).lnk"
	Delete "$SMPROGRAMS\sigrok\PulseView (Debug).lnk"
	Delete "$SMPROGRAMS\sigrok\sigrok command-line tool.lnk"
	Delete "$SMPROGRAMS\sigrok\Zadig (USB driver installer).lnk"
	Delete "$SMPROGRAMS\sigrok\Uninstall sigrok.lnk"
	Delete "$SMPROGRAMS\sigrok\PulseView HTML manual.lnk"
	RMDir "$SMPROGRAMS\sigrok"

	# Delete the registry key(s).
	DeleteRegKey HKLM "${REGSTR}"

	# Unregister file extension.
	${unregisterExtension} ".sr" "sigrok session file"
	System::Call 'Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)'
SectionEnd


# --- Component selection section descriptions --------------------------------

LangString DESC_Section1 ${LANG_ENGLISH} "This installs PulseView, sigrok-cli, protocol decoders, firmware files, Zadig, and all required libraries."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
	!insertmacro MUI_DESCRIPTION_TEXT ${Section1} $(DESC_Section1)
!insertmacro MUI_FUNCTION_DESCRIPTION_END
