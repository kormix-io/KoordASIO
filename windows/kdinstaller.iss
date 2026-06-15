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
ArchitecturesInstallIn64BitMode=x64
; disk space isn't calculated accurately - set here to 29Mb x 1024 x 1024 bytes
ExtraDiskSpaceRequired=30408704

; for 100% dpi setting should be 164x314 - https://jrsoftware.org/ishelp/
WizardImageFile=windows\koordasio.bmp
; for 100% dpi setting should be 55x55 
WizardSmallImageFile=windows\koordasio-small.bmp

[Files]
Source:"deploy\x86_64\KoordASIO.dll"; DestDir: "{app}"; Flags: ignoreversion regserver 64bit; Check: Is64BitInstallMode
; install everything else in deploy dir, including portaudio.dll, KoordASIOControl.exe and all Qt dll deps
Source:"deploy\x86_64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs 64bit; Check: Is64BitInstallMode

[Icons]
Name: "{group}\KoordASIO Control"; Filename: "{app}\KoordASIOControl.exe"; WorkingDir: "{app}"

[Run]
; make sure we have SOME working default configuration after installation
Filename: "{app}\KoordASIOControl.exe"; Parameters: "-defaults"; Description: "Set KoordASIO defaults"; Flags: nowait
; also allow user to configure immediately after installation
Filename: "{app}\KoordASIOControl.exe"; Description: "Run KoordASIO Control"; Flags: postinstall nowait skipifsilent
; ensure COM/ASIO registration succeeds even if self-registration during copy failed
Filename: "{sys}\regsvr32.exe"; Parameters: "/s ""{app}\KoordASIO.dll"""; StatusMsg: "Registering KoordASIO driver..."; Flags: runhidden

; install reg key to locate KoordASIOControl at runtime
[Registry]
Root: HKLM64; Subkey: "Software\Koord"; Flags: uninsdeletekeyifempty
Root: HKLM64; Subkey: "Software\Koord\KoordASIO"; Flags: uninsdeletekey
Root: HKLM64; Subkey: "Software\Koord\KoordASIO\Install"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
