unit FiscalPrinter;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Forms, Graphics, ExtCtrls, ComObj, IniFiles,
  // Tnt
  TntClasses,
  // This
  DrvFRLib_TLB, Receipt, ServerParams, Barcode, untUtil, AppLogger,
  FiscalPrinterIntf, untLogFile;

const
  /////////////////////////////////////////////////////////////////////////////
  // MessageID constants

  MessageIDNoPaper = 0;
  MessageIDPaperOK = 1;

type
  EFiscalPrinter = class(Exception);

  { TPrinterEventObject }

  TPrinterEventObject = class(TObject)
  private
    FID: Integer;
  public
    constructor Create(AID: Integer);
    property ID: Integer read FID;
  end;
  TPrinterEvent = procedure(Sender: TObject; const Event: TPrinterEventObject) of Object;

  { TZReportRec }

  TZReportRec = record
    Number: Integer;
    DateTime: TDateTime;
    RegNumber: string;
    SerialNumber: string;
    InnNumber: string;
    FSNumber: string;
    CashierName: string;
    TaxServiceSite: string;
    DocumentNumber: Integer;
    OperReg: array [0..255] of Integer;
    CashReg: array [0..255] of Currency;
  end;

  { TFiscalPrinter }

  TFiscalPrinter = class(TInterfacedObject, IFiscalPrinter)
  private
    FDriver: TDrvFR;
    FStopFlag: Boolean;
    FHasPaper: Boolean;
    FConnected: Boolean;
    FPrintWidth: Integer;
    FHeader: TTntStrings;
    FTrailer: TTntStrings;
    FOnEvent: TPrinterEvent;
    FCapPrintBarcodeLine: Boolean;

    procedure CheckStopFlag;
    procedure DoCheckStatus;
    procedure CheckStatusReceipt;
    function ReadPrintWidth: Integer;
    procedure LoadImage(Image: TImage);
    function GetTaxFieldNumber: Integer;
    procedure PrintBarcode(BarCodeText, DateTimeText: string);
    function GetLineData(Image: TImage; Index: Integer): string;
    procedure Check(ResultCode: Integer; const Operation: string);
    procedure WriteTable(Table, Row, Field, Value: Integer); overload;
    procedure WriteTable(Table, Row, Field: Integer; const Value: string); overload;

    property Driver: TDrvFR read FDriver;
    procedure PrintBarcodeImage(BarCodeText, DateTimeText: string);
    procedure FeedLine;
    procedure PrintReceiptCopy;
    procedure WaitForPrintSilent;
    function ReadRecText(FirstNumber, Count: Integer): string;
    procedure PrintLines(Lines: TTntStrings);
    procedure SendEvent(EventID: Integer);
    procedure SetHasPaper(Value: Boolean);
    function ReadZReport: TZReportRec;
    procedure SaveZReportToIniFile(const ZReport: TZReportRec;
      const FilePath: string);
    function ReadTable(Table, Row, Field: Integer): string;
  public
    constructor Create; 
    destructor Destroy; override;

    procedure PrintReceipt2(Receipt: TReceipt; Params: TServerParams);
    procedure SaveZReportToTxtFile(const ZReport: TZReportRec;
      const FilePath: string);
    // IFiscalPrinter
    procedure Stop;
    procedure Connect;
    procedure SaveZReport;
    procedure Disconnect;
    procedure CashOutcome;
    procedure CheckStatus;
    procedure PrintZReport;
    procedure PrintXReport;
    procedure OpenSession;
    procedure ShowProperties;
    function GetConnected: Boolean;
    function GetPrintWidth: Integer;
    function ZReportNotPrinted: Boolean;
    procedure SetPassword(const Value: Integer);
    procedure PrintReceipt(Receipt: TReceipt; Params: TServerParams);
    procedure PrintNonfiscalReceipt(Receipt: TReceipt; Params: TServerParams);

    property HasPaper: Boolean read FHasPaper;
    property Connected: Boolean read GetConnected;
    property PrintWidth: Integer read GetPrintWidth;
    property OnEvent: TPrinterEvent read FOnEvent write FOnEvent;
  end;

implementation

{ TFiscalPrinter }

constructor TFiscalPrinter.Create;
begin
  inherited Create;
  FDriver := TDrvFR.Create(nil);
  FHeader := TTntStringList.Create;
  FTrailer := TTntStringList.Create;
  FHasPaper := True;
  FStopFlag := False;
end;

destructor TFiscalPrinter.Destroy;
begin
  FStopFlag := True;
  FHeader.Free;
  FTrailer.Free;
  FDriver.Free;
  inherited Destroy;
end;

procedure TFiscalPrinter.Check(ResultCode: Integer; const Operation: string);
begin
  if ResultCode <> 0 then
    raise EFiscalPrinter.CreateFmt('Ошибка ФР: %d, %s.',
      [ResultCode, Driver.ResultCodeDescription]);
end;

procedure TFiscalPrinter.Connect;
begin
  if not GetConnected then
  begin
    FStopFlag := False;
    FPrintWidth := ReadPrintWidth;
    FConnected := True;
    FCapPrintBarcodeLine := True;
    FTrailer.Text := ReadRecText(1, 3);
    FHeader.Text := ReadRecText(4, 4);

    FDriver.UseReceiptRibbon := True;
    FDriver.UseSlipDocument := False;
    FDriver.UseJournalRibbon := False;
    Check(FDriver.Connect, 'Connect');
  end;
end;

function TFiscalPrinter.ReadRecText(FirstNumber, Count: Integer): string;
var
  i: Integer;
  Lines: TStrings;
begin
  Lines := TStringList.Create;
  try
    Driver.TableNumber := 4;
    Driver.FieldNumber := 1;
    for i := 1 to Count do
    begin
      Driver.RowNumber := i;
      if Driver.ReadTable <> 0 then Break;
      Lines.Add(Driver.ValueOfFieldString);
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TFiscalPrinter.CheckStopFlag;
begin
  if FStopFlag then Abort;
end;

procedure TFiscalPrinter.DoCheckStatus;
const
  MsgInsertPaper = 'Вставьте бумагу в ФР!';
begin
  Connect;
  try
    repeat
      CheckStopFlag;
      // Запрос состояния
      if Driver.UModel > 2 then
      begin
        Check(Driver.GetShortECRStatus, 'Краткий запрос состояния ФР');
      end else
      begin
        Check(Driver.GetECRStatus, 'Полный запрос состояния ФР');
      end;

      // 0. Если ФР ничего не печатает, то проверяем режимы
      case Driver.ECRAdvancedMode of
        0:
        begin
          case Driver.ECRMode of
            1:
            begin
              Check(Driver.InterruptDataStream, 'Прерывание выдачи данных');
            end;
            3:
            begin
              PrintZReport;
            end;
            5: // ФР заблокирован
            begin
              raise EFiscalPrinter.Create(
                'ФР заблокирован из-за ввода неправильного ' +
                'пароля налогового инспектора');
            end;
            9: // Тех. обнуление
            begin
              raise EFiscalPrinter.Create('ФР находится в режиме технологического обнуления');
            end;
            10:
            begin
              Check(Driver.InterruptTest, 'Прерывание тестового прогона');
            end;
            11, 12:
            begin
              Sleep(1000);
            end;
          else
            Exit;
          end;
        end;
        1, 2:
        begin
          SetHasPaper(False);
        end;
        3:
        begin
          // Продолжаем печать
          Check(Driver.ContinuePrint, 'Продолжение печати');
        end;
        4, 5: Sleep(1000);
      else
        Break;
      end;
    until false;
  finally
    SetHasPaper(True);
  end;
end;

procedure TFiscalPrinter.SetHasPaper(Value: Boolean);
begin
  if Value <> FHasPaper then
  begin
    FHasPaper := Value;
    if Value then SendEvent(MessageIDPaperOK)
    else SendEvent(MessageIDNoPaper);
  end;
end;

procedure TFiscalPrinter.SendEvent(EventID: Integer);
var
  Event: TPrinterEventObject;
begin
  if Assigned(FOnEvent) then
  begin
    Event := TPrinterEventObject.Create(EventID);
    FOnEvent(Self, Event);
  end;
end;

procedure TFiscalPrinter.CheckStatus;
begin
  try
    DoCheckStatus;
  finally
    //Disconnect;
  end;
end;

// Проверка состояния и отмена чека при необходимости

procedure TFiscalPrinter.CheckStatusReceipt;
begin
  CheckStatus;
  if Driver.ECRMode = 8 then
  begin
    Check(Driver.SysAdminCancelCheck, 'SysAdminCancelCheck');
  end;
end;

// Печать Z-отчета

procedure TFiscalPrinter.PrintZReport;
begin
  Check(Driver.GetECRStatus, 'Полный запрос состояния ФР');
  if Driver.ECRMode = 4 then
  begin
    Driver.OpenSession;
  end;
  SaveZReport;
  Check(Driver.PrintReportWithCleaning, 'Печать Z-отчета ФР');
end;

procedure TFiscalPrinter.PrintXReport;
begin
  Check(Driver.PrintReportWithoutCleaning, 'Печать X-отчета ФР');
end;

function TFiscalPrinter.GetTaxFieldNumber: Integer;
begin
  case Driver.UModel of
    0  : Result := 17;   // ШТРИХ-ФР-Ф
    1  : Result := 17;   // ШТРИХ-ФР-Ф (Казахстан)
    2  : Result := 17;   // ЭЛВЕС-МИНИ-ФР-Ф
    3  : Result := 17;   // ФЕЛИКС-Р Ф
    4  : Result := 17;   // ШТРИХ-ФР-К
    5  : Result := 16;   // ШТРИХ-950К
    6  : Result := 14;   // ЭЛВЕС-ФР-К
    7  : Result := 15;   // ШТРИХ-МИНИ-ФР-К
    8  : Result := 17;   // ШТРИХ-ФР-Ф (Белоруссия)
    9  : Result := 15;   // ШТРИХ-КОМБО-ФР-К версии 1
    11 : Result := 16;   // Штрих950K версия 2
    12 : Result := 15;   // ШТРИХ-КОМБО-ФР-К версии 2
    14 : Result := 15;   // ШТРИХ-МИНИ-ФР-К 2
  else
    Raise EFiscalPrinter.Create('Неизвестный тип ФР');
  end;
end;

const
  NonfiscalDocumentNumber: Integer = 1;

function CurrToStr(Value: Currency): string;
var
  DS: Char;
begin
  DS := SysUtils.DecimalSeparator;
  SysUtils.DecimalSeparator := '.';
  try
    Result := Format('=%.2f', [Value]);
  finally
    SysUtils.DecimalSeparator := DS;
  end;
end;

// Печать нефискального чека
procedure TFiscalPrinter.PrintNonfiscalReceipt(Receipt: TReceipt;
  Params: TServerParams);
var
  Line: string;
  Line1: string;
  Line2: string;
begin
  CheckStatusReceipt;
  // Заголовок документа
  Driver.DocumentName := '';
  Driver.DocumentNumber := NonfiscalDocumentNumber;
  Check(Driver.PrintDocumentTitle, 'PrintDocumentTitle');
  WaitForPrintSilent;
  // ШК Чека
  if Params.BarcodeEnabled and (Receipt.TicketBarCode <> '') then
  begin
    PrintBarcode(Receipt.TicketBarCode, Receipt.CheckDateTime);
    WaitForPrintSilent;
  end;
  PrintLines(Receipt.Lines);
  // Print total line
  Line1 := 'ИТОГ';
  Line2 := CurrToStr(Receipt.Total);

  Line := Line1 +
    StringOfChar(' ', (Receipt.PrintWidth div 2) - Length(Line1) - Length(Line2)) +
    Line2;
  Driver.StringForPrinting := Line;
  Driver.FontType := 2;
  Driver.PrintStringWithFont;


  PrintLines(FTrailer);
  PrintLines(FHeader);

  Driver.CutType := True;
  Driver.CutCheck;
  Driver.WaitForPrinting;
end;

procedure TFiscalPrinter.PrintLines(Lines: TTntStrings);
var
  i: Integer;
begin
  for i := 0 to Lines.Count-1 do
  begin
    Driver.StringForPrinting := Lines[i];
    Check(Driver.PrintString, 'Печать строки');
  end;
  Driver.WaitForPrinting;
end;

// Печать фискального чека
procedure TFiscalPrinter.PrintReceipt(Receipt: TReceipt; Params: TServerParams);
var
  i, j: Integer;
  Item: TReceiptItem;
  PaymentName: string;
begin
  CheckStatusReceipt;
  // Типы оплаты
  for i := 2 to 4 do
  begin
    PaymentName := Receipt.Payments[i].Name;
    if PaymentName <> '' then
      WriteTable(5, i, 1, PaymentName); // Наименование типа оплаты
  end;
  for i := 0 to Receipt.Items.Count-1 do
  begin
    Item := Receipt.Items.Items[i] as TReceiptItem;

    Driver.Tax1 := 0;
    Driver.Tax2 := 0;
    Driver.Tax3 := 0;
    Driver.Tax4 := 0;
    Driver.Quantity := 1;
    Driver.StringForPrinting := Item.Text;
    Driver.Price := Item.Total - Item.Discount;
    Driver.DiscountOnCheck := 0;
    Driver.Department := 1;
    // Начисление налогов на чек
    if Receipt.Tax <> 0 then
    begin
      WriteTable(1, 1, GetTaxFieldNumber, 1);     // Налоги на чек
      WriteTable(6, 1, 1, Receipt.Tax);           // Ставка налога
    end;
    // Продажа или возврат

    if Receipt.IsReturn then
      Check(Driver.ReturnSale, 'Возврат продажи')
    else
      Check(Driver.Sale, 'Продажа');

    if Item.Discount <> 0 then
    begin
      Driver.StringForPrinting := 'СКИДКА: ' + CurrToStr(Item.Discount);
      Check(Driver.PrintString, 'Печать строки');
    end;

    for j := 0 to Item.Notes.Count-1 do
    begin
      Driver.StringForPrinting := '  ' + Item.Notes[j];
      Check(Driver.PrintString, 'Печать строки');
    end;
  end;

  // Печатаем лидирующий разделитель
  Driver.StringForPrinting := Receipt.Lines[0];
  Check(Driver.PrintString, 'Печать строки');


  // ШК Чека
  if Params.BarcodeEnabled and (Receipt.TicketBarCode <> '') then
    PrintBarcode(Receipt.TicketBarCode, Receipt.CheckDateTime);

  // Всего вещей
  Driver.StringForPrinting := 'Всего вещей: ' + IntToStr(Receipt.Items.Count);
  Check(Driver.PrintString, 'Печать строки');

  // Текст чека
  for i := 0 to Receipt.Lines.Count-1 do
  begin
    Driver.StringForPrinting := Receipt.Lines[i];
    Check(Driver.PrintString, 'Печать строки');
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
  Driver.Summ1 := Receipt.Payments[1].Amount;
  Driver.Summ2 := Receipt.Payments[2].Amount;
  Driver.Summ3 := Receipt.Payments[3].Amount;
  Driver.Summ4 := Receipt.Payments[4].Amount;
  Check(Driver.CloseCheck, 'Закрытие чека');
  WaitForPrintSilent;
  PrintReceiptCopy;
end;

procedure TFiscalPrinter.PrintReceipt2(Receipt: TReceipt; Params: TServerParams);
var
  i, j: Integer;
  Item: TReceiptItem;
  PaymentName: string;
begin
  CheckStatusReceipt;
  // Типы оплаты
  for i := 2 to 4 do
  begin
    PaymentName := Receipt.Payments[i].Name;
    if PaymentName <> '' then
      WriteTable(5, i, 1, PaymentName); // Наименование типа оплаты
  end;
  // Отрываем чек
  Driver.CheckType := 0;
  if Receipt.IsReturn then
    Driver.CheckType := 2;
  Check(Driver.OpenCheck, 'OpenCheck');
  WaitForPrintSilent;
  //

(*
Операция V2
Код команды 	FF46h. Длина сообщения: 160 байт.
Пароль (4 байта)
Тип операции (1 байт):
1 - Приход
2 - Возврат прихода
3 - Расход
4 - Возврат расхода

*)

  for i := 0 to Receipt.Items.Count-1 do
  begin
    Item := Receipt.Items.Items[i] as TReceiptItem;

    Driver.Tax1 := 0;
    Driver.Tax2 := 0;
    Driver.Tax3 := 0;
    Driver.Tax4 := 0;
    Driver.Quantity := 1;
    Driver.StringForPrinting := Item.Text;
    Driver.Price := Item.Total - Item.Discount;
    Driver.DiscountOnCheck := 0;
    Driver.Department := 1;
    Driver.PaymentTypeSign := 4;
    Driver.PaymentItemSign := 4;
    Check(Driver.FNOperation, 'FNOperation');


    if Item.Discount <> 0 then
    begin
      Driver.StringForPrinting := 'СКИДКА: ' + CurrToStr(Item.Discount);
      Check(Driver.PrintString, 'Печать строки');
    end;

    for j := 0 to Item.Notes.Count-1 do
    begin
      Driver.StringForPrinting := '  ' + Item.Notes[j];
      Check(Driver.PrintString, 'Печать строки');
    end;
  end;

  // ШК Чека
  if Params.BarcodeEnabled and (Receipt.TicketBarCode <> '') then
    PrintBarcode(Receipt.TicketBarCode, Receipt.CheckDateTime);

  // Всего вещей
  Driver.StringForPrinting := 'Всего вещей: ' + IntToStr(Receipt.Items.Count);
  Check(Driver.PrintString, 'Печать строки');

  // Текст чека
  for i := 0 to Receipt.Lines.Count-1 do
  begin
    Driver.StringForPrinting := Receipt.Lines[i];
    Check(Driver.PrintString, 'Печать строки');
  end;

  // Закрытие чека
  Driver.Summ1 := 0;
  Driver.Summ2 := 0;
  Driver.Summ3 := 0;
  Driver.Summ4 := 0;
  Driver.StringForPrinting := '';
  Driver.Tax1 := 0;
  Driver.Tax2 := 0;
  Driver.Tax3 := 0;
  Driver.Tax4 := 0;
  // Выбираем тип оплаты
  Driver.Summ1 := Receipt.Payments[1].Amount;
  Driver.Summ2 := Receipt.Payments[2].Amount;
  Driver.Summ3 := Receipt.Payments[3].Amount;
  Driver.Summ4 := Receipt.Payments[4].Amount;
  Check(Driver.FNCloseCheckEx, 'FNCloseCheckEx');

  WaitForPrintSilent;
  PrintReceiptCopy;
end;

// Если чек успешно закрыт, то ошибки уже не выдаем
procedure TFiscalPrinter.WaitForPrintSilent;
begin
  try
    DoCheckStatus;
  except
    on E: Exception do
      LogFile.AddLine('Ошибка: ' + E.Message);
  end;
end;

procedure TFiscalPrinter.PrintReceiptCopy;
begin
  if not Params.ReceiptCopyEnabled then Exit;
  if Driver.RepeatDocument = 0 then
  begin
    WaitForPrintSilent;
  end;
end;

function TFiscalPrinter.GetLineData(Image: TImage; Index: Integer): string;
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

procedure TFiscalPrinter.LoadImage(Image: TImage);
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
    Check(Driver.LoadLineData, 'Загрузка графики');
  end;
  Driver.FirstLineNumber := 1;
  Driver.LastLineNumber := Count;
  Check(Driver.Draw, 'Печать графики');
end;

// Пустая строка

procedure TFiscalPrinter.FeedLine;
begin
  Driver.StringForPrinting := ' ';
  Check(Driver.PrintString, 'Печать строки');
end;

procedure TFiscalPrinter.PrintBarcodeImage(BarCodeText, DateTimeText: string);
var
  Image: TImage;
  Barcode: TAsBarCode;
begin
  // Строка штрих-кода
  Driver.StringForPrinting := StringOfChar(' ', 6) + Copy(BarCodeText, 2,
    Length(BarCodeText) - 1) + '  ' + DateTimeText;
  Check(Driver.PrintString, 'Печать строки');
  // 1 пустая строка
  FeedLine;

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
  // 1 пустая строка
  FeedLine;
end;

procedure TFiscalPrinter.PrintBarcode(BarCodeText, DateTimeText: string);
var
  ResultCode: Integer;
const
  // Команда не поддерживается в данной реализации ФР
  E_COMMAND_NOTSUPPORTED = 55;
begin
  if FCapPrintBarcodeLine then
  begin
    Driver.StringForPrinting := StringOfChar(' ', 6) + Copy(BarCodeText, 2,
      Length(BarCodeText) - 1) + '  ' + DateTimeText;
    Check(Driver.PrintString, 'Печать строки');
    // 1 пустая строка
    FeedLine;


    ResultCode := 0;
    try
      // Печать штрих-кода
      Driver.LineNumber := 100;
      Driver.Barcode := BarCodeText;
      Driver.BarcodeType := 1;
      Driver.BarWidth := 2;
      Driver.BarcodeAlignment := baCenter;
      ResultCode := Driver.PrintBarcodeLine;
      // ФР не поддерживает печать линии
      if ResultCode = E_COMMAND_NOTSUPPORTED then
      begin
        ResultCode := 0;
        FCapPrintBarcodeLine := False;
        PrintBarcodeImage(BarCodeText, DateTimeText);
      end;
    except
      // Драйвер не поддерживает методы печати линии
      on E: EOleSysError do
      begin
        FCapPrintBarcodeLine := False;
        PrintBarcodeImage(BarCodeText, DateTimeText);
      end;
    end;
    Check(ResultCode, 'PrintBarcodeLine');
    // 1 пустая строка
    FeedLine;
  end else
  begin
    PrintBarcodeImage(BarCodeText, DateTimeText);
  end;
end;

procedure TFiscalPrinter.CashOutcome;
var
  i: Integer;
  Count: Integer;
  CashSum: Int64;
const
  // Максимальная сумма выплаты (5 байт)
  MaxCashOutcomeSum = 9999999999;
begin
  // Полная инкассация
  Driver.RegisterNumber := 241;
  Check(Driver.GetCashReg, 'Запрос денежного регистра');
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
        Check(Driver.CashOutcome, 'Выплата');
        CheckStatus;
      end;
    end;
    Driver.Summ1 := (CashSum mod MaxCashOutcomeSum)/100;
    Check(Driver.CashOutcome, 'Выплата');
    CheckStatus;
  end;
end;

function TFiscalPrinter.ReadPrintWidth: Integer;
begin
  Check(Driver.GetDeviceMetrics, 'Запрос параметров устройства');
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
    22: Result := 42; 	// Retail-01K
  else
    Result := 48;
  end;
end;


procedure TFiscalPrinter.ShowProperties;
begin
  Driver.ShowProperties;
end;

function TFiscalPrinter.ZReportNotPrinted: Boolean;
begin
  Result := Driver.ECRMode in [2,3];
end;

procedure TFiscalPrinter.SetPassword(const Value: Integer);
begin
  Driver.Password := Value;
end;

procedure TFiscalPrinter.Disconnect;
begin
  FConnected := False;
  Driver.Disconnect;
end;

procedure TFiscalPrinter.WriteTable(Table, Row, Field, Value: Integer);
var
  S: string;
begin
  Driver.TableNumber := Table;
  Driver.RowNumber := Row;
  Driver.FieldNumber := Field;
  Driver.ValueOfFieldInteger := Value;

  S := Format('Запись таблицы. Таблица %d, ряд: %d, поле %d, значение %d',
    [Table, Row, Field, Value]);
  Check(Driver.WriteTable, S);
end;

procedure TFiscalPrinter.WriteTable(Table, Row, Field: Integer;
  const Value: string);
var
  S: string;
begin
  Driver.TableNumber := Table;
  Driver.RowNumber := Row;
  Driver.FieldNumber := Field;
  Driver.ValueOfFieldString := Value;

  S := Format('Запись таблицы. Таблица %d, ряд: %d, поле %d, значение %s',
    [Table, Row, Field, Value]);
  Check(Driver.WriteTable, S);
end;

function TFiscalPrinter.GetConnected: Boolean;
begin
  Result := FConnected;
end;

function TFiscalPrinter.GetPrintWidth: Integer;
begin
  Result := FPrintWidth;
end;

procedure TFiscalPrinter.OpenSession;
begin
  Check(Driver.OpenSession, 'Открытие смены');
end;

procedure TFiscalPrinter.Stop;
begin
  FStopFlag := True;
end;

procedure TFiscalPrinter.SaveZReport;
begin
  if Params.SaveZReportEnabled and (Params.ZReportFilePath <> '') then
  begin
    SaveZReportToIniFile(ReadZReport, Params.ZReportFilePath);
  end;
end;

function TFiscalPrinter.ReadTable(Table, Row, Field: Integer): string;
begin
  Driver.TableNumber := Table;
  Driver.RowNumber := Row;
  Driver.FieldNumber := Field;
  Check(Driver.ReadTable, 'ReadTable');
  Result := Driver.ValueOfFieldString;
end;

function TFiscalPrinter.ReadZReport: TZReportRec;
var
  i: Integer;
begin
  Check(Driver.GetECRStatus, 'GetECRStatus');
  Result.Number := Driver.SessionNumber + 1;

  Result.RegNumber := ReadTable(18, 1, 3);
  Result.SerialNumber := ReadTable(18, 1, 1);
  Result.InnNumber := ReadTable(18, 1, 2);
  Result.FSNumber := ReadTable(18, 1, 4);
  Result.CashierName := ReadTable(2, Driver.OperatorNumber, 2);
  Result.DocumentNumber := Driver.DocumentNumber;
  Result.TaxServiceSite := ReadTable(18, 1, 13);

  Result.DateTime := Now;
  for i := 0 to 255 do
  begin
    Result.OperReg[i] := 0;
    Result.CashReg[i] := 0;
  end;
  for i := 0 to 255 do
  begin
    Driver.RegisterNumber := i;
    if Driver.GetOperationReg <> 0 then Break;
    Result.OperReg[i] := Driver.ContentsOfOperationRegister;
  end;
  for i := 0 to 255 do
  begin
    Driver.RegisterNumber := i;
    if Driver.GetCashReg <> 0 then Break;
    Result.CashReg[i] := Driver.ContentsOfCashRegister;
  end;
end;

procedure TFiscalPrinter.SaveZReportToIniFile(const ZReport: TZReportRec;
  const FilePath: string);
var
  i: Integer;
  Section: string;
  IniFile: TIniFile;
  FileName: string;
begin
  CreateDir(Params.ZReportFilePath);

  FileName := Format('ZREport_%d_%s.ini', [
    ZReport.Number, FormatDateTime('yyyymmdd', ZReport.DateTime)]);
  FileName := IncludeTrailingPathDelimiter(Params.ZReportFilePath) + FileName;

  IniFile := TIniFile.Create(FileName);
  try
    Section := 'Header';
    IniFile.WriteInteger(Section, 'Number', ZReport.Number);
    IniFile.WriteString(Section, 'DateTime', FormatDateTime('dd.mm.yyyy hh:nn', ZReport.DateTime));
    // Operation
    Section := 'OperationReg';
    for i := 0 to 255 do
    begin
      IniFile.WriteInteger(Section, IntToStr(i), ZREport.OperReg[i]);
    end;
    // CashReg
    Section := 'CashReg';
    for i := 0 to 255 do
    begin
      IniFile.WriteString(Section, IntToStr(i),
        Format('%.2f', [ZREport.CashReg[i]]));
    end;

  finally
    IniFile.Free;
  end;
end;

procedure TFiscalPrinter.SaveZReportToTxtFile(const ZReport: TZReportRec;
  const FilePath: string);

  function ConcatLines(const Line1, Line2: string; Len: Integer): string;
  var
    L: Integer;
  begin
    L := Len - Length(Line1) - Length(Line2);
    Result := Line1;
    if L > 0 then
    begin
      Result := Result + StringOfChar(' ', L) + Line2;
    end;
    Result := Copy(Result, 1, Len);
  end;

var
  Line1: string;
  Line2: string;
  FileName: string;
  Lines: TStringList;
  PrintWidth: Integer;
begin
  CreateDir(Params.ZReportFilePath);
  FileName := Format('ZREport_%d_%s.txt', [
    ZReport.Number, FormatDateTime('yyyymmdd', ZReport.DateTime)]);
  FileName := IncludeTrailingPathDelimiter(Params.ZReportFilePath) + FileName;

  PrintWidth := 48;
  Lines := TStringList.Create;
  try
    // 1
    Line1 := 'РН ККТ:' + ZReport.RegNumber;
    Line2 := FormatDateTime('dd.mm.yy hh:nn', ZReport.DateTime);
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 2
    Line1 := 'ЗН ККТ:' + ZReport.SerialNumber;
    Line2 := 'СМЕНА:' + IntToStr(ZReport.Number);
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 3
    Lines.Add('ЗАКРЫТИЕ СМЕНЫ');
    // 4
    Line1 := 'ИНН:' + ZReport.InnNumber;
    Line2 := 'ФН:' + ZReport.FSNumber;
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 5
    Line1 := 'Кассир:' + ZReport.CashierName;
    Line2 := Format('#%.4d', [ZReport.DocumentNumber]);
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 6
    Line1 := 'Сайт ФНС';
    Line2 := ZReport.TaxServiceSite;
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 7
    Line1 := 'ЧЕКОВ ЗА СМЕНУ:';
    Line2 := IntToStr(ZReport.OperReg[144] + ZReport.OperReg[145] + ZReport.OperReg[146] + ZReport.OperReg[147]);
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 8
    Line1 := 'ФД ЗА СМЕНУ:';
    Line2 := IntToStr(0);
    Lines.Add(ConcatLines(Line1, Line2, PrintWidth));
    // 9



    Lines.SaveToFile(FileName);
  finally
    Lines.Free;
  end;
end;

{ TPrinterEventObject }

constructor TPrinterEventObject.Create(AID: Integer);
begin
  inherited Create;
  FID := AID;
end;

end.
