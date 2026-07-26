; Inno Setup 6 or later is required for this script to work.

[Setup]
AppID=KoordASIO
AppName=KoordASIO
AppVerName=KoordASIO
AppVersion={#ApplicationVersion}
VersionInfoVersion={#ApplicationVersion}
AppPublisher=kormix-io
AppPublisherURL=https://github.com/kormix-io/KoordASIO
AppSupportURL=https://github.com/kormix-io/KoordASIO/issues
AppUpdatesURL=https://github.com/kormix-io/KoordASIO/releases
WizardStyle=modern
DefaultGroupName=KoordASIO
DefaultDirName={autopf}\KoordASIO
AppendDefaultDirName=no
ArchitecturesInstallIn64BitMode=x64compatible
; The control panel is built 64-bit only, so a 32-bit Windows would get a driver
; with no way to configure it. The 32-bit driver here is for 32-bit *hosts*
; running on 64-bit Windows, which is the case that still exists.
ArchitecturesAllowed=x64compatible
; The control app is resident in the system tray, so on an upgrade it holds its
; own files open; without this the install aborts with code 5. It must be "force":
; with the tray enabled the app cancels WM_CLOSE to hide instead of quitting, so
; a polite close request is declined and the Restart Manager gives up.
CloseApplications=force
RestartApplications=no
; disk space isn't calculated accurately - set here to 45Mb x 1024 x 1024 bytes,
; raised from 29Mb now the 32-bit driver ships alongside the 64-bit one
ExtraDiskSpaceRequired=47185920

; for 100% dpi setting should be 164x314 - https://jrsoftware.org/ishelp/
WizardImageFile=windows\koordasio.bmp
; for 100% dpi setting should be 55x55 
WizardSmallImageFile=windows\koordasio-small.bmp

[Files]
Source:"deploy\x86_64\KoordASIO.dll"; DestDir: "{app}"; Flags: ignoreversion regserver 64bit
; install everything else in deploy dir, including portaudio.dll, KoordASIOControl.exe and all Qt dll deps
Source:"deploy\x86_64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs 64bit

; 32-bit driver alongside, for ASIO hosts that are themselves 32-bit. Both
; register the same CLSID, each into its own registry view, so a host loads
; whichever matches its own architecture.
Source:"deploy\x86\KoordASIO.dll"; DestDir: "{app}\x86"; Flags: ignoreversion regserver 32bit
Source:"deploy\x86\*"; DestDir: "{app}\x86"; Flags: ignoreversion 32bit

[Icons]
Name: "{group}\KoordASIO Control"; Filename: "{app}\KoordASIOControl.exe"; WorkingDir: "{app}"

[Run]
; make sure we have SOME working default configuration after installation
Filename: "{app}\KoordASIOControl.exe"; Parameters: "-defaults"; Description: "Set KoordASIO defaults"; Flags: nowait
; also allow user to configure immediately after installation
Filename: "{app}\KoordASIOControl.exe"; Description: "Run KoordASIO Control"; Flags: postinstall nowait skipifsilent
; ensure COM/ASIO registration succeeds even if self-registration during copy failed
Filename: "{sys}\regsvr32.exe"; Parameters: "/s ""{app}\KoordASIO.dll"""; StatusMsg: "Registering KoordASIO driver..."; Flags: runhidden
; the 32-bit driver has to be registered by the 32-bit regsvr32, which lives in SysWOW64
Filename: "{syswow64}\regsvr32.exe"; Parameters: "/s ""{app}\x86\KoordASIO.dll"""; StatusMsg: "Registering 32-bit KoordASIO driver..."; Flags: runhidden

; install reg key to locate KoordASIOControl at runtime
[Registry]
Root: HKLM64; Subkey: "Software\Koord"; Flags: uninsdeletekeyifempty
Root: HKLM64; Subkey: "Software\Koord\KoordASIO"; Flags: uninsdeletekey
Root: HKLM64; Subkey: "Software\Koord\KoordASIO\Install"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
