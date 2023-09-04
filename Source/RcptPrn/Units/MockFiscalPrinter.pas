unit MockFiscalPrinter;

interface

uses
  // This
  FiscalPrinterIntf, Receipt, ServerParams, DebugUtils;

type
  { TMockFiscalPrinter }

  TMockFiscalPrinter = class(TInterfacedObject, IFiscalPrinter)
  private
    procedure Stop;
    procedure Connect;
    procedure Disconnect;
    procedure CashOutcome;
    procedure CheckStatus;
    procedure PrintZReport;
    procedure PrintXReport;
    procedure ShowProperties;
    procedure OpenSession;
    function GetConnected: Boolean;
    function GetPrintWidth: Integer;
    function ZReportNotPrinted: Boolean;
    procedure SetPassword(const Value: Integer);
    procedure PrintReceipt(Receipt: TReceipt; Params: TServerParams);
    procedure PrintNonfiscalReceipt(Receipt: TReceipt; Params: TServerParams);
    procedure PrintReceipt2(Receipt: TReceipt; Params: TServerParams);
  end;

implementation

{ TMockFiscalPrinter }

procedure TMockFiscalPrinter.CashOutcome;
begin
  ODS('TMockFiscalPrinter.CashOutcome');
end;

procedure TMockFiscalPrinter.CheckStatus;
begin
  ODS('TMockFiscalPrinter.CheckStatus');
end;

procedure TMockFiscalPrinter.Connect;
begin
  ODS('TMockFiscalPrinter.Connect');
end;

procedure TMockFiscalPrinter.Disconnect;
begin
  ODS('TMockFiscalPrinter.Disconnect');
end;

function TMockFiscalPrinter.GetConnected: Boolean;
begin
  ODS('TMockFiscalPrinter.GetConnected');
  Result := False;
end;

function TMockFiscalPrinter.GetPrintWidth: Integer;
begin
  ODS('TMockFiscalPrinter.GetPrintWidth');
  Result := 0;
end;

procedure TMockFiscalPrinter.PrintNonfiscalReceipt(Receipt: TReceipt;
  Params: TServerParams);
begin
  ODS('TMockFiscalPrinter.PrintNonfiscalReceipt');
end;

procedure TMockFiscalPrinter.PrintReceipt(Receipt: TReceipt;
  Params: TServerParams);
begin
  ODS('TMockFiscalPrinter.PrintReceipt');
end;

procedure TMockFiscalPrinter.PrintZReport;
begin
  ODS('TMockFiscalPrinter.PrintZReport');
end;

procedure TMockFiscalPrinter.PrintXReport;
begin
  ODS('TMockFiscalPrinter.PrintXReport');
end;

procedure TMockFiscalPrinter.SetPassword(const Value: Integer);
begin
  ODS('TMockFiscalPrinter.SetPassword');
end;

procedure TMockFiscalPrinter.ShowProperties;
begin
  ODS('TMockFiscalPrinter.ShowProperties');
end;

function TMockFiscalPrinter.ZReportNotPrinted: Boolean;
begin
  ODS('TMockFiscalPrinter.ShowProperties');
  Result := False;
end;

procedure TMockFiscalPrinter.OpenSession;
begin
  ODS('TMockFiscalPrinter.OpenSession');
end;

procedure TMockFiscalPrinter.PrintReceipt2(Receipt: TReceipt;
  Params: TServerParams);
begin

end;

procedure TMockFiscalPrinter.Stop;
begin

end;

end.
