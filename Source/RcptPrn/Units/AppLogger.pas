unit AppLogger;

interface

uses
  // VCL
  SysUtils;
  
type
  TStringEvent = procedure(Sender: TObject; const Data: string) of Object;

  { TAppLogger }

  TAppLogger = class
  private
    FOnData: TStringEvent;
  public
    procedure AddLine(const Data: string);
    property OnData: TStringEvent read FOnData write FOnData;
  end;

var
  Logger: TAppLogger;

implementation

{ TAppLogger }

procedure TAppLogger.AddLine(const Data: string);
var
  S: string;
begin
  S := FormatDateTime('[hh:nn:ss] ', Now) + Data;
  if Assigned(FOnData) then FOnData(Self, S);
end;

initialization
  Logger := TAppLogger.Create;

finalization
  Logger.Free;

end.
