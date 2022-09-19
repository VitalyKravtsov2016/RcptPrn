unit FileManager;

interface

uses
  // VCL
  Windows, ComObj, IniFiles, SysUtils, Classes, FileCtrl, SyncObjs, Graphics,
  ExtCtrls, ActiveX, Forms, ShellAPI,
  // This
  NotifyThread, Receipt, untVInfo, ServerParams, FiscalPrinter, untUtil,
  FileNames, ShellAPI2, untLogFile, AppLogger, FiscalPrinterIntf,
  MockFiscalPrinter, Semaphore, fmuMessage;

type
  TServerEvent = procedure (Sender: TObject; EventType: TEventType; const S: string) of object;

  { TFileManager }

  TFileManager = class
  private
    FState: string;
    FReceipt: TReceipt;
    FStopFlag: Boolean;
    FThread: TNotifyThread;
    FOnEvent: TServerEvent;
    FPrinter: TFiscalPrinter;
    FEvents: TThreadList;
    FLock: TCriticalSection;

    procedure CheckStopFlag;
    procedure CheckZReportFiles;
    procedure CheckReceiptFiles;
    procedure CheckPrinterStatus;
    procedure AddLog(const S: string);
    procedure AddError(const S: string);
    procedure ThreadProc(Sender: TObject);
    procedure SetState(const Value: string);
    procedure ThreadTerminated(Sender: TObject);
    procedure PrintZReport(const FileName: string);
    procedure ErrorReceipt(const FileName: string);
    procedure ZReportProcessed(const FileName: string);
    procedure ReceiptProcessed(const FileName: string);
    procedure SendEvent(Sender: TObject; AEventType: TEventType; const S: string);

    property Receipt: TReceipt read FReceipt;
    property Printer: TFiscalPrinter read FPrinter;
    procedure WriteLogHeader;
    procedure MoveFile2(const SrcFileName, DstFileName: string);
    procedure DeleteFile2(const FileName: string);
    procedure CopyFile2(const SrcFileName, DstFileName: string);
    procedure PrinterEvent(Sender: TObject; const Event: TPrinterEventObject);
    procedure PrinterEventsProc;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Lock;
    procedure Unlock;
    procedure Stop;
    procedure Start;
    procedure Initialize;
    procedure PrintReportX;
    procedure PrintReportZ;
    function Started: Boolean;
    procedure ShowPrinterProperties;
    procedure PrintFile(const FileName: string);

    property State: string read FState;
    property OnEvent: TServerEvent read FOnEvent write FOnEvent;
  end;

function gFileManager: TFileManager;

implementation

var
  FFileManager: TFileManager = nil;

function gFileManager: TFileManager;
begin
  if FFileManager = nil then
    FFileManager := TFileManager.Create;
  Result := FFileManager;
end;

procedure CreateDirectory(const DirPath: string);
begin
  if not DirectoryExists(DirPath) then
    if not CreateDir(DirPath) then
      raise Exception.Create(Format('�� ������� ������� ����� %s', [DirPath]));
end;

// �������� ����� ������
// ���� ���� ����� ������ ������

function IsReportFile(const FileName: string): Boolean;
var
  S: string;
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(S, 10);
    Stream.Read(S[1], 10);
    Result := S = 'PROMETEO 2';
  finally
    Stream.Free;
  end;
end;

{ TFileManager }

constructor TFileManager.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FReceipt := TReceipt.Create;
  FEvents := TThreadList.Create;
  FPrinter := TFiscalPrinter.Create(nil);
  FPrinter.OnEvent := PrinterEvent;
  SetState('������� ����� ����������');
end;

destructor TFileManager.Destroy;
begin
  Stop;
  FLock.Free;
  FEvents.Free;
  FThread.Free;
  FReceipt.Free;
  FPrinter.Free;
  inherited Destroy;
end;

procedure TFileManager.PrinterEventsProc;
var
  List: TList;
  Event: TPrinterEventObject;
resourcestring
  MsgAddPaper = '���������� ������� ����� � ��!';
begin
  try
    List := FEvents.LockList;
    try
      while List.Count > 0 do
      begin
        Event := TPrinterEventObject(List[0]);
        case Event.ID of
          MessageIDNoPaper:
          begin
            fmMessage.Show2(MsgAddPaper);
          end;
          MessageIDPaperOK:
          begin
            fmMessage.Close2;
          end;
        end;
        Event.Free;
        List.Delete(0);
      end;
    finally
      FEvents.UnlockList;
    end;
  except
    on E: Exception do
    begin
      AddError(E.Message);
    end;
  end;
end;

procedure TFileManager.PrinterEvent(Sender: TObject; const Event: TPrinterEventObject);
begin
  if FThread <> nil then
  begin
    FEvents.Add(Event);
    TThread.Synchronize(FThread, PrinterEventsProc);
  end;
end;

procedure TFileManager.Lock;
begin
  FLock.Enter;
end;

procedure TFileManager.Unlock;
begin
  FLock.Leave;
end;

procedure TFileManager.ShowPrinterProperties;
begin
  Printer.ShowProperties;
end;

procedure TFileManager.CheckStopFlag;
begin
  if FStopFlag then Abort;
end;

procedure TFileManager.ErrorReceipt(const FileName: string);
begin
  if FileExists(FileName) then
  begin
    if Params.CopyErrorReceipts then
    begin
      CreateDirectory(Params.ErrorReceiptPath);
      CopyFile2(FileName, IncludeTrailingBackSlash(Params.ErrorReceiptPath) +
        ExtractFileName(FileName));
    end;
  end;
end;

procedure TFileManager.PrintReportX;
begin
  Lock;
  try
    Printer.Connect;
    Printer.PrintXReport;
  finally
    Printer.Disconnect;
    Unlock;
  end;
end;

procedure TFileManager.PrintReportZ;
begin
  Lock;
  try
    Printer.Connect;
    Printer.PrintZReport;
  finally
    Printer.Disconnect;
    Unlock;
  end;
end;

procedure TFileManager.PrintFile(const FileName: string);
begin
  Lock;
  try
    Printer.Connect;
    CheckStopFlag;
    AddLog(Format('������ ���� "%s"', [FileName]));
    try
      Receipt.PrintWidth := Printer.PrintWidth;
      Receipt.LoadFromFile(FileName);
      if Receipt.IsNonfiscal then
      begin
        Printer.PrintNonfiscalReceipt(Receipt, Params);
        AddLog(Format('������ ����� "%s" ������� ���������', [FileName]));
        ReceiptProcessed(FileName);
      end else
      begin
        Printer.PrintReceipt2(Receipt, Params);
        AddLog(Format('������ ����� "%s" ������� ���������', [FileName]));
        ReceiptProcessed(FileName);
      end;
    except
      on E: Exception do
      begin
        AddLog(Format('������ ��� ��������� ����� "%s": %s', [FileName, E.Message]));
        ErrorReceipt(FileName);
        ReceiptProcessed(FileName);
      end;
    end;
  finally
    Printer.Disconnect;
    Unlock;
  end;
end;

// �������� ����� ������

procedure TFileManager.CheckReceiptFiles;

var
  i: Integer;
  FileName: string;
  FileNames: TFileNames;
begin
  FileNames := TFileNames.Create;
  try
    if Params.ReceiptMode = fmSaveTime then
      FileNames.FindByTime(Params.ReceiptMask, Params.ReceiptFileTime)
    else
      FileNames.FindByMask(Params.ReceiptMask);

    for i := 0 to FileNames.Count-1 do
    begin
      FileName := FileNames[i];
      if not IsReportFile(FileName) then
        PrintFile(FileName);
    end;
  finally
    FileNames.Free;
  end;
end;

procedure TFileManager.MoveFile2(const SrcFileName, DstFileName: string);
begin
  DeleteFile2(DstFileName);
  if not MoveFile(PChar(SrcFileName), PChar(DstFileName)) then
    AddLog(Format('�� ������� ����������� ���� "%s" � ����� "%s".',
      [SrcFileName, ExtractFilePath(DstFileName)]));
end;

procedure TFileManager.CopyFile2(const SrcFileName, DstFileName: string);
begin
  DeleteFile2(DstFileName);
  if not MoveFile(PChar(SrcFileName), PChar(DstFileName)) then
    AddLog(Format('�� ������� ����������� ���� "%s" � ����� "%s".',
      [SrcFileName, ExtractFilePath(DstFileName)]));
end;

procedure TFileManager.DeleteFile2(const FileName: string);
begin
  if FileExists(FileName) then
  begin
    if not DeleteFile(FileName) then
      AddLog(Format('�� ������� ������� ���� "%s".', [FileName]));
  end;
end;

procedure TFileManager.ReceiptProcessed(const FileName: string);
var
  NewFileName: string;
begin
  if FileExists(FileName) then
  begin
    case Params.ReceiptMode of
      fmMove:
      begin
        NewFileName := IncludeTrailingBackSlash(Params.ProcessedReceiptPath) +
            ExtractFileName(FileName);

        CreateDirectory(Params.ProcessedReceiptPath);
        if Params.ChangeFileName then
        begin
          NewFileName := IncludeTrailingBackSlash(Params.ProcessedReceiptPath) +
            Params.FileNamePrefix + ChangeFileExt(ExtractFileName(FileName), '.txt');
        end;
        MoveFile2(FileName, NewFileName);
      end;
      fmDelete:
        DeleteFile2(FileName);
      fmSaveTime:
      begin
        Params.ReceiptFileTime := GetLastWriteTime(FileName);
      end;
    end;
  end;
end;

procedure TFileManager.ZReportProcessed(const FileName: string);
begin
  if FileExists(FileName) then
  begin
    case Params.ReportMode of
      fmMove:
      begin
        CreateDirectory(Params.ProcessedReportPath);
        MoveFile2(FileName, IncludeTrailingBackSlash(Params.ProcessedReportPath) +
          ExtractFileName(FileName));
      end;
      fmDelete:
        DeleteFile2(FileName);
      fmSaveTime:
        Params.ReportFileTime := GetLastWriteTime(FileName);
    end;
  end;
end;

// �������� ����� Z-������

procedure TFileManager.CheckZReportFiles;
var
  i: Integer;
  FileName: string;
  FileNames: TFileNames;
begin
  FileNames := TFileNames.Create;
  try
    // ���� Z ����� �������� - �������
    if not Params.ZReportEnabled then Exit;

    if Params.ReportMode = fmSaveTime then
      FileNames.FindByTime(Params.ZReportMask, Params.ReportFileTime)
    else
      FileNames.FindByMask(Params.ZReportMask);

    for i := 0 to FileNames.Count-1 do
    begin
      CheckStopFlag;
      FileName := FileNames[i];
      if IsReportFile(FileName) then
      begin
        AddLog('������ ���� "' + FileNames[i] + '" � ����� Z-�������.');
        // �������� ���������
        CheckPrinterStatus;
        PrintZReport(FileName);
      end;
    end;
  finally
    FileNames.Free;
  end;
end;

procedure TFileManager.SetState(const Value: string);
begin
  AddLog(Value);
  FState := Value;
  SendEvent(Self, ctState, '');
end;

procedure TFileManager.WriteLogHeader;
const
  BoolTostr: array [Boolean] of string = ('[ ]', '[X]');
  FileModeToStr: array [TFileMode] of string = (
    '���������� ������������ ����� � �����',
    '������� ������������ �����',
    '���������� ���� ���������� ������������� �����');
begin
  LogFile.AddSeparator;
  LogFile.AddLine(' ����X-�: ������� �����, ������: ' + GetFileVersionInfoStr);
  LogFile.AddLine('');
  LogFile.AddLine(' ��������� ����������:');
  LogFile.AddLine('');
  LogFile.AddLine(' �������� �����-���                 : ' + BoolToStr[Params.BarcodeEnabled]);
  LogFile.AddLine(' �������� ������� ����� ��� ������� : ' + BoolToStr[Params.AutoStartSrv]);
  LogFile.AddLine(' ���������� �������                 : ' + BoolToStr[Params.PollPrinter]);
  LogFile.AddLine(' ������ �������������� ��           : ' + IntToStr(Params.DriverPassword));
  LogFile.AddLine(' ����� ������ �����                 : ' + Params.ReceiptMask);
  LogFile.AddLine(' ����� ������ Z-�������             : ' + Params.ZReportMask);
  LogFile.AddLine(' ������� ������� � �����            : ' + Params.ReturnSale);
  LogFile.AddLine(' ����� �����                        : ' + FileModeToStr[Params.ReceiptMode]);
  LogFile.AddLine(' ����� �����                        : ' + Params.ProcessedReceiptPath);
  LogFile.AddLine(' ���� ���������� ����               : ' +
    FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', Params.ReceiptFileTime));
  LogFile.AddLine(' ��������� ������ Z-�������         : ' + BoolToStr[Params.ZReportEnabled]);
  LogFile.AddLine(' ����� �������                      : ' + FileModeToStr[Params.ReportMode]);
  LogFile.AddLine(' ����� �������                      : ' + Params.ProcessedReportPath);
  LogFile.AddLine(' ���� ���������� ������             : ' +
    FormatDateTime('dd.mm.yyyy hh:nn:ss.zzz', Params.ReportFileTime));

  LogFile.AddLine(' ���������� ��������� ����          : ' + BoolToStr[Params.CopyErrorReceipts]);
  LogFile.AddLine(' ����� ��������� �����              : ' + Params.ErrorReceiptPath);

  LogFile.AddSeparator;
end;

procedure TFileManager.CheckPrinterStatus;
begin
  Lock;
  try
    Printer.Connect;
    Printer.CheckStatus;
  finally
    //Printer.Disconnect; !!!
    Unlock;
  end;
end;

// ��������� ��� ������

procedure TFileManager.ThreadProc(Sender: TObject);
begin
  FStopFlag := False;
  try
    WriteLogHeader;
    // ������ �������� �����
    SetState('������� ����� �����������...');
    OleCheck(CoInitialize(nil));
    try
      Printer.SetPassword(Params.DriverPassword);
      Logger.AddLine('����������� � ��');
      CheckPrinterStatus;
      SetState('������� ����� ��������');
      repeat
        CheckStopFlag;
        try
          // �������� ��������� ���
          if Params.PollPrinter then
            CheckPrinterStatus;
          // �������� ������
          CheckZReportFiles;
          CheckReceiptFiles;
          Sleep(500);
        except
          on E: Exception do
          begin
            if E is EAbort then Break;
            AddLog('������: ' + E.Message);
            Sleep(5000);
          end;
        end;
      until False;
    finally
      CoUninitialize;
    end;
  except
    on E: Exception do
    begin
      if not(E is EAbort) then
        AddError(E.Message);
    end;
  end;
  FThread.Terminate;
end;

procedure TFileManager.ThreadTerminated(Sender: TObject);
begin
  SetState('������� ����� ����������');
end;

function TFileManager.Started: Boolean;
begin
  Result := (FThread <> nil)and(not FThread.Terminated);
end;

procedure TFileManager.AddError(const S: string);
begin
  AddLog(S);
  SendEvent(Self, ctError, S);
end;

procedure TFileManager.AddLog(const S: string);
begin
  Logger.AddLine(S);
  LogFile.AddLine(S);
end;

procedure TFileManager.Start;
begin
  if Started then Exit;
  FThread := TNotifyThread.CreateThread(ThreadProc);
  FThread.OnTerminate := ThreadTerminated;
end;

procedure TFileManager.Stop;
begin
  FPrinter.Stop;
  FStopFlag := True;
  FThread.Free;
  FThread := nil;
end;

procedure TFileManager.SendEvent(Sender: TObject; AEventType: TEventType;
  const S: string);
begin
  if Assigned(FOnEvent) then FOnEvent(Sender, AEventType, S);
end;

procedure TFileManager.Initialize;
begin
  if Params.AutostartSrv then Start;
end;

// ������ Z-������

procedure TFileManager.PrintZReport(const FileName: string);
begin
  Lock;
  try
    Printer.Connect;
    // ������ ������
    Printer.PrintZReport;
    ZReportProcessed(FileName);
    // �������� ���������� ������
    Printer.CheckStatus;
    AddLog('Z-����� ������� ����������');
    // ������ ����������
    Printer.CashOutcome;
  finally
    Printer.Disconnect;
    Unlock;
  end;
end;

end.
