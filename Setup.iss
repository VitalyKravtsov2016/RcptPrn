[Setup]
AppName="�����-�: ������� �����"
AppVerName="�����-�: ������� ����� 1.33"
DefaultDirName={pf}\�����-�\������� �����
DefaultGroupName=�����-�\������� �����
UninstallDisplayIcon={app}\Uninstall.exe
AllowNoIcons=Yes

AppVersion=1.33
AppPublisher=�����-�
AppPublisherURL=http://www.shtrih-m.ru
AppSupportURL=http://www.shtrih-m.ru
AppUpdatesURL=http://www.shtrih-m.ru
AppComments=�������� ������������ �� �������������, ������������� ��������
AppContact=�. (495) 797-6090
AppReadmeFile=History.txt
AppCopyright="Copyright � 2022 �����-�  ���"
;������
VersionInfoCompany="�����-�"
VersionInfoDescription="������� �����"
VersionInfoTextVersion="1.33.0.0"
VersionInfoVersion=1.33.0.0
OutputBaseFilename=setup
[Languages]
Name: "ru"; MessagesFile: "compiler:languages\Russian.isl"
[Tasks]
Name: "zreporticon"; Description: "������� ����� ��� Z-������"; GroupDescription: "�������� �������:";
Name: "xreporticon"; Description: "������� ����� ��� X-������"; GroupDescription: "�������� �������:";
Name: "desktopicon"; Description: "������� ����� �� &������� �����"; GroupDescription: "�������� �������:";
Name: "quicklaunchicon"; Description: "������� &����� � ������ �������� �������"; GroupDescription: "�������� �������:"; Flags: unchecked;
[Dirs]
Name: "{app}\Logs"
[Files]
; ������� ������
Source: "History.txt"; DestDir: "{app}";
; ������������
Source: "Doc\������������.pdf"; DestDir: "{app}\Doc";
; 
Source: "Bin\Report.ico"; DestDir: "{app}";
Source: "Bin\RcptPrn.exe"; DestDir: "{app}";
Source: "Setup\rtl70.bpl"; DestDir: "{sys}"; Flags: onlyifdoesntexist sharedfile;
Source: "Setup\vcl70.bpl"; DestDir: "{sys}"; Flags: onlyifdoesntexist sharedfile;
[Icons]
; ������� ������
Name: "{group}\������� ������"; Filename: "{app}\History.txt";
; ������������
Name: "{group}\������������"; Filename: "{app}\Doc\������������.pdf";
; ��������
Name: "{group}\������� ����� 1.33"; Filename: "{app}\RcptPrn.exe"; WorkingDir: "{app}";
Name: "{group}\�������"; Filename: "{uninstallexe}"
Name: "{group}\����� X-�����"; Filename: "{app}\RcptPrn.exe"; Parameters: "-XReport"; IconFilename: "{app}\Report.ico";
Name: "{group}\����� Z-�����"; Filename: "{app}\RcptPrn.exe"; Parameters: "-ZReport"; IconFilename: "{app}\Report.ico";
; ���������
Name: "{commonstartup}\������� �����"; Filename: "{app}\RcptPrn.exe"; WorkingDir: "{app}";
; ������ �� ������� �����
Name: "{userdesktop}\����� Z-�����"; Filename: "{app}\RcptPrn.exe"; Parameters: "-XReport"; Tasks: zreporticon; IconFilename: "{app}\Report.ico";
Name: "{userdesktop}\����� X-�����"; Filename: "{app}\RcptPrn.exe"; Parameters: "-ZReport"; Tasks: xreporticon; IconFilename: "{app}\Report.ico";
Name: "{userdesktop}\������� ����� 1.33"; Filename: "{app}\RcptPrn.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\������� ����� 1.33"; Filename: "{app}\RcptPrn.exe"; Tasks: quicklaunchicon
[Run]
Filename: "{app}\RcptPrn.exe"; Description: "��������� ����������"; Flags: postinstall nowait skipifsilent skipifdoesntexist;

