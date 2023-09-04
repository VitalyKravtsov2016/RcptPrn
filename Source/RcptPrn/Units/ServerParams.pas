unit ServerParams;

interface

uses
  // VCL
  Windows, SysUtils, IniFiles, Classes,
  // This
  AppLogger, untLogFile;

const
  /////////////////////////////////////////////////////////////////////////////
  // ReceiptEncoding constants

  ReceiptEncodingCP866  = 0;
  ReceiptEncodingUTF8   = 1;

type
  TFileMode = (fmMove, fmDelete, fmSaveTime);

  { TServerParams }

  TServerParams = class
  private
    FCashNames: TStrings;               { Типы оплаты наличными }
    FCashlessNames: TStrings;           { Безналичные типы оплаты }
    FNonfiscalNames: TStrings;          { Нефискальные типы оплаты }

    FIniFileName: string;
    FDefLogFilePath: string;
    FDefErrorReceiptPath: string;
    FDefProcessedReportPath: string;
    FDefProcessedReceiptPath: string;
    FDefDuplicateReceiptPath: string;

    function GetLogFilePath: string;
    function GetLogFileEnabled: Boolean;
    procedure SetLogFilePath(const Value: string);
    procedure SetCashNames(const Value: TStrings);
    procedure SetLogFileEnabled(const Value: Boolean);

    property DefLogFilePath: string read FDefLogFilePath;
    procedure SetCashlessNames(const Value: TStrings);
    function ReadText(IniFile: TIniFile; const Section: string): string;
    procedure WriteText(const Text: string; IniFile: TIniFile;
      const Section: string);
    procedure SetNonfiscalNames(const Value: TStrings);
  public
    ReturnSale: string;
    ReceiptMask: string;
    ZReportMask: string;
    AutoStartSrv: Boolean;
    ReportMode: TFileMode;
    ReceiptMode: TFileMode;
    BarcodeEnabled: Boolean;
    DriverPassword: Integer;
    ReportFileTime: TDateTime;
    ReceiptFileTime: TDateTime;
    ProcessedReportPath: string;
    ProcessedReceiptPath: string;
    DuplicateReceiptPath: string;
    ErrorReceiptPath: string;
    ZReportEnabled: Boolean;
    PollPrinter: Boolean;
    UnknownPaytypeEnabled: Boolean;
    CopyErrorReceipts: Boolean;
    ReceiptCopyEnabled: Boolean;
    ReceiptEncoding: Integer;
    ChangeFileName: Boolean;
    FileNamePrefix: string;
    SaveZReportEnabled: Boolean;
    ZReportFilePath: string;
    DefZReportFilePath: string;

    constructor Create;
    destructor Destroy; override;

    procedure SetDefaults;
    procedure SaveToIniFile;
    procedure LoadFromIniFile;

    property CashNames: TStrings read FCashNames write SetCashNames;
    property LogFilePath: string read GetLogFilePath write SetLogFilePath;
    property CashlessNames: TStrings read FCashlessNames write SetCashlessNames;
    property LogFileEnabled: Boolean read GetLogFileEnabled write SetLogFileEnabled;
    property NonfiscalNames: TStrings read FNonfiscalNames write SetNonfiscalNames;
  end;

const
  DefAutostartSrv               = False;
  DefAutostartApp               = False;
  DefDriverPassword             = 30;
  DefZReportMask                = 'C:\P2\Fiscal\*.p2';
  DefReceiptMask                = 'C:\P2\Fiscal\*.p2t';
  DefBarcodeEnabled             = False;
  DefReturnSale                 = 'VIREMENT';
  DefDeleteBadFiles             = False;
  DefReportMode                 = fmSaveTime;
  DefReceiptMode                = fmDelete;
  DefZReportEnabled             = False;
  DefPollPrinter                = True;
  DefLogFileEnabled             = True;
  DefUnknownPaytypeEnabled    = False;
  DefCopyErrorReceipts          = True;
  DefReceiptCopyEnabled         = False;
  DefReceiptEncoding            = ReceiptEncodingCP866;

function Params: TServerParams;
function GetLastWriteTime(const FileName: string): TDateTime;

implementation

var
  FParams: TServerParams;

function Params: TServerParams;
begin
  Result := FParams;
end;

function FileTimeToStr(const ft: _FILETIME): string;
begin
  Result := Format('%.8x%.8x', [ft.dwHighDateTime, ft.dwLowDateTime]);
end;

function StrToFileTime(const Value: string):_FILETIME;
begin
  Result.dwHighDateTime := StrToInt64('$' + Copy(Value, 1, 8));
  Result.dwLowDateTime := StrToInt64('$' + Copy(Value, 9, 8));
end;

function GetLastWriteTime(const FileName: string): TDateTime;
var
  F: THandle;
  ct: _FILETIME;
  at: _FILETIME;
  wt: _FILETIME;
  ft: TFileTime;
  fd: Integer;
begin
  Result := Now;
  F := CreateFile(PChar(FileName), 0,0,nil,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0);
  if F <> INVALID_HANDLE_VALUE then
  begin
    Win32Check(GetFileTime(F, @ct, @at, @wt));
    FileTimeToLocalFileTime(wt, ft);
    Win32Check(FileTimeToDosDateTime(ft, LongRec(fd).Hi, LongRec(fd).Lo));
    Result := FileDateToDateTime(fd);
    CloseHandle(F);
  end;
end;

{ TServerParams }

constructor TServerParams.Create;
begin
  inherited Create;
  FCashNames := TStringList.Create;
  FCashlessNames := TStringList.Create;
  FNonfiscalNames := TStringList.Create;

  FIniFileName := ChangeFileExt(ParamStr(0), '.ini');
  FDefLogFilePath := IncludeTrailingBackSlash(ExtractFilePath(ParamStr(0))) + 'Logs';
  FDefProcessedReportPath := ExtractFilePath(ParamStr(0)) + 'Reports';
  FDefProcessedReceiptPath := ExtractFilePath(ParamStr(0)) + 'Receipts';
  FDefDuplicateReceiptPath := ExtractFilePath(ParamStr(0)) + 'Duplicate';
  FDefErrorReceiptPath := ExtractFilePath(ParamStr(0)) + 'ErrorReceipts';
  DefZReportFilePath := ExtractFilePath(ParamStr(0)) + 'ZReports';
end;

destructor TServerParams.Destroy;
begin
  FCashNames.Free;
  FCashlessNames.Free;
  FNonfiscalNames.Free;
  inherited Destroy;
end;

/////////////////////////////////////////////////////////////////////
// Выставляем настройки по умолчанию

procedure TServerParams.SetDefaults;
begin
  ReceiptMask := DefReceiptMask;
  ZReportMask := DefZReportMask;
  ReturnSale := DefReturnSale;
  DriverPassword := DefDriverPassword;
  BarcodeEnabled := DefBarcodeEnabled;
  AutostartSrv := DefAutostartSrv;
  ReportMode := DefReportMode;
  ReceiptMode := DefReceiptMode;
  ProcessedReportPath := FDefProcessedReportPath;
  ProcessedReceiptPath := FDefProcessedReceiptPath;
  DuplicateReceiptPath := FDefDuplicateReceiptPath;
  ZReportEnabled := DefZReportEnabled;
  PollPrinter := DefPollPrinter;
  ReceiptCopyEnabled := DefReceiptCopyEnabled;

  ErrorReceiptPath := FDefErrorReceiptPath;
  CopyErrorReceipts := DefCopyErrorReceipts;

  // Параметры лога
  LogFileEnabled := DefLogFileEnabled;
  LogFilePath := DefLogFilePath;
  // CashNames
  CashNames.Clear;
  CashNames.Add('ESPECE');
  CashNames.Add('НАЛИЧНЫЕ');
  CashNames.Add('ОПЛАТА НАЛИЧНЫМИ');
  // CashlessNames
  CashlessNames.Clear;
  CashlessNames.Add('ОПЛАТА КАРТОЙ');
  ReceiptEncoding := DefReceiptEncoding;
end;

// Загрузка параметров приложения из Ini файла
procedure TServerParams.LoadFromIniFile;
var
  IniFile: TIniFile;
begin
  try
    SetDefaults;
    if not FileExists(FIniFileName) then Exit;

    IniFile := TIniFile.Create(FIniFileName);
    try
      ReceiptMask := IniFile.ReadString('Settings', 'ReceiptMask', DefReceiptMask);
      ZReportMask := IniFile.ReadString('Settings', 'ZReportMask', DefZReportMask);
      ReturnSale := IniFile.ReadString('Settings', 'ReturnSale',  DefReturnSale);
      DriverPassword := IniFile.ReadInteger('Settings', 'DriverPassword', DefDriverPassword);
      BarcodeEnabled := IniFile.ReadBool('Settings', 'BarcodeEnabled', DefBarcodeEnabled);
      AutostartSrv := IniFile.ReadBool('Settings', 'AutostartSrv', DefAutostartSrv);
      ReportMode := TFileMode(IniFile.ReadInteger('Settings', 'ReportMode', Ord(DefReportMode)));
      ReceiptMode := TFileMode(IniFile.ReadInteger('Settings', 'ReceiptMode', Ord(DefReceiptMode)));
      ProcessedReportPath := IniFile.ReadString('Settings', 'ProcessedReportPath', FDefProcessedReportPath);
      ProcessedReceiptPath := IniFile.ReadString('Settings', 'ProcessedReceiptPath', FDefProcessedReceiptPath);
      DuplicateReceiptPath := IniFile.ReadString('Settings', 'DuplicateReceiptPath', FDefDuplicateReceiptPath);
      ReportFileTime := StrToDate(IniFile.ReadString('Settings', 'ReportFileTime', DateToStr(Now)));
      ReceiptFileTime := StrToDate(IniFile.ReadString('Settings', 'ReceiptFileTime', DateToStr(Now)));
      ZReportEnabled := IniFile.ReadBool('Settings', 'ZReportEnabled', DefZReportEnabled);
      PollPrinter := IniFile.ReadBool('Settings', 'PollPrinter', DefPollPrinter);
      UnknownPaytypeEnabled := IniFile.ReadBool('Settings', 'UnknownPaytypeEnabled', DefUnknownPaytypeEnabled);
      ErrorReceiptPath := IniFile.ReadString('Settings', 'ErrorReceiptPath', FDefErrorReceiptPath);
      CopyErrorReceipts := IniFile.ReadBool('Settings', 'CopyErrorReceipts', DefCopyErrorReceipts);
      ReceiptCopyEnabled := IniFile.ReadBool('Settings', 'ReceiptCopyEnabled', DefReceiptCopyEnabled);
      ReceiptEncoding := IniFile.ReadInteger('Settings', 'ReceiptEncoding', DefReceiptEncoding);
      // параметры лога
      LogFileEnabled := IniFile.ReadBool('Settings', 'LogFileEnabled', DefLogFileEnabled);
      LogFilePath := IniFile.ReadString('Settings', 'LogFilePath', DefLogFilePath);
      // CashNames
      CashNames.Text := ReadText(IniFile, 'CashNames');
      CashlessNames.Text := ReadText(IniFile, 'CashlessNames');
      NonfiscalNames.Text := ReadText(IniFile, 'NonfiscalNames');
      ChangeFileName := IniFile.ReadBool('Settings', 'ChangeFileName', False);
      FileNamePrefix := IniFile.ReadString('Settings', 'FileNamePrefix', 'RU001');

      SaveZReportEnabled := IniFile.ReadBool('Settings', 'SaveZReportEnabled', True);
      ZReportFilePath := IniFile.ReadString('Settings', 'ZReportFilePath', DefZReportFilePath);
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
    begin
      Logger.AddLine('TServerParams.LoadFromIniFile: ' + E.Message);
    end;
  end;
end;

// Сохраняем настройки
procedure TServerParams.SaveToIniFile;
var
  IniFile: TIniFile;
begin
  try
    if FileExists(FIniFileName) then
      DeleteFile(FIniFileName);

    IniFile := TIniFile.Create(FIniFileName);
    try
      IniFile.WriteString('Settings', 'ReceiptMask', ReceiptMask);
      IniFile.WriteString('Settings', 'ZReportMask', ZReportMask);
      IniFile.WriteString('Settings', 'ReturnSale', ReturnSale);
      IniFile.WriteInteger('Settings', 'DriverPassword', DriverPassword);
      IniFile.WriteBool('Settings', 'BarcodeEnabled', BarcodeEnabled);
      IniFile.WriteBool('Settings', 'AutostartSrv', AutostartSrv);
      IniFile.WriteInteger('Settings', 'ReportMode', Ord(ReportMode));
      IniFile.WriteInteger('Settings', 'ReceiptMode', Ord(ReceiptMode));
      IniFile.WriteString('Settings', 'ProcessedReportPath', ProcessedReportPath);
      IniFile.WriteString('Settings', 'ProcessedReceiptPath', ProcessedReceiptPath);
      IniFile.WriteString('Settings', 'DuplicateReceiptPath', DuplicateReceiptPath);
      IniFile.WriteString('Settings', 'ReportFileTime', DateToStr(ReportFileTime));
      IniFile.WriteString('Settings', 'ReceiptFileTime', DateToStr(ReceiptFileTime));
      IniFile.WriteBool('Settings', 'ZReportEnabled', ZReportEnabled);
      IniFile.WriteBool('Settings', 'PollPrinter', PollPrinter);
      IniFile.WriteBool('Settings', 'UnknownPaytypeEnabled', UnknownPaytypeEnabled);
      IniFile.WriteString('Settings', 'ErrorReceiptPath', ErrorReceiptPath);
      IniFile.WriteBool('Settings', 'CopyErrorReceipts', CopyErrorReceipts);
      IniFile.WriteString('Settings', 'LogFilePath', LogFilePath);
      IniFile.WriteBool('Settings', 'LogFileEnabled', LogFileEnabled);
      IniFile.WriteBool('Settings', 'ReceiptCopyEnabled', ReceiptCopyEnabled);
      IniFile.WriteInteger('Settings', 'ReceiptEncoding', ReceiptEncoding);
      WriteText(CashNames.Text, IniFile, 'CashNames');
      WriteText(CashlessNames.Text, IniFile, 'CashlessNames');
      WriteText(NonfiscalNames.Text, IniFile, 'NonfiscalNames');
      IniFile.WriteBool('Settings', 'ChangeFileName', ChangeFileName);
      IniFile.WriteString('Settings', 'FileNamePrefix', FileNamePrefix);

      IniFile.WriteBool('Settings', 'SaveZReportEnabled', SaveZReportEnabled);
      IniFile.WriteString('Settings', 'ZReportFilePath', ZReportFilePath);
    finally
      IniFile.Free;
    end;
  except
    on E: Exception do
    begin
      Logger.AddLine('TServerParams.SaveToIniFile: ' + E.Message);
    end;
  end;
end;

function TServerParams.ReadText(IniFile: TIniFile; const Section: string): string;
var
  S: string;
  i: Integer;
  Lines: TStrings;
  KeyNames: TStrings;
begin
  Result := '';
  Lines := TStringList.Create;
  KeyNames := TStringList.Create;
  try
    IniFile.ReadSection(Section, KeyNames);
    for i := 0 to KeyNames.Count-1 do
    begin
      S := Trim(IniFile.ReadString(Section, KeyNames[i], ''));
      if S <> '' then Lines.Add(S);
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
    KeyNames.Free;
  end;
end;

procedure TServerParams.WriteText(const Text: string; IniFile: TIniFile;
  const Section: string);
var
  i: Integer;
  Lines: TStrings;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    for i := 0 to Lines.Count-1 do
    begin
      IniFile.WriteString(Section, IntToStr(i), Lines[i]);
    end;
  finally
    Lines.Free;
  end;
end;

function TServerParams.GetLogFileEnabled: Boolean;
begin
  Result := LogFile.Enabled;
end;

function TServerParams.GetLogFilePath: string;
begin
  Result := LogFile.FilePath;
end;

procedure TServerParams.SetLogFileEnabled(const Value: Boolean);
begin
  LogFile.Enabled := Value;
end;

procedure TServerParams.SetLogFilePath(const Value: string);
begin
  LogFile.FilePath := Value;
end;

procedure TServerParams.SetCashNames(const Value: TStrings);
begin
  FCashNames.Assign(Value);
end;

procedure TServerParams.SetCashlessNames(const Value: TStrings);
begin
  FCashlessNames.Assign(Value);
end;

procedure TServerParams.SetNonfiscalNames(const Value: TStrings);
begin
  FNonfiscalNames.Assign(Value);
end;

initialization
  FParams := TServerParams.Create;
  FParams.LoadFromIniFile;

finalization
  FParams.SaveToIniFile;
  FParams.Free;
  FParams := nil;

end.
