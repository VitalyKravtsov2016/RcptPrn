unit Form2;

interface

uses
  // VCL
  Windows, Forms, Classes, SysUtils, Graphics;

(******************************************************************************

  ������� ����� ��� ���� ���� ����������

  1. ReadState ��������, ����� ��� �������� ������ ��������� ����
     ����� �� ���������� �����.

******************************************************************************)

type
  { TForm2 }

  TForm2 = class(TForm)
  protected
    procedure ReadState(Reader: TReader); override;
  end;

implementation

{ TForm2 }

procedure TForm2.ReadState(Reader: TReader);
begin
  DisableAlign;
  try
    inherited ReadState(Reader);
    if BorderStyle = bsSizeable then
    begin
      Height := Height + GetSystemMetrics(SM_CYCAPTION) - 19 +
        (GetSystemMetrics(SM_CYSIZEFRAME)-GetSystemMetrics(SM_CYEDGE)-1)*2;

      Width := Width +
        (GetSystemMetrics(SM_CXSIZEFRAME)-GetSystemMetrics(SM_CXEDGE)-1)*2;
    end;
  finally
    EnableAlign;
  end;
end;

end.
