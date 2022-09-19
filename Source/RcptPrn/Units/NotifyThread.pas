unit NotifyThread;

interface

uses
  // VCL
  Classes;

type
  { TNotifyThread }

  TNotifyThread = class(TThread)
  private
    FOnExecute: TNotifyEvent;
  protected
    procedure Execute; override;
  public
    constructor CreateThread(AOnExecute: TNotifyEvent);
  published
    property Terminated;
  end;

implementation


{ TNotifyThread }

constructor TNotifyThread.CreateThread(AOnExecute: TNotifyEvent);
begin
  FOnExecute := AOnExecute;
  inherited Create(False);
end;

procedure TNotifyThread.Execute;
begin
  if Assigned(FOnExecute) then
    FOnExecute(Self);
end;

end.
