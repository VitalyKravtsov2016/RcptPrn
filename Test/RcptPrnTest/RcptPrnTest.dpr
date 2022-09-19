program RcptPrnTest;

uses
  FastMM4,
  TestFramework,
  GUITestRunner,
  TextDfmTest in 'Units\TextDfmTest.pas',
  FileUtils in '..\..\Source\Shared\FileUtils.pas',
  ReceiptTest in 'Units\ReceiptTest.pas',
  fmuAbout in '..\..\Source\RcptPrn\Forms\fmuAbout.pas' {fmAbout},
  fmuMain in '..\..\Source\RcptPrn\Forms\fmuMain.pas' {fmMain},
  fmuMessage in '..\..\Source\RcptPrn\Forms\fmuMessage.pas' {fmMessage},
  fmuPrinter in '..\..\Source\RcptPrn\Forms\fmuPrinter.pas' {fmPrinter},
  fmuSettings in '..\..\Source\RcptPrn\Forms\fmuSettings.pas' {fmSettings},
  Form2 in '..\..\Source\RcptPrn\Units\Form2.pas',
  untVInfo in '..\..\Source\RcptPrn\Units\untVInfo.pas',
  FileManager in '..\..\Source\RcptPrn\Units\FileManager.pas',
  NotifyThread in '..\..\Source\RcptPrn\Units\NotifyThread.pas',
  Receipt in '..\..\Source\RcptPrn\Units\Receipt.pas',
  untUtil in '..\..\Source\RcptPrn\Units\untUtil.pas',
  ServerParams in '..\..\Source\RcptPrn\Units\ServerParams.pas',
  AppLogger in '..\..\Source\RcptPrn\Units\AppLogger.pas',
  untLogFile in '..\..\Source\RcptPrn\Units\untLogFile.pas',
  FiscalPrinter in '..\..\Source\RcptPrn\Units\FiscalPrinter.pas',
  Barcode in '..\..\Source\RcptPrn\Units\Barcode.pas',
  BrowseFolders in '..\..\Source\RcptPrn\Units\BrowseFolders.pas',
  DebugUtils in '..\..\Source\RcptPrn\Units\DebugUtils.pas',
  DrvFRLib_TLB in '..\..\Source\RcptPrn\Units\DrvFRLib_TLB.pas',
  FileNames in '..\..\Source\RcptPrn\Units\FileNames.pas',
  FiscalPrinterIntf in '..\..\Source\RcptPrn\Units\FiscalPrinterIntf.pas',
  ShellAPI2 in '..\..\Source\RcptPrn\Units\ShellAPI2.pas',
  MockFiscalPrinter in '..\..\Source\RcptPrn\Units\MockFiscalPrinter.pas',
  Semaphore in '..\..\Source\RcptPrn\Units\Semaphore.pas',
  AutoScrollTest in 'Units\AutoScrollTest.pas';

{$R *.RES}

begin
  TGUITestRunner.RunTest(RegisteredTests);
end.
