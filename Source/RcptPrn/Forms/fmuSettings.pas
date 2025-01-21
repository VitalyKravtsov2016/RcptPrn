unit fmuSettings;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, ExtCtrls, ComCtrls,
  // This
  ServerParams, BrowseFolders, Form2;

type
  { TfmSettings }

  TfmSettings = class(TForm2)
    btnCancel: TButton;
    btnOk: TButton;
    btnDefaults: TButton;
    PageControl: TPageControl;
    tsPrometeo: TTabSheet;
    tsMain: TTabSheet;
    gbPrometeo: TGroupBox;
    lblReceiptMask: TLabel;
    Label2: TLabel;
    lblZReportMask: TLabel;
    edtReceiptMask: TEdit;
    btnReceiptMask: TButton;
    edtReturnSaleString: TEdit;
    edtZReportMask: TEdit;
    btnZReportMask: TButton;
    Label1: TLabel;
    edtFRPassword: TEdit;
    chbAutostartSrv: TCheckBox;
    chbBarcodeEnabled: TCheckBox;
    tsReceipt: TTabSheet;

    tsZReport: TTabSheet;
    chbZReportEnabled: TCheckBox;
    gbZReport: TGroupBox;
    btnProcessedReportPath: TButton;
    edtProcessedReportPath: TEdit;
    rbRepMove: TRadioButton;
    rbRepSaveTime: TRadioButton;
    rbRepDelete: TRadioButton;
    chbPollPrinter: TCheckBox;
    tsLogFile: TTabSheet;
    chbLogEnabled: TCheckBox;
    OpenDialog: TOpenDialog;
    edtLogPath: TEdit;
    lblLogPath: TLabel;
    gsLog: TGroupBox;
    chbUnknownPaytypeEnabled: TCheckBox;
    tsPayTypes: TTabSheet;
    lblCashReceipts: TLabel;
    mmCashPay: TMemo;
    lblCashPay: TLabel;
    gbAfterProcess: TGroupBox;
    edtProcessedReceiptPath: TEdit;
    rbRecMove: TRadioButton;
    btnProcessedReceiptPath: TButton;
    rbRecSaveTime: TRadioButton;
    rbRecDelete: TRadioButton;
    cbAfterError: TGroupBox;
    btnErrorReceiptPath: TButton;
    edtErrorReceiptPath: TEdit;
    chbCopyErrorReceipts: TCheckBox;
    lblCashlessPay: TLabel;
    mmCashlessPay: TMemo;
    chbReceiptCopyEnabled: TCheckBox;
    lblNonfiscal: TLabel;
    mmNonfiscalPay: TMemo;
    lblReceiptEncoding: TLabel;
    cbReceiptEncoding: TComboBox;
    chbChangeFileName: TCheckBox;
    edtFileNamePrefix: TEdit;
    lblFileNamePrefix: TLabel;
    chbSaveZReportEnabled: TCheckBox;
    edtZReportFilePath: TEdit;
    lblZReportFilePath: TLabel;
    btnZReportFilePath: TButton;
    lblDuplicateReceiptPath: TLabel;
    edtDuplicateReceiptPath: TEdit;
    btnDuplicateReceiptPath: TButton;
    chbStopAfterFile: TCheckBox;
    procedure btnOkClick(Sender: TObject);
    procedure btnDefaultsClick(Sender: TObject);
    procedure btnReceiptMaskClick(Sender: TObject);
    procedure btnZReportMaskClick(Sender: TObject);
    procedure edtFRPasswordKeyPress(Sender: TObject; var Key: Char);
    procedure btnProcessedReceiptPathClick(Sender: TObject);
    procedure btnProcessedReportPathClick(Sender: TObject);
    procedure btnErrorReceiptPathClick(Sender: TObject);
    procedure btnZReportFilePathClick(Sender: TObject);
    procedure btnDuplicateReceiptPathClick(Sender: TObject);
  private
    FParams: TServerParams;
    procedure UpdatePage(AParams: TServerParams);
    procedure UpdateObject(AParams: TServerParams);
  end;

function ShowSettingsDlg(AParams: TServerParams): Boolean;

implementation

{$R *.DFM}

function ShowSettingsDlg(AParams: TServerParams): Boolean;
var
  fm: TfmSettings;
begin
  fm := TfmSettings.Create(nil);
  try
    fm.FParams := AParams;
    fm.UpdatePage(AParams);
    Result := fm.ShowModal = mrOK;
  finally
    fm.Free;
  end;
end;

procedure TfmSettings.UpdatePage(AParams: TServerParams);
begin
  // Закладка "Основные"
  chbAutostartSrv.Checked := AParams.AutostartSrv;
  chbBarcodeEnabled.Checked := AParams.BarcodeEnabled;
  chbPollPrinter.Checked := AParams.PollPrinter;
  chbUnknownPaytypeEnabled.Checked := AParams.UnknownPaytypeEnabled;
  chbReceiptCopyEnabled.Checked := AParams.ReceiptCopyEnabled;
  chbStopAfterFile.Checked := AParams.StopAfterFile;
  edtFRPassword.Text := IntToStr(AParams.DriverPassword);
  // Закладка "Prometeo"
  edtReceiptMask.Text := AParams.ReceiptMask;
  edtZReportMask.Text := AParams.ZReportMask;
  edtReturnSaleString.Text := AParams.ReturnSale;
  cbReceiptEncoding.ItemIndex := AParams.ReceiptEncoding;
  // Закладка "Чеки"
  rbRecMove.Checked := AParams.ReceiptMode = fmMove;
  rbRecDelete.Checked := AParams.ReceiptMode = fmDelete;
  rbRecSaveTime.Checked := AParams.ReceiptMode = fmSaveTime;
  edtProcessedReceiptPath.Text := AParams.ProcessedReceiptPath;
  edtDuplicateReceiptPath.Text := AParams.DuplicateReceiptPath;
  edtErrorReceiptPath.Text := AParams.ErrorReceiptPath;
  chbCopyErrorReceipts.Checked := AParams.CopyErrorReceipts;
  chbChangeFileName.Checked := AParams.ChangeFileName;
  edtFileNamePrefix.Text := AParams.FileNamePrefix;
  // Закладка "Отчеты"
  rbRepMove.Checked := AParams.ReportMode = fmMove;
  chbZReportEnabled.Checked := AParams.ZReportEnabled;
  rbRepDelete.Checked := AParams.ReportMode = fmDelete;
  rbRepSaveTime.Checked := AParams.ReportMode = fmSaveTime;
  edtProcessedReportPath.Text := AParams.ProcessedReportPath;

  edtZReportFilePath.Text := AParams.ZReportFilePath;
  chbSaveZReportEnabled.Checked := AParams.SaveZReportEnabled;
  // Закладка "Лог файл"
  edtLogPath.Text := AParams.LogFilePath;
  chbLogEnabled.Checked := AParams.LogFileEnabled;
  // Закладка "Типы оплат"
  mmCashPay.Lines := AParams.CashNames;
  mmCashlessPay.Lines := AParams.CashlessNames;
  mmNonfiscalPay.Lines := AParams.NonfiscalNames;
end;

procedure TfmSettings.UpdateObject(AParams: TServerParams);
begin
  if edtReceiptMask.Text = '' then
    raise Exception.Create('Укажите маску для файлов чеков');
  if edtZReportMask.Text = '' then
    raise Exception.Create('Укажите маску для файлов Z-отчетов');
  // Закладка "Основные"
  AParams.PollPrinter := chbPollPrinter.Checked;
  AParams.AutostartSrv := chbAutostartSrv.Checked;
  AParams.BarcodeEnabled := chbBarcodeEnabled.Checked;
  AParams.UnknownPaytypeEnabled := chbUnknownPaytypeEnabled.Checked;
  AParams.ReceiptCopyEnabled := chbReceiptCopyEnabled.Checked;
  AParams.StopAfterFile := chbStopAfterFile.Checked;
  AParams.DriverPassword := StrToInt(edtFRPassword.Text);
  // Закладка "Prometeo"
  AParams.ReceiptMask := edtReceiptMask.Text;
  AParams.ZReportMask := edtZReportMask.Text;
  AParams.ReturnSale := edtReturnSaleString.Text;
  AParams.ReceiptEncoding := cbReceiptEncoding.ItemIndex;
  AParams.ChangeFileName := chbChangeFileName.Checked;
  AParams.FileNamePrefix := edtFileNamePrefix.Text;
  // Закладка "Чеки"
  if rbRecMove.Checked then AParams.ReceiptMode := fmMove;
  if rbRecDelete.Checked then AParams.ReceiptMode := fmDelete;
  if rbRecSaveTime.Checked then AParams.ReceiptMode := fmSaveTime;
  AParams.ProcessedReceiptPath := edtProcessedReceiptPath.Text;
  AParams.DuplicateReceiptPath := edtDuplicateReceiptPath.Text;
  AParams.ErrorReceiptPath := edtErrorReceiptPath.Text;
  AParams.CopyErrorReceipts := chbCopyErrorReceipts.Checked;
  // Закладка "Отчеты"
  AParams.ZReportEnabled := chbZReportEnabled.Checked;
  if rbRepMove.Checked then AParams.ReportMode := fmMove;
  if rbRepDelete.Checked then AParams.ReportMode := fmDelete;
  if rbRepSaveTime.Checked then AParams.ReportMode := fmSaveTime;
  AParams.ProcessedReportPath := edtProcessedReportPath.Text;
  AParams.ZReportFilePath := edtZReportFilePath.Text;
  AParams.SaveZReportEnabled := chbSaveZReportEnabled.Checked;
  // Закладка "Лог файл"
  AParams.LogFilePath := edtLogPath.Text;
  AParams.LogFileEnabled := chbLogEnabled.Checked;
  // Закладка "Типы оплат"
  AParams.CashNames := mmCashPay.Lines;
  AParams.CashlessNames := mmCashlessPay.Lines;
  AParams.NonfiscalNames := mmNonfiscalPay.Lines;
  // Сохранение параметров
  AParams.SaveToIniFile;
end;

procedure TfmSettings.btnOkClick(Sender: TObject);
begin
  UpdateObject(FParams);
  ModalResult := mrOK;
end;

procedure TfmSettings.btnDefaultsClick(Sender: TObject);
var
  ServerParams: TServerParams;
begin
  ServerParams := TServerParams.Create;
  try
    ServerParams.SetDefaults;
    UpdatePage(ServerParams);
  finally
    ServerParams.Free;
  end;
end;

procedure TfmSettings.btnReceiptMaskClick(Sender: TObject);
var
  S: string;
begin
  S := edtReceiptMask.Text;
  if BrowseFolder(Handle, S, 'Укажите папку файлов чеков', 0) then
    edtReceiptMask.Text := S;
end;

procedure TfmSettings.btnZReportMaskClick(Sender: TObject);
var
  S: string;
begin
  S := edtZReportMask.Text;
  if BrowseFolder(Handle, S, 'Укажите папку Z-отчетов', 0) then
    edtZReportMask.Text := S;
end;

procedure TfmSettings.edtFRPasswordKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not (Key in ['0'..'9']) and (Key <> #8) then Key := #0;
end;

procedure TfmSettings.btnProcessedReceiptPathClick(Sender: TObject);
var
  S: string;
begin
  S := edtProcessedReceiptPath.Text;
  if BrowseFolder(Handle, S, 'Укажите путь к папке', 0) then
    edtProcessedReceiptPath.Text := S;
end;

procedure TfmSettings.btnProcessedReportPathClick(Sender: TObject);
var
  S: string;
begin
  S := edtProcessedReportPath.Text;
  if BrowseFolder(Handle, S, 'Укажите путь к папке', 0) then
    edtProcessedReportPath.Text := S;
end;

procedure TfmSettings.btnErrorReceiptPathClick(Sender: TObject);
var
  S: string;
begin
  S := edtErrorReceiptPath.Text;
  if BrowseFolder(Handle, S, 'Укажите путь к папке', 0) then
    edtErrorReceiptPath.Text := S;
end;

procedure TfmSettings.btnZReportFilePathClick(Sender: TObject);
var
  S: string;
begin
  S := edtZReportFilePath.Text;
  if BrowseFolder(Handle, S, 'Укажите путь к папке', 0) then
    edtZReportFilePath.Text := S;
end;

procedure TfmSettings.btnDuplicateReceiptPathClick(Sender: TObject);
var
  S: string;
begin
  S := edtDuplicateReceiptPath.Text;
  if BrowseFolder(Handle, S, 'Укажите путь к папке', 0) then
    edtDuplicateReceiptPath.Text := S;
end;

end.
