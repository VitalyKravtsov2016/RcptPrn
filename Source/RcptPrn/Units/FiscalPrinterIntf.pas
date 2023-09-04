unit FiscalPrinterIntf;

interface

uses
  // This
  Receipt, ServerParams;

type
  IFiscalPrinter = interface
  ['{2A352C19-4DFB-41DA-B4FD-4E85FF4A90AB}']
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

    property Connected: Boolean read GetConnected;
    property PrintWidth: Integer read GetPrintWidth;
  end;

implementation

end.
