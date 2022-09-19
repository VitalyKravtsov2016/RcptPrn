unit ReceiptTest;

interface

uses
  // VCL
  Windows, Classes, SysUtils, Forms,
  // This
  TestFramework, FileUtils, TntClasses, Receipt, ServerParams;


type
  { TReceiptTest }

  TReceiptTest = class(TTestCase)
  private
    procedure CheckReceipt(const FileName: WideString);
  published
    procedure CheckReceipts;
    procedure CheckReceipt1;
    procedure CheckReceipt2;
  end;

implementation

function GetReceiptsDir: WideString;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(FileUtils.GetModuleFileName));
  Result := IncludeTrailingPathDelimiter(Result + 'Receipts');
end;

{ TReceiptTest }

procedure TReceiptTest.CheckReceipts;
var
  i: Integer;
  Mask: WideString;
  FileNames: TTntStrings;
begin
  FileNames := TTntStringList.Create;
  try
    Mask := GetReceiptsDir + '*.P2T';
    GetFileNames(Mask, FileNames);
    CheckEquals(86, FileNames.Count, 'Invalid FileNames.Count');
    for i := 0 to FileNames.Count-1 do
    begin
      CheckReceipt(FileNames[i]);
    end;
  finally
    FileNames.Free;
  end;
end;

(*
13072022 0933;;;K;TICKET; ;40870; ;
13072022 0933;;;N;7;40870;13.07.2022 09:33:57;13.07.2022 00:00:00;320,0000; ; ; ;
13072022 0933;;;F;�����; ;40870; ;
13072022 0933;;;A;��������,�����,�����; ;40870001; ;01010001102
13072022 0933;;;S;��������� � ������;320,00;40870001;0,00;05000005000
13072022 0933;;;R;����� 75%;;;;06000006016
13072022 0933;;;R;������ ����������;;;;06000006015
13072022 0933;;;R;������ ������ �����;;;;06000006017
13072022 0933;;;R;����� ��� ��������;;;;06000006003
13072022 0933;;;T;�����;320,00;40870000; ;
13072022 0933;;;G;������ ���������;320,00;40870; ;09040009400
13072022 0933;;;U;�����;520,00;40870; ;09040009400
13072022 0933;;;U;���������� ���������;200,00;40870; ;09040009400

*)

procedure TReceiptTest.CheckReceipt(const FileName: WideString);
var
  Receipt: TReceipt;
begin
  Receipt := TReceipt.Create;
  try
    Receipt.LoadFromFile(FileName);
    CheckEquals(Receipt.Total, Receipt.ItemsTotal, 'Receipt.ItemsTotal');
    CheckEquals(Receipt.Total, Receipt.PaymentsTotal-Receipt.Change, 'Receipt.PaymentsTotal-Receipt.Change');
    CheckEquals(False, Receipt.IsReturn, 'Receipt.IsReturn');
  except
    on E: Exception do
    begin
      E.Message := FileName + ', ' + E.Message;
      Receipt.Free;
      raise;
    end;
  end;
  Receipt.Free;
end;

(*
13072022 0933;;;K;TICKET; ;40870; ;
13072022 0933;;;N;7;40870;13.07.2022 09:33:57;13.07.2022 00:00:00;320,0000; ; ; ;
13072022 0933;;;F;�����; ;40870; ;
13072022 0933;;;A;��������,�����,�����; ;40870001; ;01010001102
13072022 0933;;;S;��������� � ������;320,00;40870001;0,00;05000005000
13072022 0933;;;R;����� 75%;;;;06000006016
13072022 0933;;;R;������ ����������;;;;06000006015
13072022 0933;;;R;������ ������ �����;;;;06000006017
13072022 0933;;;R;����� ��� ��������;;;;06000006003
13072022 0933;;;T;�����;320,00;40870000; ;
13072022 0933;;;G;������ ���������;320,00;40870; ;09040009400
13072022 0933;;;U;�����;520,00;40870; ;09040009400
13072022 0933;;;U;���������� ���������;200,00;40870; ;09040009400
*)


procedure TReceiptTest.CheckReceipt1;
var
  Receipt: TReceipt;
  Item: TReceiptItem;
  FileName: WideString;
begin
  Params.ReceiptEncoding := ReceiptEncodingUTF8;
  Receipt := TReceipt.Create;
  try
    FileName := GetReceiptsDir + 'RU000140870.P2T';
    Receipt.LoadFromFile(FileName);

    CheckEquals(1, Receipt.Items.Count, 'Receipt.Items.Count');
    Item := Receipt.Items.Items[0] as TReceiptItem;
    CheckEquals('��������,�����,�����, ��������� � ������', Item.Text, 'Item.Text');
    CheckEquals(320.00, Item.Total, 'Item.Total');
    CheckEquals(0.00, Item.Discount, 'Item.Discount');
    CheckEquals(4, Item.Notes.Count, 'Item.Notes.Count');
    CheckEquals('����� 75%', Item.Notes[0], 'Item.Notes[0]');
    CheckEquals('������ ����������', Item.Notes[1], 'Item.Notes[1]');
    CheckEquals('������ ������ �����', Item.Notes[2], 'Item.Notes[2]');
    CheckEquals('����� ��� ��������', Item.Notes[3], 'Item.Notes[3]');
    CheckEquals(320.00, Receipt.Total, 'Receipt.Total');
    CheckEquals('������ ���������', Receipt.Payments[1].Name, 'Receipt.Payments[1].Name');
    CheckEquals(320, Receipt.Payments[1].Amount, 'Receipt.Payments[1].Amount');
  finally
    Receipt.Free;
  end;
end;

(*

13072022 1029;;;K;TICKET; ;40874; ;
13072022 1029;;;N;7;40874;13.07.2022 10:29:54;13.07.2022 00:00:00;4040,0000; ; ; ;
13072022 1029;;;F;�����; ;40874; ;
13072022 1029;;;A;������; ;40874001; ;01040001400
13072022 1029;;;S;��������� � ������;680,00;40874001;0,00;05000005000
13072022 1029;;;S;�������             ;200,00;40874001;0,00;05010005052
13072022 1029;;;R;����� 50%;;;;06000006026
13072022 1029;;;R;������ ����������;;;;06000006015
13072022 1029;;;R;�������� ��� ������.;;;;06000006004
13072022 1029;;;R;����� ��� ��������;;;;06000006003
13072022 1029;;;A;������; ;40874002; ;01040001400
13072022 1029;;;S;��������� � ������;680,00;40874002;0,00;05000005000
13072022 1029;;;S;�������             ;200,00;40874002;0,00;05010005052
13072022 1029;;;R;����� 50%;;;;06000006026
13072022 1029;;;R;������ ����������;;;;06000006015
13072022 1029;;;R;�������� ��� ������.;;;;06000006004
13072022 1029;;;R;����� ��� ��������;;;;06000006003
13072022 1029;;;A;������; ;40874003; ;01040001400
13072022 1029;;;S;��������� � ������;680,00;40874003;0,00;05000005000
13072022 1029;;;S;�������             ;200,00;40874003;0,00;05010005052
13072022 1029;;;R;����� 50%;;;;06000006026
13072022 1029;;;R;������ ����������;;;;06000006015
13072022 1029;;;R;�������� ��� ������.;;;;06000006004
13072022 1029;;;R;����� ��� ��������;;;;06000006003
13072022 1029;;;A;������ �����/�����; ;40874004; ;01050001505
13072022 1029;;;S;������ � ������     ;1130,00;40874004;0,00;05000505050
13072022 1029;;;S;�������             ;270,00;40874004;0,00;05010005052
13072022 1029;;;R;����� 50%;;;;06000006026
13072022 1029;;;R;������ ����������;;;;06000006015
13072022 1029;;;R;���� ����������;;;;06000006015
13072022 1029;;;R;��������� ���������;;;;06000006007
13072022 1029;;;R;����� ��� ��������;;;;06000006003
13072022 1029;;;T;�����;4040,00;40874000; ; 
13072022 1029;;;G;������ ������;4040,00;40874; ;09040009415

*)

procedure TReceiptTest.CheckReceipt2;
var
  Receipt: TReceipt;
  Item: TReceiptItem;
  FileName: WideString;
begin
  Params.ReceiptEncoding := ReceiptEncodingUTF8;
  Receipt := TReceipt.Create;
  try
    FileName := GetReceiptsDir + 'RU000140874.P2T';
    Receipt.LoadFromFile(FileName);

    CheckEquals(8, Receipt.Items.Count, 'Receipt.Items.Count');

    Item := Receipt.Items.Items[0] as TReceiptItem;
    CheckEquals('������, ��������� � ������', Item.Text, 'Item.Text');
    CheckEquals(680.00, Item.Total, 'Item.Total');
    CheckEquals(0.00, Item.Discount, 'Item.Discount');
    CheckEquals(0, Item.Notes.Count, 'Item.Notes.Count');
    Item := Receipt.Items.Items[1] as TReceiptItem;
    CheckEquals('������, �������', Item.Text, 'Item.Text');
    CheckEquals(200.00, Item.Total, 'Item.Total');
    CheckEquals(0.00, Item.Discount, 'Item.Discount');
    CheckEquals(4, Item.Notes.Count, 'Item.Notes.Count');
    CheckEquals('����� 50%', Item.Notes[0], 'Item.Notes[0]');
    CheckEquals('������ ����������', Item.Notes[1], 'Item.Notes[1]');
    CheckEquals('�������� ��� ������.', Item.Notes[2], 'Item.Notes[2]');
    CheckEquals('����� ��� ��������', Item.Notes[3], 'Item.Notes[3]');

    CheckEquals(4040.00, Receipt.Total, 'Receipt.Total');
    CheckEquals('������ ������', Receipt.Payments[2].Name, 'Receipt.Payments[2].Name');
    CheckEquals(4040.00, Receipt.Payments[2].Amount, 'Receipt.Payments[2].Amount');
  finally
    Receipt.Free;
  end;
end;

initialization
  RegisterTest('', TReceiptTest.Suite);

end.
