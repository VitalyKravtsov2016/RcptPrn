unit FileManagerTest;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Forms,
  // DUnit
  TestFramework,
  // This
  FileUtils, FileManager, FiscalPrinterIntf, MockFiscalPrinter, ServerParams;


type
  { TFileManagerTest }

  TFileManagerTest = class(TTestCase)
  private
    Manager: TFileManager;
    Printer: IFiscalPrinter;
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure CheckDuplicateReceipt;
  end;

implementation

{ TFileManagerTest }

procedure TFileManagerTest.Setup;
begin
  inherited Setup;
  Printer := TMockFiscalPrinter.Create;
  Manager := TFileManager.Create(Printer);
end;

procedure TFileManagerTest.TearDown;
begin
  Manager.Free;
  inherited TearDown;
end;

procedure TFileManagerTest.CheckDuplicateReceipt;
var
  Result: Boolean;
  FileName: string;
  DstFileName: string;
begin
  CheckEquals(88, Manager.ProcessedFiles.Count, 'Manager.ProcessedFiles.Count');
  CheckEquals(False, Manager.IsDuplicateReceiptFile('Test.txt'), 'IsDuplicateReceiptFile');
  CheckEquals(True, Manager.IsDuplicateReceiptFile('RU000140878.P2T'), 'RU000140878.P2T');
  CheckEquals(True, Manager.IsDuplicateReceiptFile('RU000140878.txt'), 'RU000140878.txt');

  Params.ReceiptMask := GetModulePath + 'Fiscal\*.p2t';
  CreateDirectory(GetModulePath + 'Fiscal');
  FileName := IncludeTrailingBackSlash(Params.ProcessedReceiptPath) + 'RU000140869.P2T';
  DstFileName := IncludeTrailingBackSlash(GetModulePath + 'Fiscal\') + 'RU000140869.P2T';
  if FileExists(DstFileName) then
  begin
    CheckEquals(True, DeleteFile(DstFileName), 'Failed to delete file');
  end;
  CheckEquals(False, FileExists(DstFileName), DstFileName + ' exists');
  Result := Windows.CopyFile(PChar(FileName), PChar(DstFileName), True);
  CheckEquals(True, Result, 'CopyFile failed: ' + DstFileName);

  CheckEquals(True, FileExists(DstFileName), 'FileExists(DstFileName) <> True');
  Manager.CheckReceiptFiles;
  CheckEquals(False, FileExists(DstFileName), 'FileExists(DstFileName) <> False');
  DstFileName := IncludeTrailingBackSlash(Params.DuplicateReceiptPath) + 'RU000140869.P2T';
  CheckEquals(True, FileExists(DstFileName), 'FileExists(DstFileName) <> True');
end;

initialization
  RegisterTest('', TFileManagerTest.Suite);

end.