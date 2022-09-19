unit untUtil;

interface

uses
  // VCL
  SysUtils;

type
  TEventType = (ctLog, ctState, ctError);

function GetStr(const S: string; Index: Integer): string;

implementation

type
  TSetOfChar = set of char;

function GetSubString(const S: String; var Value: string; K: Integer;
  Delimiters: TSetOfChar): Boolean;
var
  LastPos: Integer;
  CurPos: Integer;
  CurParam: Integer;
  Len: Integer;
begin
  Result := False;
  Value := '';
  Len := Length(S);
  CurParam := 1;
  CurPos := 1;
  while (CurPos <= Len) and (CurParam <= K) do
  begin
    LastPos := CurPos;
    while (CurPos <= Len) and not (S[CurPos] in Delimiters) do Inc(CurPos);
    if CurParam = K then
    begin
      Result := True;
      Value := Copy(S, LastPos, CurPos - LastPos);
      Exit;
    end;
    Inc(CurPos);
    Inc(CurParam);
  end;
end;

function GetStr(const S: string; Index: Integer): string;
begin
  GetSubString(S, Result, Index, [';']);
end;

end.
