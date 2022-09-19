unit Receipt;

interface

uses
  // VCL
  Windows, Classes, SysUtils,
  // Tnt
  TntClasses,
  // This
  untUtil, ServerParams;

type
  { TPayment }

  TPayment = record
    Name: string;
    Amount: Currency;
  end;

  { TPayments }

  TPayments = array [1..4] of TPayment;

  { TReceiptItem }

  TReceiptItem = class(TCollectionItem)
  private
    FText: WideString;
    FTotal: Currency;
    FDiscount: Currency;
    FNotes: TTntStrings;
  public
    constructor Create(AOwner: TCollection); override;
    destructor Destroy; override;

    property Total: Currency read FTotal;
    property Text: WideString read FText;
    property Notes: TTntStrings read FNotes;
    property Discount: Currency read FDiscount;
  end;

  { TReceipt }

  TReceipt = class
  private
    FTotal: Currency;
    FChange: Currency;
    FTax: Integer;
    FCountT: Integer;
    FBarCode: WideString;
    FPrintWidth: Integer;
    FCheckDateTime: WideString;
    FItemText: WideString;
    FLastItem: TReceiptItem;
    FPayments: TPayments;
    FItems: TCollection;
    FLines: TTntStrings;

    procedure ClearReceipt;
    procedure CheckReceiptFormat;
    procedure AddItemA(const Line: WideString);
    procedure AddItemS(const Line: WideString);
    procedure AddItemJ(const Line: WideString);
    procedure AddItemK(const Line: WideString);
    procedure AddItemF(const Line: WideString);
    procedure AddItemT(const Line: WideString);
    procedure AddItemU(const Line: WideString);
    procedure AddItemG(const Line: WideString);
    procedure AddItemD(const Line: WideString);
    procedure AddItemR(const Line: WideString);
    procedure AddItemB(const Line: WideString);
    procedure InsertLine(Index: Integer; const S: WideString);
    procedure ParseStrings(Strings: TTntStrings);
    function DecodeLine(const Line: WideString): WideString;
    function IsCashPayment(const PaymentName: string): Boolean;
    function GetPaymentsTotal: Currency;
  public
    constructor Create;
    destructor Destroy; override;

    function IsReturn: Boolean;
    function IsNonfiscal: Boolean;
    function ItemsTotal: Currency;
    procedure LoadFromFile(const FileName: WideString);
    function IsCashlessPayment(const PaymentName: string): Boolean;
    function IsNonfiscalPayment(const PaymentName: string): Boolean;

    property Total: Currency read FTotal;
    property Change: Currency read FChange;
    property Items: TCollection read FItems;
    property Lines: TTntStrings read FLines;
    property Tax: Integer read FTax write FTax;
    property TicketBarCode: WideString read FBarCode;
    property PaymentsTotal: Currency read GetPaymentsTotal;
    property CheckDateTime: WideString read FCheckDateTime;
    property Payments: TPayments read FPayments write FPayments;
    property PrintWidth: Integer read FPrintWidth write FPrintWidth;
  end;

  EReceiptException = class(Exception);

function AnsiToOEM(const S: WideString): WideString;
function StrToCurrency(const S: WideString): Currency;
function StrToInt2(const S: WideString): Integer;

implementation

function StrToCurrency(const S: WideString): Currency;
var
  SaveDecimalSeparator: Char;
begin
  Result := 0;
  SaveDecimalSeparator := DecimalSeparator;
  try
    try
      DecimalSeparator := '.';
      Result := StrToCurr(S);
      Exit;
    except
    end;
    try
      DecimalSeparator := ',';
      Result := StrToCurr(S);
    except
    end;
  finally
    DecimalSeparator := SaveDecimalSeparator;
  end;
end;

function StrToInt2(const S: WideString): Integer;
begin
  Result := Trunc(StrToCurrency(S));
end;

function SetStrLen(const S: WideString; L: Integer): WideString;
begin
  Result := Copy(S, 1, L);
  Result := Result + StringOfChar(' ', L-Length(Result));
end;

function GetPosNumber(const S: WideString): Integer;
begin
  Result := StrToInt2(Copy(GetStr(S, 7), 6, 3));
end;

function OemToAnsi(const S: string): string;
begin
  Result := '';
  if Length(S) > 0 then
  begin
    SetLength(Result, Length(S));
    OemToChar(@S[1], @Result[1]);
  end;
end;

function AnsiToOEM(const S: WideString): WideString;
begin
  Result := '';
  if Length(S) > 0 then
  begin
    SetLength(Result, Length(S));
    CharToOem(@S[1], @Result[1]);
  end;
end;

{ TReceipt }

constructor TReceipt.Create;
begin
  inherited Create;
  FLines := TTntStringList.Create;
  FItems := TCollection.Create(TReceiptItem);
  PrintWidth := 36;
end;

destructor TReceipt.Destroy;
begin
  FItems.Free;
  FLines.Free;
  inherited Destroy;
end;

procedure TReceipt.ClearReceipt;
var
  i: Integer;
begin
  FTotal := 0;
  FBarCode := '';
  FCountT := 0;
  FTax := 0;
  FCheckDateTime := '';
  for i := 1 to 4 do
  begin
    FPayments[i].Amount := 0;
    FPayments[i].Name := '';
  end;
  FItems.Clear;
  FLines.Clear;
  FChange := 0;
end;

// Вещь

procedure TReceipt.AddItemA(const Line: WideString);
begin
  FItemText := Trim(GetStr(Line, 5));
end;

// Кассир

procedure TReceipt.AddItemF(const Line: WideString);
begin
  InsertLine(1, 'Кассир: ' + GetStr(Line, 5));
end;

// Когда забрать вещи?

procedure TReceipt.AddItemJ(const Line: WideString);
var
  S: WideString;
begin
  S := GetStr(Line, 5);
  InsertLine(1, S);
end;

procedure TReceipt.InsertLine(Index: Integer; const S: WideString);
begin
  Lines.Insert(Index, Copy(S, 1, PrintWidth));
end;

// Чек
procedure TReceipt.AddItemK(const Line: WideString);
var
  S: WideString;
begin
  S := 'Код клиента: ' + GetStr(Line, 3);
  InsertLine(0, S);
  S := 'Клиент: ' + GetStr(Line, 3);
  InsertLine(0, S);

  S := GetStr(Line, 1);
  insert('.', S, 3);
  insert('.', S, 6);
  insert(':', S, 14);
  FCheckDateTime := S;
  S := 'Вещи сданы: ' + S;
  InsertLine(0, S);
end;

// Услуга

procedure TReceipt.AddItemS(const Line: WideString);
var
  ItemPrice: Currency;
  ServiceText: WideString;
  Item: TReceiptItem;
begin
  ServiceText := TrimRight(GetStr(Line, 5));
  ItemPrice := StrToCurrency(Trim(GetStr(Line, 6)));

  Item := TReceiptItem.Create(FItems);
  Item.FTotal := ItemPrice;
  Item.FText := FItemText + ', ' + ServiceText;
  FLastItem := Item;
end;

// Сумма чека
procedure TReceipt.AddItemT(const Line: WideString);
begin
  FTotal := StrToCurrency(Trim(GetStr(Line, 6)));
  Inc(FCountT);
end;

// Тип оплаты
//
// 13022016 1128;;;G;ОПЛАТА КАРТОЙ;1200,00;58335; ;09040009415
// 13022016 1128;;;G;ОПЛАТА НАЛИЧНЫМИ;1550,00;58335; ;09040009400
procedure TReceipt.AddItemG(const Line: WideString);
var
  i: Integer;
  PaymentName: WideString;
  PaymentAmount: Currency;
begin
  PaymentName := Trim(GetStr(Line, 5));
  PaymentAmount := StrToCurrency(Trim(GetStr(Line, 6)));
  if IsCashPayment(PaymentName) then
  begin
    FPayments[1].Amount := FPayments[1].Amount + PaymentAmount;
    FPayments[1].Name := PaymentName;
  end else
  begin
    for i := 2 to 4 do
    begin
      if FPayments[i].Amount = 0 then
      begin
        FPayments[i].Name := PaymentName;
        FPayments[i].Amount := PaymentAmount;
        Break;
      end else
      begin
        if (FPayments[i].Name = PaymentName)or(i=4) then
        begin
          FPayments[i].Amount := FPayments[i].Amount + PaymentAmount;
          Break;
        end;
      end;
    end;
  end;
end;

// Полученная сумма
(*
13072022 1057;;;U;Сдача;2000,00;05614; ;09040009400
13072022 1057;;;U;Оплаченная стоимость;730,00;05614; ;09040009400
*)

procedure TReceipt.AddItemU(const Line: WideString);
begin
  if (UpperCase(Trim(GetStr(Line, 5))) = 'СДАЧА') then
  begin
    FPayments[1].Amount := StrToCurrency(Trim(GetStr(Line, 6)));
  end;
  if (UpperCase(Trim(GetStr(Line, 5))) = 'ОПЛАЧЕННАЯ СТОИМОСТЬ') then
  begin
    FChange := StrToCurrency(Trim(GetStr(Line, 6)));
  end;
end;

// Скидки

procedure TReceipt.AddItemD(const Line: WideString);
var
  S: WideString;
begin
  S := Trim(GetStr(Line, 6));
  if S = '' then Exit;

  if FLastItem <> nil then
  begin
    FLastItem.FDiscount := Abs(StrToCurrency(S));
  end;
end;

// Дефекты

procedure TReceipt.AddItemR(const Line: WideString);
begin
  if FLastItem <> nil then
  begin
    FLastItem.Notes.Add(Trim(GetStr(Line, 5)));
  end;
end;

// Штрих-код (Code128A)

procedure TReceipt.AddItemB(const Line: WideString);
begin
  FBarCode := Trim(GetStr(Line, 5));
end;


{ Обработка файла }

procedure TReceipt.LoadFromFile(const FileName: WideString);
var
  Strings: TTntStrings;
begin
  Strings := TTntStringList.Create;
  try
    Strings.LoadFromFile(FileName);
    try
      ParseStrings(Strings);
    except
      on E: Exception do
        Raise EReceiptException.Create(E.Message);
    end;
  finally
    Strings.Free;
  end;
end;

function TReceipt.DecodeLine(const Line: WideString): WideString;
begin
  Result := Line;
  if Params.ReceiptEncoding = ReceiptEncodingCP866 then
    Result := OemToAnsi(Line);
end;

procedure TReceipt.ParseStrings(Strings: TTntStrings);
var
  i: Integer;
  S: WideString;
  Line: WideString;
  FieldType: WideChar;
begin
  ClearReceipt;
  if Strings.Count = 0 then Exit;
  for i := 0 to Strings.Count-1 do
  begin
    Line := DecodeLine(Strings[i]);
    S := Trim(GetStr(Line, 4));
    if Length(S) >= 1 then
    begin
      FieldType := S[1];
      case FieldType of
        'A': AddItemA(Line);  // Вещь
        'S': AddItemS(Line);  // Услуга
        'T': AddItemT(Line);  // Сумма чека
        'K': AddItemK(Line);  // Информация о чеке
        'F': AddItemF(Line);  // Кассир
        'J': AddItemJ(Line);  // Когда забирать
        'U': AddItemU(Line);  // Сдача при оплате наличными
        'G': AddItemG(Line);  // Тип оплаты
        'D': AddItemD(Line);  // Скидки
        'R': AddItemR(Line);  // Износ
        'B': AddItemB(Line);  // Штрих-Код
      end;
    end;
  end;
  // Разделитель
  InsertLine(0, StringOfChar('-', PrintWidth));
  // Проверка формата чека
  CheckReceiptFormat;
end;

procedure TReceipt.CheckReceiptFormat;
begin
  if FCountT = 0 then
    raise EReceiptException.Create('В чеке нет суммы');
  if FCountT > 1 then
    raise EReceiptException.Create('В чеке несколько сумм');
  if FItems.Count > 190 then
    raise EReceiptException.Create('В чеке слишком много позиций');
end;

// Чек оплачен наличными
function TReceipt.IsCashPayment(const PaymentName: string): Boolean;
var
  i: Integer;
begin
  Result := PaymentName = '';
  if Result then Exit;

  for i := 0 to Params.CashNames.Count-1 do
  begin
    Result := AnsiSameText(PaymentName, Params.CashNames[i]);
    if Result then Exit;
  end;
end;

function TReceipt.IsCashlessPayment(const PaymentName: string): Boolean;
var
  i: Integer;
begin
  Result := PaymentName = '';
  if Result then Exit;

  for i := 0 to Params.CashlessNames.Count-1 do
  begin
    Result := AnsiSameText(PaymentName, Params.CashlessNames[i]);
    if Result then Exit;
  end;
end;

function TReceipt.IsNonfiscalPayment(const PaymentName: string): Boolean;
var
  i: Integer;
begin
  Result := PaymentName = '';
  if Result then Exit;

  for i := 0 to Params.NonfiscalNames.Count-1 do
  begin
    Result := AnsiSameText(PaymentName, Params.NonfiscalNames[i]);
    if Result then Exit;
  end;
end;

function TReceipt.IsReturn: Boolean;
var
  i: Integer;
begin
  for i := 1 to 4 do
  begin
    Result := Payments[i].Name = Params.ReturnSale;
    if Result then Break;
  end;
end;

function TReceipt.IsNonfiscal: Boolean;
var
  i: Integer;
begin
  for i := 1 to 4 do
  begin
    Result := Params.NonfiscalNames.IndexOf(Payments[i].Name) <> -1;
    if Result then Break;
  end;
end;

function TReceipt.ItemsTotal: Currency;
var
  i: Integer;
  Item: TReceiptItem;
begin
  Result := 0;
  for i := 0 to Items.Count-1 do
  begin
    Item := Items.Items[i] as TReceiptItem;
    Result := Result + Item.Total - Item.Discount;
  end;
end;

function TReceipt.GetPaymentsTotal: Currency;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to 4 do
  begin
    Result := Result + Payments[i].Amount;
  end;
end;

{ TReceiptItem }

constructor TReceiptItem.Create(AOwner: TCollection);
begin
  inherited Create(AOwner);
  FNotes := TTntStringList.Create
end;

destructor TReceiptItem.Destroy;
begin
  FNotes.Free;
  inherited Destroy;
end;

end.
