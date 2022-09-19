unit AutoScrollTest;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Forms,
  // This
  TestFramework,
  FileUtils, fmuAbout, fmuMain, fmuMessage, fmuPrinter, fmuSettings;


type
  { TAutoScrollTest }

  TAutoScrollTest = class(TTestCase)
  private
    procedure CheckAutoScroll(FormClass: TFormClass);
  published
    procedure CheckForms;
  end;

implementation

{ TAutoScrollTest }

procedure TAutoScrollTest.CheckAutoScroll(FormClass: TFormClass);
var
  Form: TForm;
begin
  Form := FormClass.Create(nil);
  try
    CheckEquals(False, Form.AutoScroll, 'AutoScroll=True. Form=' + Form.ClassName);
  finally
    Form.Free;
  end;
end;

procedure TAutoScrollTest.CheckForms;
begin
  CheckAutoScroll(TfmAbout);
  CheckAutoScroll(TfmMain);
  CheckAutoScroll(TfmMessage);
  CheckAutoScroll(TfmPrinter);
  CheckAutoScroll(TfmSEttings);
end;

initialization
  RegisterTest('', TAutoScrollTest.Suite);

end.
