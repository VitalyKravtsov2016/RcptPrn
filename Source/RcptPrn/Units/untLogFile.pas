unit untLogFile;

interface

uses
  // VCL
  Windows, Classes, SysUtils, SyncObjs;

type
  { TLogFile }

  TLogFile = class
  private
    FHandle: THandle;
    FFileName: string;
    FFilePath: string;
    FEnabled: Boolean;
    FCS: TCriticalSection;

    procedure OpenFile;
    function GetOpened: Boolean;
    function GetFileName: string;
    procedure SetEnabled(Value: Boolean);
    procedure DoAddLine(const Data: string);
    procedure SetFilePath(const Value: string);

    property CS: TCriticalSection read FCS;
    property Opened: Boolean read GetOpened;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Lock;
    procedure Unlock;
    procedure CloseFile;
    procedure AddSeparator;
    procedure AddLine(const Data: string);

    property Enabled: Boolean read FEnabled write SetEnabled;
    property FilePath: string read FFilePath write SetFilePath;
  end;

var
  LogFile: TLogFile;

implementation

const
  S_SEPARATOR   = '------------------------------------------------------------';

{ TLogFile }

constructor TLogFile.Create;
begin
  inherited Create;
  FCS := TCriticalSection.Create;
  FHandle := INVALID_HANDLE_VALUE;
end;

destructor TLogFile.Destroy;
begin
  CloseFile;
  FCS.Free;
  inherited Destroy;
end;

function TLogFile.GetFileName: string;
begin
  Result := IncludeTrailingBackslash(FilePath) + 'RcptPrn_' +
    FormatDateTime('dd.mm.yyyy', Date) + '.log';
end;

procedure TLogFile.OpenFile;
var
  FileName: string;
begin
  if not Opened then
  begin
    FileName := GetFileName;
    CreateDir(ExtractFilePath(FileName));
    FHandle := CreateFile(PChar(GetFileName), GENERIC_READ or GENERIC_WRITE,
      FILE_SHARE_READ, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);

    if Opened then
    begin
      FileSeek(FHandle, 0, 2); // 0 from end
      FFileName := FileName;
    end;
  end;
end;

procedure TLogFile.CloseFile;
begin
  if Opened then
    CloseHandle(FHandle);
  FHandle := INVALID_HANDLE_VALUE;
end;

function TLogFile.GetOpened: Boolean;
begin
  Result := FHandle <> INVALID_HANDLE_VALUE;
end;

procedure TLogFile.SetEnabled(Value: Boolean);
begin
  if Value <> Enabled then
  begin
    FEnabled := Value;
    CloseFile;
  end;
end;

procedure TLogFile.SetFilePath(const Value: string);
begin
  if Value <> FilePath then
  begin
    CloseFile;
    FFilePath := Value;
  end;
end;

function GetFileSizeInMB(hFile: THandle): DWORD;
var
  FileSizeLow: DWORD;
  FileSizeHigh: DWORD;
begin
  Result := 0;
  FileSizeLow := GetFileSize(hFile, @FileSizeHigh);
  if FileSizeLow = INVALID_FILE_SIZE then Exit;
  Result := ((FileSizeHigh shl 32) + FileSizeLow) shr 20;
end;

procedure TLogFile.DoAddLine(const Data: string);
var
  S: string;
  Count: DWORD;
begin
  if not Enabled then Exit;
  S := FormatDateTime('[dd.mm.yyyy hh:nn:ss.zzz] ', Now) + Data + #13#10;
  OpenFile;
  if Opened then
  begin
    if GetFileName <> FFileName then
    begin
      CloseFile;

      OpenFile;
      if Opened then
        WriteFile(FHandle, S[1], Length(S), Count, nil);
    end else
    begin
      WriteFile(FHandle, S[1], Length(S), Count, nil);
    end;
    CloseFile;
  end;
end;

procedure TLogFile.AddLine(const Data: string);
begin
  Lock;
  try
    DoAddLine(Data);
  finally
    Unlock;
  end;
end;

procedure TLogFile.Lock;
begin
  CS.Enter;
end;

procedure TLogFile.Unlock;
begin
  CS.Leave;
end;

procedure TLogFile.AddSeparator;
begin
  AddLine(S_SEPARATOR);
end;

initialization
  LogFile := TLogFile.Create;

finalization
  LogFile.Free;

end.
