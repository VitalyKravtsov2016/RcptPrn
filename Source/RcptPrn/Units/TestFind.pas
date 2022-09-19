unit TestFind;

interface

uses
  // This
  Classes, SysUtils;

procedure TestFindFile;

implementation

procedure FindFileNames(const Mask: string; FileNames: TStrings);
var
  F: TSearchRec;
  Result: Integer;
  FileName: string;
begin
  Result := FindFirst(Mask, faAnyFile, F);
  while Result = 0 do
  begin
    //FileName := ExtractFilePath(Mask) + F.FindData.cFileName;
    FileNames.Add(FileName);
    Result := FindNext(F);
  end;
  FindClose(F);
end;

procedure PrintFile(const FileName: string);
begin

end;

procedure TestFindFile;
var
  i: Integer;
  FileNames: TStrings;
begin
  FileNames := TStringList.Create;
  try
    FindFileNames('c:\P2\fiscal\*.p2t', FileNames);
    for i := 0 to FileNames.Count-1 do
      PrintFile(FileNames[i]);
  finally
    FileNames.Free;
  end;
end;


end.
