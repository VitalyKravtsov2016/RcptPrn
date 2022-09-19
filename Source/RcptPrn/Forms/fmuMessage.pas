unit fmuMessage;

interface

uses
  // VCL
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, JvExComCtrls, JvAnimate, JvComponentBase, JvAnimTitle,
  StdCtrls, ExtCtrls, pngimage, jpeg, JvExExtCtrls, JvImage;

type
  TfmMessage = class(TForm)
    lblText: TLabel;
    Image2: TImage;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FCanClose: Boolean;
  public
    procedure Close2;
    procedure Show2(const AText: string);
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  fmMessage: TfmMessage;

implementation

uses fmuMain;

{$R *.dfm}


procedure TfmMessage.Show2(const AText: string);
begin
  lblText.Caption := AText;
  FCanClose := False;
  Show;
end;

procedure TfmMessage.Close2;
begin
  FCanClose := True;
  Close;
end;

procedure TfmMessage.CreateParams(var Params: TCreateParams);
begin
   inherited CreateParams(Params);
   Params.WndParent := GetDesktopWindow;
end;

procedure TfmMessage.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := FCanClose;
end;

end.

