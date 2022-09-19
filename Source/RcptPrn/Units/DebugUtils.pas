unit DebugUtils;

interface

uses
  // VCL
  Windows;

procedure ODS(const S: string);

implementation

procedure ODS(const S: string);
begin
  OutputDebugString(PChar(S));
end;

end.
