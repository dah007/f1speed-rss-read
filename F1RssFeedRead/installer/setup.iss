; Inno Setup installer/uninstaller for the F1Speed Feed Read Command Palette extension.
;
; Produces a per-user, no-admin-required installer that registers the extension's
; out-of-process COM server (see Program.cs's "-RegisterProcessAsComServer" entry
; point) so Command Palette can activate it. Uninstalling removes the files and the
; registry entries, so the extension disappears from Command Palette cleanly.
;
; Build with build-exe.ps1 (which passes /DMyAppVersion and /DArchitecturesAllowed),
; or run ISCC.exe directly on this file to use the defaults below.

#define MyAppName "F1Speed Feed Read"
#define MyAppExeName "F1RssFeedRead.exe"
#define MyAppPublisher "dah007"
#define MyAppURL "https://github.com/dah007/f1speed-rss-read"
; Inno Setup treats a bare "{" as the start of a {constant} reference, so the
; opening brace here is doubled ("{{") to escape it into a literal character
; everywhere {#MyAppCLSID} is substituted below (AppId= and the two Subkey=
; lines) — otherwise ISCC fails with "Unknown constant" on the GUID text.
#define MyAppCLSID "{{20D1B788-DDD1-4B84-A5FA-DF3B61A47939}"

#ifndef MyAppVersion
  #define MyAppVersion "0.0.1"
#endif
#ifndef ArchitecturesAllowed
  #define ArchitecturesAllowed "x64compatible"
#endif

[Setup]
AppId={#MyAppCLSID}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
ArchitecturesAllowed={#ArchitecturesAllowed}
; Without this, Setup runs as a 32-bit process and Windows' WOW64 redirector
; silently sends the [Registry] writes below to ...\Classes\WOW6432Node\CLSID
; instead of the real key — Command Palette (a 64-bit process) would then
; never find the registration. Running Setup natively 64-bit/ARM64 avoids it.
ArchitecturesInstallIn64BitMode={#ArchitecturesAllowed}
DefaultDirName={localappdata}\Programs\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
Compression=lzma
SolidCompression=yes
WizardStyle=modern
OutputDir=Installer
OutputBaseFilename={#MyAppName}_{#MyAppVersion}_{#ArchitecturesAllowed}
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
; Registers the out-of-process COM server so Command Palette can CoCreateInstance
; the extension's CLSID. HKCU keeps this a per-user registration, matching the
; per-user install above (no admin rights needed to install or uninstall).
Root: HKCU; Subkey: "Software\Classes\CLSID\{#MyAppCLSID}"; ValueType: string; ValueName: ""; ValueData: "{#MyAppName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\CLSID\{#MyAppCLSID}\LocalServer32"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" -RegisterProcessAsComServer"; Flags: uninsdeletekey

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
