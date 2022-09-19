[Setup]
AppName="ШТРИХ-М: Принтер чеков"
AppVerName="ШТРИХ-М: Принтер чеков 1.33"
DefaultDirName={pf}\ШТРИХ-М\Принтер чеков
DefaultGroupName=ШТРИХ-М\Принтер чеков
UninstallDisplayIcon={app}\Uninstall.exe
AllowNoIcons=Yes

AppVersion=1.33
AppPublisher=ШТРИХ-М
AppPublisherURL=http://www.shtrih-m.ru
AppSupportURL=http://www.shtrih-m.ru
AppUpdatesURL=http://www.shtrih-m.ru
AppComments=Торговое оборудование от производителя, автоматизация торговли
AppContact=т. (495) 797-6090
AppReadmeFile=History.txt
AppCopyright="Copyright © 2022 ШТРИХ-М  ©®™"
;Версия
VersionInfoCompany="ШТРИХ-М"
VersionInfoDescription="Принтер чеков"
VersionInfoTextVersion="1.33.0.0"
VersionInfoVersion=1.33.0.0
OutputBaseFilename=setup
[Languages]
Name: "ru"; MessagesFile: "compiler:languages\Russian.isl"
[Tasks]
Name: "zreporticon"; Description: "Создать ярлык для Z-отчета"; GroupDescription: "Создание ярлыков:";
Name: "xreporticon"; Description: "Создать ярлык для X-отчета"; GroupDescription: "Создание ярлыков:";
Name: "desktopicon"; Description: "Создать ярлык на &рабочем столе"; GroupDescription: "Создание ярлыков:";
Name: "quicklaunchicon"; Description: "Создать &ярлык в панели быстрого запуска"; GroupDescription: "Создание ярлыков:"; Flags: unchecked;
[Dirs]
Name: "{app}\Logs"
[Files]
; История версий
Source: "History.txt"; DestDir: "{app}";
; Документация
Source: "Doc\ПринтерЧеков.pdf"; DestDir: "{app}\Doc";
; 
Source: "Bin\Report.ico"; DestDir: "{app}";
Source: "Bin\RcptPrn.exe"; DestDir: "{app}";
Source: "Setup\rtl70.bpl"; DestDir: "{sys}"; Flags: onlyifdoesntexist sharedfile;
Source: "Setup\vcl70.bpl"; DestDir: "{sys}"; Flags: onlyifdoesntexist sharedfile;
[Icons]
; История версий
Name: "{group}\История версий"; Filename: "{app}\History.txt";
; Документация
Name: "{group}\Документация"; Filename: "{app}\Doc\ПринтерЧеков.pdf";
; Основные
Name: "{group}\Принтер чеков 1.33"; Filename: "{app}\RcptPrn.exe"; WorkingDir: "{app}";
Name: "{group}\Удалить"; Filename: "{uninstallexe}"
Name: "{group}\Снять X-отчет"; Filename: "{app}\RcptPrn.exe"; Parameters: "-XReport"; IconFilename: "{app}\Report.ico";
Name: "{group}\Снять Z-отчет"; Filename: "{app}\RcptPrn.exe"; Parameters: "-ZReport"; IconFilename: "{app}\Report.ico";
; Автостарт
Name: "{commonstartup}\Принтер чеков"; Filename: "{app}\RcptPrn.exe"; WorkingDir: "{app}";
; Иконки на рабочем столе
Name: "{userdesktop}\Снять Z-отчет"; Filename: "{app}\RcptPrn.exe"; Parameters: "-XReport"; Tasks: zreporticon; IconFilename: "{app}\Report.ico";
Name: "{userdesktop}\Снять X-отчет"; Filename: "{app}\RcptPrn.exe"; Parameters: "-ZReport"; Tasks: xreporticon; IconFilename: "{app}\Report.ico";
Name: "{userdesktop}\Принтер чеков 1.33"; Filename: "{app}\RcptPrn.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\Принтер чеков 1.33"; Filename: "{app}\RcptPrn.exe"; Tasks: quicklaunchicon
[Run]
Filename: "{app}\RcptPrn.exe"; Description: "Запустить приложение"; Flags: postinstall nowait skipifsilent skipifdoesntexist;

