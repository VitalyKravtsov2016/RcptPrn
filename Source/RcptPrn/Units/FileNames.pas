unit FileNames;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Forms,
  // This
  ServerParams, untLogFile;

type
  { TFileNames }

  TFileNames = class(TStringList)
  private
    procedure AddFile(const Path: string; MinFileDate: TDateTime;
      const FindData: TWin32FindData);
  public
    procedure FindByMask(const Mask: string);
    procedure FindByTime(const Path: string; MinFileDate: TDateTime);
  end;

implementation

{ TFileNames }

///////////////////////////////////////////////////////////////////////////////
// Поиск файлов по маске с минимальной датой последней записи MinFileTime

procedure TFileNames.AddFile(const Path: string;
  MinFileDate: TDateTime; const FindData: TWin32FindData);
var
  FileName: string;
  FileDate: Integer;
  FileDateTime: TDateTime;
  LocalFileTime: TFileTime;
begin
  FileTimeToLocalFileTime(FindData.ftLastWriteTime, LocalFileTime);
  Win32Check(FileTimeToDosDateTime(LocalFileTime, LongRec(FileDate).Hi, LongRec(FileDate).Lo));
  FileDateTime := FileDateToDateTime(FileDate);

  if Trunc(FileDateTime) > Trunc(MinFileDate) then
  begin
    FileName := ExtractFilePath(Path) + String(FindData.cFileName);
    Add(FileName);
  end;
end;

/////////////////////////////////////////////////////////////////////
// Поиск файлов по маске

procedure TFileNames.FindByMask(const Mask: string);
var
  F: TSearchRec;
  Result: Integer;
  FileName: string;
begin
  Result := FindFirst(Mask, faAnyFile, F);
  while Result = 0 do
  begin
    FileName := ExtractFilePath(Mask) + F.FindData.cFileName;
    Add(FileName);
    Result := FindNext(F);
  end;
  FindClose(F);
end;

procedure TFileNames.FindByTime(const Path: string; MinFileDate: TDateTime);
var
  F: TSearchRec;
  FindData: TWin32FindData;
  FindHandle: THandle;
begin
  FindHandle := FindFirstFile(PChar(Path), FindData);
  if FindHandle <> INVALID_HANDLE_VALUE then
  begin
    AddFile(Path, MinFileDate, FindData);
    while FindNextFile(FindHandle, FindData) do
      AddFile(Path, MinFileDate, FindData);
    FindClose(F);
  end;
end;

end.
