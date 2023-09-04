unit fmuPrinter;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ToolWin, ComCtrls, StdCtrls, ExtCtrls, Buttons, ImgList,
  // 3'd
  PngSpeedButton, PngImageList, JvComponentBase, JvTrayIcon,
  // This
  FileManager, fmuAbout, fmuSettings, untVInfo, Form2, untUtil,
  AppLogger, ServerParams, untLogFile;

const
  WM_SERVEREVENT = WM_USER + 1;

type
  TfmPrinter = class(TForm2)
    mmuMainMenu: TMainMenu;
    pmLogMemo: TPopupMenu;
    miFile: TMenuItem;
    miExit: TMenuItem;
    miSettings: TMenuItem;
    miDrvParams: TMenuItem;
    miAppParams: TMenuItem;
    miHelp: TMenuItem;
    miAppAbout: TMenuItem;
    miLogClear: TMenuItem;
    miLogSave: TMenuItem;
    tbMain: TToolBar;
    tbtnDivider3: TToolButton;
    tbtnDivider4: TToolButton;
    StatusBar: TStatusBar;
    miReceiptPrint: TMenuItem;
    ToolButton2: TToolButton;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    Memo: TMemo;
    miServerStart: TMenuItem;
    miServerStop: TMenuItem;
    N2: TMenuItem;
    N4: TMenuItem;
    N1: TMenuItem;
    miFont: TMenuItem;
    FontDialog: TFontDialog;
    N5: TMenuItem;
    mmiPrintXReport: TMenuItem;
    mmiPrintZReport: TMenuItem;
    PngImageList1: TPngImageList;
    btnReceiptPrint: TPngSpeedButton;
    btnServerStart: TPngSpeedButton;
    btnServerStop: TPngSpeedButton;
    btnDrvParams: TPngSpeedButton;
    btnAppParams: TPngSpeedButton;
    btnAppAbout: TPngSpeedButton;
    procedure LogClear(Sender: TObject);
    procedure DriverProperties(Sender: TObject);
    procedure ProgramParams(Sender: TObject);
    procedure ProgramAbout(Sender: TObject);
    procedure ServerStart(Sender: TObject);
    procedure ServerStop(Sender: TObject);
    procedure ReceiptPrint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LogSave(Sender: TObject);
    procedure miFontClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pmiTrayExitClick(Sender: TObject);
    procedure PrintXReportClick(Sender: TObject);
    procedure PrintZReportClick(Sender: TObject);
    procedure pmiShowHideClick(Sender: TObject);
    procedure TrayIcon1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure miExitClick(Sender: TObject);
  private
    FFileManager: TFileManager;
    procedure UpdateControls;
    function GetFileManager: TFileManager;
    procedure LoggerData(Sender: TObject; const Data: string);
    procedure WMServerEvent(var Message: TMessage); message WM_SERVEREVENT;
    procedure ServerEvent(Sender: TObject; EventType: TEventType; const S: string);

    property FileManager: TFileManager read GetFileManager;
    procedure ShowOrHide;
    procedure AppMinimize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  fmPrinter: TfmPrinter;

implementation

{$R *.DFM}

function GetAnimation: Boolean;
var
  Info: TAnimationInfo;
begin
  Info.cbSize := SizeOf(TAnimationInfo);
  if SystemParametersInfo(SPI_GETANIMATION, SizeOf(Info), @Info, 0) then
    Result := Info.iMinAnimate <> 0 else
    Result := False;
end;

procedure SetAnimation(Value: Boolean);
var
  Info: TAnimationInfo;
begin
  Info.cbSize := SizeOf(TAnimationInfo);
  BOOL(Info.iMinAnimate) := Value;
  SystemParametersInfo(SPI_SETANIMATION, SizeOf(Info), @Info, 0);
end;

procedure ShowWinNoAnimate(Handle: HWnd; CmdShow: Integer);
var
  Animation: Boolean;
begin
  Animation := GetAnimation;
  if Animation then SetAnimation(False);
  ShowWindow(Handle, CmdShow);
  if Animation then SetAnimation(True);
end;

{ TfmMain }

constructor TfmPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Logger.OnData := LoggerData;
  Application.OnMinimize := AppMinimize;
end;

destructor TfmPrinter.Destroy;
begin
  Logger.OnData := nil;
  FFileManager.Free;
  inherited Destroy;
end;

procedure TfmPrinter.AppMinimize(Sender: TObject);
begin
  ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TfmPrinter.UpdateControls;
var
  ServerStarted: Boolean;
begin
  ServerStarted := FileManager.Started;
  // ToolBar
  btnServerStop.Enabled := ServerStarted;
  btnServerStart.Enabled := not ServerStarted;
  btnReceiptPrint.Enabled := not ServerStarted;
  btnDrvParams.Enabled := not ServerStarted;
  btnAppParams.Enabled := not ServerStarted;
  // Main menu
  miServerStop.Enabled := ServerStarted;
  miServerStart.Enabled := not ServerStarted;
  miReceiptPrint.Enabled := not ServerStarted;
  miDrvParams.Enabled := not ServerStarted;
  miAppParams.Enabled := not ServerStarted;
  StatusBar.SimpleText := FileManager.State;
end;

// Событие от сервера

procedure TfmPrinter.ServerEvent(Sender: TObject; EventType: TEventType;
  const S: string);
var
  Dst: PChar;
begin
  GetMem(Dst, Length(S)+1);
  StrCopy(Dst, PChar(S));
  PostMessage(Handle, WM_SERVEREVENT, Integer(Dst), Ord(EventType));
end;

procedure TfmPrinter.LoggerData(Sender: TObject; const Data: string);
var
  Dst: PChar;
begin
  GetMem(Dst, Length(Data)+1);
  StrCopy(Dst, PChar(Data));
  PostMessage(Handle, WM_SERVEREVENT, Integer(Dst), Ord(ctLog));
end;

procedure TfmPrinter.WMServerEvent(var Message: TMessage);
var
  S: string;
  EventType: TEventType;
begin
  EventType := TEventType(Message.lparam);
  case EventType of
    ctState: UpdateControls;
    ctError:
    begin
      S := PChar(Message.wparam);
      FreeMem(PChar(Message.wparam));

      if not Visible then
        MessageBox(Handle, PChar(S), PChar(Application.Title), MB_ICONERROR);
    end;
    ctLog:
    begin
      S := PChar(Message.wparam);
      FreeMem(PChar(Message.wparam));

      while Memo.Lines.Count >= 100 do
        Memo.Lines.Delete(0);

      Memo.Lines.Add(S)
    end;
  end;
end;

// Создаем cервер по обращению

function TfmPrinter.GetFileManager: TFileManager;
begin
  if FFileManager = nil then
  begin
    FFileManager := TFileManager.Create(nil);
    FFileManager.OnEvent := ServerEvent;
  end;
  Result := FFileManager;
end;

// Настройки драйвера

procedure TfmPrinter.DriverProperties(Sender: TObject);
begin
  FileManager.ShowPrinterProperties;
end;

// Настройки

procedure TfmPrinter.ProgramParams(Sender: TObject);
begin
  ShowSettingsDlg(Params);
end;

// О программе

procedure TfmPrinter.ProgramAbout(Sender: TObject);
begin
  ShowAboutBox(Application.Handle, Application.Title,
    ['Версия программы: ' + GetFileVersionInfoStr]);
end;

// Выход

procedure TfmPrinter.ServerStart(Sender: TObject);
begin
  FileManager.Start;
end;

procedure TfmPrinter.ServerStop(Sender: TObject);
begin
  FileManager.Stop;
end;

procedure TfmPrinter.ReceiptPrint(Sender: TObject);
begin
  OpenDialog.InitialDir := Params.ReceiptMask;
  if OpenDialog.Execute then
    FileManager.PrintFile(OpenDialog.FileName);
end;

procedure TfmPrinter.FormCreate(Sender: TObject);
begin
  Caption := Application.Title + '  ' + GetFileVersionInfoStr;
  UpdateControls;
  FileManager.Initialize;
end;

// Сохранить лог

procedure TfmPrinter.LogSave(Sender: TObject);
begin
  if SaveDialog.Execute then
    Memo.Lines.SaveToFile(SaveDialog.FileName);
end;

// Очистить лог

procedure TfmPrinter.LogClear(Sender: TObject);
begin
  Memo.Clear;
end;

procedure TfmPrinter.miFontClick(Sender: TObject);
begin
  FontDialog.Font := Memo.Font;
  if FontDialog.Execute then
    Memo.Font := FontDialog.Font;
end;

procedure TfmPrinter.ShowOrHide;
begin
  if IsWindowVisible(Application.Handle) then
  begin
    ShowWinNoAnimate(Application.Handle, SW_MINIMIZE);
    ShowWinNoAnimate(Application.Handle, SW_HIDE);
  end else
  begin
    ShowWinNoAnimate(Application.Handle, SW_RESTORE);
    SetForeGroundWindow(Application.MainForm.Handle);
  end;
end;

procedure TfmPrinter.TrayIcon1Click(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ShowOrHide;
end;

procedure TfmPrinter.pmiTrayExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfmPrinter.PrintXReportClick(Sender: TObject);
begin
  FileManager.PrintReportX;
end;

procedure TfmPrinter.PrintZReportClick(Sender: TObject);
begin
  FileManager.PrintReportZ;
end;

procedure TfmPrinter.pmiShowHideClick(Sender: TObject);
begin
  ShowOrHide;
end;

procedure TfmPrinter.TrayIcon1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then ShowOrHide;
end;

procedure TfmPrinter.miExitClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.
