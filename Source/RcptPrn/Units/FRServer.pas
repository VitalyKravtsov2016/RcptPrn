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
      S := 'Не удалось удалить файл "%s".'#13#10'Повторить попытку?';
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
    raise Exception.CreateFmt('Не удалось переместить файл "%s"'#13#10+
    'в папку "%s".', [SrcFileName, ExtractFilePath(DstFileName)]);
end;

/////////////////////////////////////////////////////////////////////
// Поиск файлов по маске

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
// Поиск файлов по маске с минимальной датой последней записи MinFileTime

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

// Сохранение с созданием директории

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
      raise Exception.Create(Format('Не удалось создать папку %s', [DirPath]));
end;

// Проверка файла отчета
// Файл чека имеет другой формат

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
  SetState('Принтер чеков остановлен');
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

{ Проверка  результата }

procedure TFRServer.Check(ResultCode: Integer);
begin
  if ResultCode <> 0 then
    raise EDriverError.CreateFmt('Ошибка ФР: %d, %s.',
      [ResultCode, Driver.ResultCodeDescription]);
end;

// Печать чека

procedure TFRServer.PrintReceipt;
var
  i: Integer;
begin
  // Тип оплаты
  if not Receipt.IsCashPayment then
  begin
    Driver.TableNumber := 5;
    Driver.RowNumber := 2;
    Driver.FieldNumber := 1;
    Driver.ValueOfFieldString := Receipt.PaymentType;
    Check(Driver.WriteTable);
  end;
  // Продажа
  Driver.Tax1 := 0;
  Driver.Tax2 := 0;
  Driver.Tax3 := 0;
  Driver.Tax4 := 0;
  Driver.Quantity := 1;
  Driver.StringForPrinting := '';
  Driver.Price := Receipt.Summ + Receipt.Discount;
  Driver.DiscountOnCheck := 0;
  Driver.Department := 1;
  // Начисление налогов на чек
  if Receipt.Tax <> 0 then
    SetReceiptTax(Receipt.Tax);
  // Продажа или возврат
  if Receipt.PaymentType <> Params.ReturnSale then
    Check(Driver.Sale)
  else
    Check(Driver.ReturnSale);


  // Печатаем лидирующий разделитель
  Driver.StringForPrinting := Receipt.Lines[0];
  Check(Driver.PrintString);


  // ШК Чека
  if Receipt.TicketBarCode <> '' then
    PrintBarcode(Receipt.TicketBarCode);
  // Текст чека
  for i := 0 to Receipt.Lines.Count-1 do
  begin
    Driver.StringForPrinting := Receipt.Lines[i];
    Check(Driver.PrintString);
  end;

  // Скидка
  if Receipt.Discount <> 0 then
  begin
    Driver.Summ1 := Receipt.Discount;
    Check(Driver.Discount);
  end;
  // Закрытие чека
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
  // Выбираем тип оплаты
  if Receipt.ClientSumm = 0 then         // Если сумма чека = сумме клиента
  begin
    if not Receipt.IsCashPayment then
    begin
      Driver.Summ2 := Receipt.Summ;
    end else
    begin
      Driver.Summ1 := Receipt.Summ;      // Оплата наличными
    end;
  end else
  begin
    Driver.Summ1 := Receipt.ClientSumm;  // Наличными со сдачей
  end;
  Check(Driver.CloseCheck);
  CheckFRStatus;
end;

procedure TFRServer.PrintFile(const FileName: string);
begin
  if FThread.Terminated then Abort;
  AddLog(Format('Найден файл "%s"', [FileName]));
  try
    Receipt.LoadFromFile(FileName);
    CheckFRStatus;
    PrintReceipt;
    CheckFRStatus;
    AddLog(Format('Печать файла "%s" успешно завершена', [FileName]));
  except
    on E: Exception do
      AddLog(Format('Ошибка при обработке файла "%s": %s', [FileName, E.Message]));
  end;
  ReceiptProcessed(FileName);
end;

// Проверка новых файлов

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

// Печать Z-отчета

procedure TFRServer.PrintZReport(const FileName: string);
var
  i: Integer;
  Count: Integer;
  CashSum: Int64;
const
  // Максимальная сумма выплаты (5 байт)
  MaxCashOutcomeSum = 9999999999;
begin
  AddLog('Печать Z-отчета ФР');
  Check(Driver.PrintReportWithCleaning);
  ZReportProcessed(FileName);
  CheckFRStatus;
  // Полная инкассация
  Driver.RegisterNumber := 241;
  Check(Driver.GetCashReg);
  CashSum := Trunc(Driver.ContentsOfCashRegister*100);
  if CashSum > 0 then
  begin
    // Запрос денежного регистра возвращает 6 байт,
    // а выплатить можно только 5 байт
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
  AddLog('Z-отчет успешно распечатан');
end;

// Проверка файла Z-Отчета

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
        AddLog('Найден файл "' + FileNames[i] + '" в папке Z-отчетов.');
        // Проверка состояния
        GetFRStatus;
        if Driver.ECRMode in [2,3] then
        begin
          PrintZReport(FileName);
        end else
        begin
          // Если смена не открыта - просто считаем файл обработанным
          AddLog('Смена в ФР не открыта - Z-отчет нельзя распечатать');
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

// Процедура для потока

procedure TFRServer.ThreadProc(Sender: TObject);
var
  Connected: Boolean;
begin
  try
    // Запуск принтера чеков
    SetState('Принтер чеков запускается...');
    OleCheck(CoInitialize(nil));

    CreateDirectory(FDataPath);
    CreateDirectory(Params.ProcessedReportPath);
    CreateDirectory(Params.ProcessedReceiptPath);
    Driver.Password := Params.DriverPassword;
    SetState('Принтер чеков работает');

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
            AddLog('Чек аннулирован');
          end;
          Connected := True;
        end;

        // В потоке можно обращаться к FThread
        if FThread.Terminated then Abort;

        CheckZReportFiles;
        CheckReceiptFiles;
        CheckFRStatus;
        Sleep(100);
      except
        on E: Exception do
        begin
          if E is EAbort then Break;
          AddLog('Ошибка: ' + E.Message);
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
  SetState('Принтер чеков остановлен');
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
     0: Result := 36;   // ШТРИХ-ФР-Ф
     1: Result := 36;   // ШТРИХ-ФР-Ф (Казахстан)
     2: Result := 24;   // ЭЛВЕС-МИНИ-ФР-Ф
     3: Result := 20;   // ФЕЛИКС-Р Ф
     4: Result := 36;   // ШТРИХ-ФР-К
     5: Result := 40;   // ШТРИХ-950К
     6: Result := 32;   // ЭЛВЕС-ФР-К
     7: Result := 50;   // ШТРИХ-МИНИ-ФР-К
     8: Result := 36;   // ШТРИХ-ФР-Ф (Белоруссия)
     9: Result := 48;   // ШТРИХ-КОМБО-ФР-К версии 1
    10: Result := 40;   // Фискальный блок Штрих-POS-Ф
    11: Result := 40;   // Штрих950K версия 2
    12: Result := 40; 	// ШТРИХ-КОМБО-ФР-К версии 2
    14: Result := 50; 	// ШТРИХ-МИНИ-ФР-К 2
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

// Проверка состояния ФР

procedure TFRServer.CheckFRStatus;
begin
  repeat
    GetFRStatus;
    // 0. Если ФР ничего не печатает, то проверяем режимы
    if Driver.ECRAdvancedMode = 0 then
    begin
      case Driver.ECRMode of
        1:
        begin
          Check(Driver.InterruptDataStream);
          AddLog('Выдача данных прервана');
        end;
        3:
        begin
          PrintZReport('');
        end;
        5: // ФР заблокирован
        begin
          raise Exception.Create(
            'ФР заблокирован из-за ввода неправильного ' +
            'пароля налогового инспектора');
        end;
        9: // Тех. обнуление
        begin
          raise Exception.Create('ФР находится в режиме технологического обнуления');
        end;
        10:
        begin
          Check(Driver.InterruptTest);
          AddLog('Тестовый прогон прерван');
        end;
        11, 12:
        begin
          Sleep(1000);
        end;
      else
        Exit;
      end;
    end;
    // Если ФР ничего не печатает, бумаги нет
    if (Driver.ECRAdvancedMode = 1) or
       (Driver.ECRAdvancedMode = 2) then
    begin
      // Ждем подачи бумаги, либо отказа от продолжения
      if MessageBox(0, PChar('Вставьте бумагу в ФР и нажмите ОК.'),
         PChar(Application.Title), MB_ICONERROR + MB_OKCANCEL) = idCancel
      then
        Abort;
    end;
    // Продолжаем печать
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
    0  : FieldNumber := 17;   // ШТРИХ-ФР-Ф
    1  : FieldNumber := 17;   // ШТРИХ-ФР-Ф (Казахстан)
    2  : FieldNumber := 17;   // ЭЛВЕС-МИНИ-ФР-Ф
    3  : FieldNumber := 17;   // ФЕЛИКС-Р Ф
    4  : FieldNumber := 17;   // ШТРИХ-ФР-К
    5  : FieldNumber := 16;   // ШТРИХ-950К
    6  : FieldNumber := 14;   // ЭЛВЕС-ФР-К
    7  : FieldNumber := 15;   // ШТРИХ-МИНИ-ФР-К
    8  : FieldNumber := 17;   // ШТРИХ-ФР-Ф (Белоруссия)
    9  : FieldNumber := 15;   // ШТРИХ-КОМБО-ФР-К версии 1
    11 : FieldNumber := 16;   // Штрих950K версия 2
    12 : FieldNumber := 15;   // ШТРИХ-КОМБО-ФР-К версии 2
    14 : FieldNumber := 15;   // ШТРИХ-МИНИ-ФР-К 2
  else
    Raise Exception.Create('Неизвестный тип устройства');
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
