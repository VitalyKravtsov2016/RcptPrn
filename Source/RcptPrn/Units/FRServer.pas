unit FRServer;

interface

uses
  // VCL
  Windows, ComObj, IniFiles, SysUtils, Classes, FileCtrl, SyncObjs, Graphics,
  ExtCtrls, ActiveX, Forms,
  // This
  NotifyThread, Receipt, Barcode, untVInfo, ServerParams, DrvFRLib_TLB;

type
  TEventType = (ctLog, ctState, ctError);
  TServerEvent = procedure (Sender: TObject; EventType: TEventType; const S: string) of object;

  { TFRServer }

  TFRServer = class
  private
    FDriver: IDrvFR;
    FState: string;
    FDataPath: string;
    FErrorText: string;
    FReceipt: TReceipt;
    FThread: TNotifyThread;
    FParams: TServerParams;
    FOnEvent: TServerEvent;

    procedure GetFRStatus;
    procedure PrintReceipt;
    procedure CheckFRStatus;
    procedure CheckReceiptFiles;
    function GetDriver: IDrvFR;
    procedure CheckZReportFiles;
    function GetPrintWidth: Integer;
    procedure AddLog(const S: string);
    procedure LoadImage(Image: TImage);
    procedure AddError(const S: string);
    procedure ThreadProc(Sender: TObject);
    procedure SetState(const Value: string);
    procedure ThreadTerminated(Sender: TObject);
    procedure SetReceiptTax(ReceiptTax: Integer);
    procedure PrintZReport(const FileName: string);
    procedure ZReportProcessed(const FileName: string);
    procedure ReceiptProcessed(const FileName: string);
    function GetLineData(Image: TImage; Index: Integer): string;
    procedure SendEvent(AEventType: TEventType; const S: string);

    property Receipt: TReceipt read FReceipt;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Stop;
    procedure Start;
    procedure Initialize;
    function Started: Boolean;
    procedure ShowDriverProperties;
    procedure Check(ResultCode: Integer);
    procedure PrintFile(const FileName: string);
    procedure PrintBarcode(BarCodeText: string);

    property State: string read FState;
    property Driver: IDrvFR read GetDriver;
    property ErrorText: string read FErrorText;
    property Params: TServerParams read FParams;
    property OnEvent: TServerEvent read FOnEvent write FOnEvent;
  end;

  EDriverError = class(Exception);

procedure FindFileNames(const Mask: string; FileNames: TStrings);

implementation

procedure DeleteFile2(const FileName: string);
var
  S: string;
begin
  repeat
    if FileExists(FileName) and (not DeleteFile(FileName)) then
    begin
      S := '�� ������� ������� ���� "%s".'#13#10'��������� �������?';
      if MessageBox(Application.Handle, PChar(S), PChar(Application.Title),
        MB_YESNO or MB_ICONEXCLAMATION) = ID_NO then
        raise Exception.Create(S);
    end else
    begin
      Break;
    end;
  until False;
end;

procedure MoveFile2(const SrcFileName, DstFileName: string);
begin
  DeleteFile2(DstFileName);
  if not MoveFile(PChar(SrcFileName), PChar(DstFileName)) then
    raise Exception.CreateFmt('�� ������� ����������� ���� "%s"'#13#10+
    '� ����� "%s".', [SrcFileName, ExtractFilePath(DstFileName)]);
end;

/////////////////////////////////////////////////////////////////////
// ����� ������ �� �����

procedure FindFileNames(const Mask: string; FileNames: TStrings);
var
  F: TSearchRec;
  Result: Integer;
  FileName: string;
begin
  Result := FindFirst(Mask, faAnyFile, F);
  while Result = 0 do
  begin
    FileName := ExtractFilePath(Mask) + F.FindData.cFileName;
    FileNames.Add(FileName);
    Result := FindNext(F);
  end;
  FindClose(F);
end;

///////////////////////////////////////////////////////////////////////////////
// ����� ������ �� ����� � ����������� ����� ��������� ������ MinFileTime

procedure AddFile(const Path: string; FileNames: TStrings;
  MinFileTime: _FILETIME; const FindData: TWin32FindData);
var
  FileName: string;
begin
  if CompareFileTime(FindData.ftLastWriteTime, MinFileTime) > 0 then
  begin
    FileName := ExtractFilePath(Path) + String(FindData.cFileName);
    FileNames.Add(FileName);
  end;
end;

procedure FindFileNames2(const Path: string; FileNames: TStrings;
  MinFileTime: _FILETIME);
var
  F: TSearchRec;
  FindData: TWin32FindData;
  FindHandle: THandle;
begin
  FindHandle := FindFirstFile(PChar(Path), FindData);
  if FindHandle <> INVALID_HANDLE_VALUE then
  begin
    AddFile(Path, FileNames, MinFileTime, FindData);
    while FindNextFile(FindHandle, FindData) do
      AddFile(Path, FileNames, MinFileTime, FindData);
    FindClose(F);
  end;
end;

// ���������� � ��������� ����������

procedure SaveStrings(Strings: TStrings; const FileName: string);
var
  Dir: string;
begin
  Dir := ExtractFilePath(FileName);
  if not DirectoryExists(Dir) then CreateDir(Dir);
  Strings.SaveToFile(FileName);
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

{ TFRServer }

constructor TFRServer.Create;
begin
  inherited Create;
  FReceipt := TReceipt.Create;
  FParams := TServerParams.Create;
  FDataPath := ExtractFilePath(ParamStr(0)) + 'Data';
  Params.LoadFromIniFile;
  SetState('������� ����� ����������');
end;

destructor TFRServer.Destroy;
begin
  Stop;
  Params.SaveToIniFile;
  FThread.Free;
  FReceipt.Free;
  FParams.Free;
  FDriver := nil;
  inherited Destroy;
end;

function TFRServer.GetDriver: IDrvFR;
begin
  if FDriver = nil then
    FDriver := IUnknown(CreateOleObject('Addin.DrvFR')) as IDrvFR;
  Result := FDriver;
end;

procedure TFRServer.ShowDriverProperties;
begin
  Driver.ShowProperties;
end;

{ ��������  ���������� }

procedure TFRServer.Check(ResultCode: Integer);
begin
  if ResultCode <> 0 then
    raise EDriverError.CreateFmt('������ ��: %d, %s.',
      [ResultCode, Driver.ResultCodeDescription]);
end;

// ������ ����

procedure TFRServer.PrintReceipt;
var
  i: Integer;
begin
  // ��� ������
  if not Receipt.IsCashPayment then
  begin
    Driver.TableNumber := 5;
    Driver.RowNumber := 2;
    Driver.FieldNumber := 1;
    Driver.ValueOfFieldString := Receipt.PaymentType;
    Check(Driver.WriteTable);
  end;
  // �������
  Driver.Tax1 := 0;
  Driver.Tax2 := 0;
  Driver.Tax3 := 0;
  Driver.Tax4 := 0;
  Driver.Quantity := 1;
  Driver.StringForPrinting := '';
  Driver.Price := Receipt.Summ + Receipt.Discount;
  Driver.DiscountOnCheck := 0;
  Driver.Department := 1;
  // ���������� ������� �� ���
  if Receipt.Tax <> 0 then
    SetReceiptTax(Receipt.Tax);
  // ������� ��� �������
  if Receipt.PaymentType <> Params.ReturnSale then
    Check(Driver.Sale)
  else
    Check(Driver.ReturnSale);


  // �������� ���������� �����������
  Driver.StringForPrinting := Receipt.Lines[0];
  Check(Driver.PrintString);


  // �� ����
  if Receipt.TicketBarCode <> '' then
    PrintBarcode(Receipt.TicketBarCode);
  // ����� ����
  for i := 0 to Receipt.Lines.Count-1 do
  begin
    Driver.StringForPrinting := Receipt.Lines[i];
    Check(Driver.PrintString);
  end;

  // ������
  if Receipt.Discount <> 0 then
  begin
    Driver.Summ1 := Receipt.Discount;
    Check(Driver.Discount);
  end;
  // �������� ����
  Driver.Summ1 := 0;
  Driver.Summ2 := 0;
  Driver.Summ3 := 0;
  Driver.Summ4 := 0;
  Driver.StringForPrinting := '';
  if Receipt.Tax <> 0 then
    Driver.Tax1 := 1
  else
    Driver.Tax1 := 0;
  Driver.Tax2 := 0;
  Driver.Tax3 := 0;
  Driver.Tax4 := 0;
  // �������� ��� ������
  if Receipt.ClientSumm = 0 then         // ���� ����� ���� = ����� �������
  begin
    if not Receipt.IsCashPayment then
    begin
      Driver.Summ2 := Receipt.Summ;
    end else
    begin
      Driver.Summ1 := Receipt.Summ;      // ������ ���������
    end;
  end else
  begin
    Driver.Summ1 := Receipt.ClientSumm;  // ��������� �� ������
  end;
  Check(Driver.CloseCheck);
  CheckFRStatus;
end;

procedure TFRServer.PrintFile(const FileName: string);
begin
  if FThread.Terminated then Abort;
  AddLog(Format('������ ���� "%s"', [FileName]));
  try
    Receipt.LoadFromFile(FileName);
    CheckFRStatus;
    PrintReceipt;
    CheckFRStatus;
    AddLog(Format('������ ����� "%s" ������� ���������', [FileName]));
  except
    on E: Exception do
      AddLog(Format('������ ��� ��������� ����� "%s": %s', [FileName, E.Message]));
  end;
  ReceiptProcessed(FileName);
end;

// �������� ����� ������

procedure TFRServer.CheckReceiptFiles;
var
  i: Integer;
  FileName: string;
  FileNames: TStrings;
begin
  FileNames := TStringList.Create;
  try
    if Params.ReceiptMode = fmSaveTime then
      FindFileNames2(Params.ReceiptMask, FileNames, Params.ReceiptFileTime)
    else
      FindFileNames(Params.ReceiptMask, FileNames);

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

procedure TFRServer.ReceiptProcessed(const FileName: string);
begin
  if FileExists(FileName) then
  begin
    case Params.ReceiptMode of
      fmMove:
        MoveFile2(FileName, Params.ProcessedReceiptPath + ExtractFileName(FileName));
      fmDelete:
        DeleteFile2(FileName);
      fmSaveTime:
      begin
        Params.ReceiptFileTime := GetLastWriteTime(FileName);
      end;
    end;
  end;
end;

procedure TFRServer.ZReportProcessed(const FileName: string);
begin
  if FileExists(FileName) then
  begin
    case Params.ReportMode of
      fmMove:
        MoveFile2(FileName, Params.ProcessedReportPath + ExtractFileName(FileName));
      fmDelete:
        DeleteFile2(FileName);
      fmSaveTime:
        Params.ReportFileTime := GetLastWriteTime(FileName);
    end;
  end;
end;

// ������ Z-������

procedure TFRServer.PrintZReport(const FileName: string);
var
  i: Integer;
  Count: Integer;
  CashSum: Int64;
const
  // ������������ ����� ������� (5 ����)
  MaxCashOutcomeSum = 9999999999;
begin
  AddLog('������ Z-������ ��');
  Check(Driver.PrintReportWithCleaning);
  ZReportProcessed(FileName);
  CheckFRStatus;
  // ������ ����������
  Driver.RegisterNumber := 241;
  Check(Driver.GetCashReg);
  CashSum := Trunc(Driver.ContentsOfCashRegister*100);
  if CashSum > 0 then
  begin
    // ������ ��������� �������� ���������� 6 ����,
    // � ��������� ����� ������ 5 ����
    if CashSum > MaxCashOutcomeSum then
    begin
      Count := CashSum div MaxCashOutcomeSum;
      for i := 0 to Count-1 do
      begin
        Driver.Summ1 := MaxCashOutcomeSum/100;
        Check(Driver.CashOutcome);
        CheckFRStatus;
      end;
    end;
    Driver.Summ1 := (CashSum mod MaxCashOutcomeSum)/100;
    Check(Driver.CashOutcome);
    CheckFRStatus;
  end;
  AddLog('Z-����� ������� ����������');
end;

// �������� ����� Z-������

procedure TFRServer.CheckZReportFiles;
var
  i: Integer;
  FileName: string;
  FileNames: TStrings;
begin
  FileNames := TStringList.Create;
  try
    if Params.ReportMode = fmSaveTime then
      FindFileNames2(Params.ZReportMask, FileNames, Params.ReportFileTime)
    else
      FindFileNames(Params.ZReportMask, FileNames);

    for i := 0 to FileNames.Count-1 do
    begin
      if FThread.Terminated then Abort;
      FileName := FileNames[i];
      if IsReportFile(FileName) then
      begin
        AddLog('������ ���� "' + FileNames[i] + '" � ����� Z-�������.');
        // �������� ���������
        GetFRStatus;
        if Driver.ECRMode in [2,3] then
        begin
          PrintZReport(FileName);
        end else
        begin
          // ���� ����� �� ������� - ������ ������� ���� ������������
          AddLog('����� � �� �� ������� - Z-����� ������ �����������');
          ZReportProcessed(FileName);
        end;
      end;
    end;
  finally
    FileNames.Free;
  end;
end;

procedure TFRServer.SetState(const Value: string);
begin
  AddLog(Value);
  FState := Value;
  SendEvent(ctState, '');
end;

// ��������� ��� ������

procedure TFRServer.ThreadProc(Sender: TObject);
var
  Connected: Boolean;
begin
  try
    // ������ �������� �����
    SetState('������� ����� �����������...');
    OleCheck(CoInitialize(nil));

    CreateDirectory(FDataPath);
    CreateDirectory(Params.ProcessedReportPath);
    CreateDirectory(Params.ProcessedReceiptPath);
    Driver.Password := Params.DriverPassword;
    SetState('������� ����� ��������');

    Connected := True;
    repeat
      try
        if not Connected then
        begin
          Receipt.PrintWidth := GetPrintWidth;
          CheckFRStatus;
          if Driver.ECRMode = 8 then
          begin
            Check(Driver.CancelCheck);
            AddLog('��� �����������');
          end;
          Connected := True;
        end;

        // � ������ ����� ���������� � FThread
        if FThread.Terminated then Abort;

        CheckZReportFiles;
        CheckReceiptFiles;
        CheckFRStatus;
        Sleep(100);
      except
        on E: Exception do
        begin
          if E is EAbort then Break;
          AddLog('������: ' + E.Message);
          Sleep(1000);
        end;
      end;
    until False;
    Driver.Disconnect;
    CoUninitialize;
  except
    on E: Exception do
    begin
      if not(E is EAbort) then
        AddError(E.Message);
    end;
  end;
  FThread.Terminate;
end;

procedure TFRServer.ThreadTerminated(Sender: TObject);
begin
  SetState('������� ����� ����������');
end;

function TFRServer.Started: Boolean;
begin
  Result := (FThread <> nil)and(not FThread.Terminated);
end;

procedure TFRServer.AddError(const S: string);
begin
  AddLog(S);
  FErrorText := S;
  SendEvent(ctError, '');
end;

procedure TFRServer.AddLog(const S: string);
begin
  SendEvent(ctLog, Format('[%s] %s', [TimeToStr(Time), S]));
end;

procedure TFRServer.Start;
begin
  if Started then Exit;
  FThread := TNotifyThread.CreateThread(ThreadProc);
  FThread.OnTerminate := ThreadTerminated;
end;

procedure TFRServer.Stop;
begin
  FThread.Free;
  FThread := nil;
end;

function TFRServer.GetPrintWidth: Integer;
begin
  Check(Driver.GetDeviceMetrics);
  case Driver.UModel of
     0: Result := 36;   // �����-��-�
     1: Result := 36;   // �����-��-� (���������)
     2: Result := 24;   // �����-����-��-�
     3: Result := 20;   // ������-� �
     4: Result := 36;   // �����-��-�
     5: Result := 40;   // �����-950�
     6: Result := 32;   // �����-��-�
     7: Result := 50;   // �����-����-��-�
     8: Result := 36;   // �����-��-� (����������)
     9: Result := 48;   // �����-�����-��-� ������ 1
    10: Result := 40;   // ���������� ���� �����-POS-�
    11: Result := 40;   // �����950K ������ 2
    12: Result := 40; 	// �����-�����-��-� ������ 2
    14: Result := 50; 	// �����-����-��-� 2
  else
    Result := 48;
  end;
end;

procedure TFRServer.GetFRStatus;
begin
  if Driver.UModel > 2 then
  begin
    Check(Driver.GetShortECRStatus);
  end else
  begin
    Check(Driver.GetECRStatus);
  end;
end;

// �������� ��������� ��

procedure TFRServer.CheckFRStatus;
begin
  repeat
    GetFRStatus;
    // 0. ���� �� ������ �� ��������, �� ��������� ������
    if Driver.ECRAdvancedMode = 0 then
    begin
      case Driver.ECRMode of
        1:
        begin
          Check(Driver.InterruptDataStream);
          AddLog('������ ������ ��������');
        end;
        3:
        begin
          PrintZReport('');
        end;
        5: // �� ������������
        begin
          raise Exception.Create(
            '�� ������������ ��-�� ����� ������������� ' +
            '������ ���������� ����������');
        end;
        9: // ���. ���������
        begin
          raise Exception.Create('�� ��������� � ������ ���������������� ���������');
        end;
        10:
        begin
          Check(Driver.InterruptTest);
          AddLog('�������� ������ �������');
        end;
        11, 12:
        begin
          Sleep(1000);
        end;
      else
        Exit;
      end;
    end;
    // ���� �� ������ �� ��������, ������ ���
    if (Driver.ECRAdvancedMode = 1) or
       (Driver.ECRAdvancedMode = 2) then
    begin
      // ���� ������ ������, ���� ������ �� �����������
      if MessageBox(0, PChar('�������� ������ � �� � ������� ��.'),
         PChar(Application.Title), MB_ICONERROR + MB_OKCANCEL) = idCancel
      then
        Abort;
    end;
    // ���������� ������
    if Driver.ECRAdvancedMode = 3 then
      Check(Driver.ContinuePrint);

    if Driver.ECRAdvancedMode in [4, 5] then
      Sleep(1000);
  until false;
end;

procedure TFRServer.SendEvent(AEventType: TEventType; const S: string);
begin
  if Assigned(FOnEvent) then FOnEvent(Self, AEventType, S);
end;

procedure TFRServer.PrintBarcode(BarCodeText: string);
var
  Barcode: TAsBarCode;
  Image: TImage;
begin
  if not Params.BarcodeEnabled then Exit;
  Driver.StringForPrinting := StringOfChar(' ', 6) + Copy(BarCodeText, 2,
                              Length(BarCodeText) - 1) + '  ' + Receipt.CheckDateTime;
  Check(Driver.PrintString);
  Image := TImage.Create(nil);
  Barcode := TAsBarCode.Create(nil);
  try
    Image.Visible := False;
    Image.Picture := nil;
    Image.Width := 320;
    Image.Height := 100;
    Barcode.Text := BarCodeText;
    Barcode.Top := 0;
    Barcode.Left := 20;
    Barcode.Typ := bcCodeEAN128A;
    Barcode.Modul := 1;
    Barcode.Ratio := 2.0;
    Barcode.Height := 100;
    Barcode.Width := 300;
    Image.Picture := nil;
    Barcode.DrawBarcode(Image.Canvas);
    LoadImage(Image);
  finally
    Image.Free;
    Barcode.Free;
  end;
end;

function TFRServer.GetLineData(Image: TImage; Index: Integer): string;
const
  Bits: array[0..7] of Byte = (1,2,4,8,$10,$20,$40,$80);
var
  Data: Byte;
  i, j: Integer;
  ImageWidth: Integer;
begin
  Result := '';
  ImageWidth := Image.Picture.Width;
  for i := 0 to 39 do
  begin
    Data := 0;
    for j := 0 to 7 do
    begin
      if (8*i+j) <= ImageWidth then
      begin
        if (Image.Canvas.Pixels[8*i + j, Index] = clBlack)or
          (Image.Canvas.Pixels[8*i+j, Index] = 0) then
        Data := Data + Bits[j];
      end;
    end;
    Result := Result + Chr(Data);
  end;
end;

procedure TFRServer.LoadImage(Image: TImage);
var
  i: Integer;
  Count: Integer;
begin
  if Image.Picture.Graphic = nil then Exit;

  Count := Image.Picture.Height;
  if Count > 200 then Count := 200;
  for i := 0 to Count-1 do
  begin
    Driver.LineNumber := i;
    Driver.LineData := GetLineData(Image, i);
    Check(Driver.LoadLineData);
  end;
  Driver.FirstLineNumber := 1;
  Driver.LastLineNumber := Count;
  Check(Driver.Draw);
end;

procedure TFRServer.SetReceiptTax(ReceiptTax: Integer);
var
  FieldNumber: Integer;
begin
  case Driver.UModel of
    0  : FieldNumber := 17;   // �����-��-�
    1  : FieldNumber := 17;   // �����-��-� (���������)
    2  : FieldNumber := 17;   // �����-����-��-�
    3  : FieldNumber := 17;   // ������-� �
    4  : FieldNumber := 17;   // �����-��-�
    5  : FieldNumber := 16;   // �����-950�
    6  : FieldNumber := 14;   // �����-��-�
    7  : FieldNumber := 15;   // �����-����-��-�
    8  : FieldNumber := 17;   // �����-��-� (����������)
    9  : FieldNumber := 15;   // �����-�����-��-� ������ 1
    11 : FieldNumber := 16;   // �����950K ������ 2
    12 : FieldNumber := 15;   // �����-�����-��-� ������ 2
    14 : FieldNumber := 15;   // �����-����-��-� 2
  else
    Raise Exception.Create('����������� ��� ����������');
  end;
  Driver.TableNumber := 1;
  Driver.RowNumber := 1;
  Driver.FieldNumber := FieldNumber;
  Driver.ValueOfFieldInteger := 1;
  Check(Driver.WriteTable);

  Driver.TableNumber := 6;
  Driver.RowNumber := 1;
  Driver.FieldNumber := 1;
  Driver.ValueOfFieldInteger := Receipt.Tax;
  Check(Driver.WriteTable);
end;

procedure TFRServer.Initialize;
begin
  if Params.AutostartSrv then Start;
end;

end.
