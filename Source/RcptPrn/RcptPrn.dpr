program RcptPrn;

{%ToDo 'RcptPrn.todo'}

uses
  Forms,
  SysUtils,
  ActiveX,
  fmuMain in 'Forms\fmuMain.pas' {fmMain},
  FileManager in 'Units\FileManager.pas',
  fmuSettings in 'Forms\fmuSettings.pas' {fmSettings},
  fmuAbout in 'Forms\fmuAbout.pas' {fmAbout},
  Receipt in 'Units\Receipt.pas',
  TrayIcon in 'Units\TrayIcon.PAS',
  untVInfo in 'Units\untVInfo.pas',
  Barcode in 'Units\Barcode.pas',
  BrowseFolders in 'Units\BrowseFolders.pas',
  untUtil in 'Units\untUtil.pas',
  Form2 in 'Units\Form2.pas',
  NotifyThread in 'Units\NotifyThread.pas',
  ServerParams in 'Units\ServerParams.pas',
  FiscalPrinter in 'Units\FiscalPrinter.pas',
  FileNames in 'Units\FileNames.pas',
  ShellAPI2 in 'Units\ShellAPI2.pas',
  untLogFile in 'Units\untLogFile.pas',
  AppLogger in 'Units\AppLogger.pas',
  FiscalPrinterIntf in 'Units\FiscalPrinterIntf.pas',
  MockFiscalPrinter in 'Units\MockFiscalPrinter.pas',
  DebugUtils in 'Units\DebugUtils.pas',
  DrvFRLib_TLB in 'Units\DrvFRLib_TLB.pas',
  Semaphore in 'Units\Semaphore.pas',
  fmuMessage in 'Forms\fmuMessage.pas' {fmMessage},
  fmuPrinter in 'Forms\fmuPrinter.pas' {fmPrinter};

{$R *.RES}

function HasCmdLineSwitch: Boolean;
begin
  Result := False;
  try
    Result := FindCmdLineSwitch('XReport', ['-', '/'], True);
    if Result then
    begin
      gFileManager.PrintReportX;
      Exit;
    end;

    Result := FindCmdLineSwitch('ZReport', ['-', '/'], True);
    if Result then
    begin
      gFileManager.PrintReportZ;
      Exit;
    end;

  except
    on E: Exception do
    begin
      Application.HandleException(nil);
    end;
  end;
end;

begin
  CoInitialize(nil);
  if HasCmdLineSwitch then Exit;

  Application.Initialize;
  Application.ShowMainForm := False;
  Application.Title := 'ШТРИХ-М: Принтер чеков';
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmMessage, fmMessage);
  Application.CreateForm(TfmPrinter, fmPrinter);
  Application.Run;
end.
