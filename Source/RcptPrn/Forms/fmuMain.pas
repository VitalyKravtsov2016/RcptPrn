unit fmuMain;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, JvComponentBase, JvTrayIcon,
  // This
  untVInfo, FileManager, fmuPrinter, fmuAbout;

type
  TfmMain = class(TForm)
    TrayIcon1: TJvTrayIcon;
    pmTrayMenu: TPopupMenu;
    pmiShowHide: TMenuItem;
    pmiAbout: TMenuItem;
    N3: TMenuItem;
    btnPrintXReport: TMenuItem;
    btnPrintZReport: TMenuItem;
    miDivider2: TMenuItem;
    pmiTrayExit: TMenuItem;
    procedure pmiAboutClick(Sender: TObject);
    procedure pmiTrayExitClick(Sender: TObject);
    procedure btnPrintZReportClick(Sender: TObject);
    procedure btnPrintXReportClick(Sender: TObject);
    procedure pmiShowHideClick(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

uses fmuMessage;

{$R *.dfm}

procedure TfmMain.pmiAboutClick(Sender: TObject);
begin
  ShowAboutBox(Application.Handle, Application.Title,
    ['Версия программы: ' + GetFileVersionInfoStr]);
end;

procedure TfmMain.pmiTrayExitClick(Sender: TObject);
begin
  fmMessage.Close2;
  Close;
end;

procedure TfmMain.btnPrintZReportClick(Sender: TObject);
begin
  gFileManager.PrintReportZ;
end;

procedure TfmMain.btnPrintXReportClick(Sender: TObject);
begin
  gFileManager.PrintReportX;
end;

procedure TfmMain.pmiShowHideClick(Sender: TObject);
begin
  fmPrinter.Show;
end;

procedure TfmMain.TrayIcon1Click(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    fmPrinter.Visible := not fmPrinter.Visible;
  end;
end;

end.
