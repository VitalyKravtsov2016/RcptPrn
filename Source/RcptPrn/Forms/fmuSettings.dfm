object fmSettings: TfmSettings
  Left = 386
  Top = 199
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = #1053#1072#1089#1090#1088#1086#1081#1082#1080
  ClientHeight = 384
  ClientWidth = 439
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  DesignSize = (
    439
    384)
  PixelsPerInch = 96
  TextHeight = 13
  object btnCancel: TButton
    Left = 360
    Top = 352
    Width = 73
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    ModalResult = 2
    TabOrder = 3
  end
  object btnOk: TButton
    Left = 280
    Top = 352
    Width = 73
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = btnOkClick
  end
  object btnDefaults: TButton
    Left = 8
    Top = 352
    Width = 97
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = #1055#1086' '#1091#1084#1086#1083#1095#1072#1085#1080#1102
    TabOrder = 1
    OnClick = btnDefaultsClick
  end
  object PageControl: TPageControl
    Left = 8
    Top = 8
    Width = 425
    Height = 337
    ActivePage = tsMain
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object tsMain: TTabSheet
      Caption = #1054#1089#1085#1086#1074#1085#1099#1077
      ImageIndex = 1
      object Label1: TLabel
        Left = 16
        Top = 172
        Width = 149
        Height = 13
        Caption = #1055#1072#1088#1086#1083#1100' '#1072#1076#1084#1080#1085#1080#1089#1090#1088#1072#1090#1086#1088#1072' '#1060#1056':'
      end
      object edtFRPassword: TEdit
        Left = 176
        Top = 168
        Width = 153
        Height = 21
        TabOrder = 5
        Text = '30'
        OnKeyPress = edtFRPasswordKeyPress
      end
      object chbAutostartSrv: TCheckBox
        Left = 8
        Top = 40
        Width = 217
        Height = 17
        Caption = #1042#1082#1083#1102#1095#1072#1090#1100' '#1087#1088#1080#1085#1090#1077#1088' '#1095#1077#1082#1086#1074' '#1087#1088#1080' '#1079#1072#1087#1091#1089#1082#1077
        TabOrder = 1
      end
      object chbBarcodeEnabled: TCheckBox
        Left = 8
        Top = 16
        Width = 217
        Height = 17
        Caption = #1055#1077#1095#1072#1090#1072#1090#1100' '#1096#1090#1088#1080#1093'-'#1082#1086#1076
        TabOrder = 0
      end
      object chbPollPrinter: TCheckBox
        Left = 8
        Top = 64
        Width = 369
        Height = 17
        Caption = #1054#1087#1088#1072#1096#1080#1074#1072#1090#1100' '#1087#1088#1080#1085#1090#1077#1088
        TabOrder = 2
      end
      object chbUnknownPaytypeEnabled: TCheckBox
        Left = 8
        Top = 88
        Width = 361
        Height = 17
        Caption = #1055#1077#1095#1072#1090#1072#1090#1100' '#1095#1077#1082#1080' '#1089' '#1085#1077#1080#1079#1074#1077#1089#1090#1085#1099#1084#1080' '#1090#1080#1087#1072#1084#1080' '#1086#1087#1083#1072#1090#1099
        TabOrder = 3
      end
      object chbReceiptCopyEnabled: TCheckBox
        Left = 8
        Top = 112
        Width = 361
        Height = 17
        Caption = #1055#1077#1095#1072#1090#1072#1090#1100' '#1082#1086#1087#1080#1102' '#1095#1077#1082#1086#1074
        TabOrder = 4
      end
    end
    object tsPrometeo: TTabSheet
      Caption = 'Prometeo'
      DesignSize = (
        417
        309)
      object gbPrometeo: TGroupBox
        Left = 8
        Top = 8
        Width = 401
        Height = 289
        Anchors = [akLeft, akTop, akRight, akBottom]
        Caption = #1057#1080#1089#1090#1077#1084#1072' Prometeo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        DesignSize = (
          401
          289)
        object lblReceiptMask: TLabel
          Left = 8
          Top = 24
          Width = 109
          Height = 13
          Caption = #1052#1072#1089#1082#1072' '#1092#1072#1081#1083#1086#1074' '#1095#1077#1082#1086#1074':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object Label2: TLabel
          Left = 8
          Top = 128
          Width = 136
          Height = 13
          Caption = #1042#1086#1079#1074#1088#1072#1090' '#1087#1088#1086#1076#1072#1078#1080' '#1074' '#1092#1072#1081#1083#1077':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object lblZReportMask: TLabel
          Left = 8
          Top = 72
          Width = 129
          Height = 13
          Caption = #1052#1072#1089#1082#1072' '#1092#1072#1081#1083#1086#1074' Z-'#1086#1090#1095#1077#1090#1086#1074':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object lblReceiptEncoding: TLabel
          Left = 8
          Top = 184
          Width = 84
          Height = 13
          Caption = #1050#1086#1076#1080#1088#1086#1074#1082#1072' '#1095#1077#1082#1072':'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
        end
        object edtReceiptMask: TEdit
          Left = 8
          Top = 40
          Width = 353
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object btnReceiptMask: TButton
          Left = 368
          Top = 38
          Width = 25
          Height = 25
          Anchors = [akTop, akRight]
          Caption = '...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = btnReceiptMaskClick
        end
        object edtReturnSaleString: TEdit
          Left = 8
          Top = 144
          Width = 353
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 4
        end
        object edtZReportMask: TEdit
          Left = 8
          Top = 88
          Width = 353
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
        end
        object btnZReportMask: TButton
          Left = 368
          Top = 86
          Width = 25
          Height = 25
          Anchors = [akTop, akRight]
          Caption = '...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
          OnClick = btnZReportMaskClick
        end
        object cbReceiptEncoding: TComboBox
          Left = 8
          Top = 208
          Width = 353
          Height = 21
          Style = csDropDownList
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ItemHeight = 13
          ParentFont = False
          TabOrder = 5
          Items.Strings = (
            'CP866'
            'UTF8')
        end
      end
    end
    object tsReceipt: TTabSheet
      Caption = #1063#1077#1082#1080
      ImageIndex = 2
      DesignSize = (
        417
        309)
      object gbAfterProcess: TGroupBox
        Left = 8
        Top = 8
        Width = 401
        Height = 201
        Anchors = [akLeft, akTop, akRight]
        Caption = #1055#1086#1089#1083#1077' '#1086#1073#1088#1072#1073#1086#1090#1082#1080
        TabOrder = 0
        DesignSize = (
          401
          201)
        object lblFileNamePrefix: TLabel
          Left = 72
          Top = 152
          Width = 143
          Height = 13
          Caption = #1055#1088#1077#1092#1080#1082#1089' '#1076#1083#1103' '#1092#1072#1081#1083#1086#1074' '#1095#1077#1082#1086#1074':'
        end
        object edtProcessedReceiptPath: TEdit
          Left = 32
          Top = 96
          Width = 321
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 3
          Text = 'C:\Program Files\'#1064#1058#1056#1048#1061'-'#1052'\'#1055#1088#1080#1085#1090#1077#1088' '#1095#1077#1082#1086#1074'\Data\Receipts'
        end
        object rbRecMove: TRadioButton
          Left = 16
          Top = 72
          Width = 249
          Height = 17
          Caption = #1055#1077#1088#1077#1084#1077#1097#1072#1090#1100' '#1092#1072#1081#1083#1099' '#1074' '#1087#1072#1087#1082#1091':'
          TabOrder = 2
        end
        object btnProcessedReceiptPath: TButton
          Left = 360
          Top = 94
          Width = 24
          Height = 24
          Anchors = [akTop, akRight]
          Caption = '...'
          TabOrder = 4
          OnClick = btnProcessedReceiptPathClick
        end
        object rbRecSaveTime: TRadioButton
          Left = 16
          Top = 48
          Width = 233
          Height = 17
          Caption = #1047#1072#1087#1086#1084#1080#1085#1072#1090#1100' '#1076#1072#1090#1091' '#1087#1086#1089#1083#1077#1076#1085#1077#1075#1086' '#1092#1072#1081#1083#1072
          TabOrder = 1
        end
        object rbRecDelete: TRadioButton
          Left = 16
          Top = 24
          Width = 305
          Height = 17
          Caption = #1059#1076#1072#1083#1103#1090#1100' '#1092#1072#1081#1083#1099' '#1095#1077#1082#1086#1074
          TabOrder = 0
        end
        object chbChangeFileName: TCheckBox
          Left = 16
          Top = 128
          Width = 281
          Height = 17
          Caption = #1048#1079#1084#1077#1085#1080#1090#1100' '#1085#1072#1079#1074#1072#1085#1080#1077' '#1092#1072#1081#1083#1072' '#1080' '#1088#1072#1089#1096#1080#1088#1077#1085#1080#1077
          TabOrder = 5
        end
        object edtFileNamePrefix: TEdit
          Left = 224
          Top = 152
          Width = 129
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 6
          Text = 'RU0001'
        end
      end
      object cbAfterError: TGroupBox
        Left = 8
        Top = 216
        Width = 401
        Height = 81
        Anchors = [akLeft, akTop, akRight]
        Caption = #1055#1088#1080' '#1086#1096#1080#1073#1082#1077
        TabOrder = 1
        DesignSize = (
          401
          81)
        object btnErrorReceiptPath: TButton
          Left = 361
          Top = 46
          Width = 24
          Height = 24
          Anchors = [akTop, akRight]
          Caption = '...'
          TabOrder = 2
          OnClick = btnErrorReceiptPathClick
        end
        object edtErrorReceiptPath: TEdit
          Left = 32
          Top = 48
          Width = 321
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Text = 'C:\Program Files\'#1064#1058#1056#1048#1061'-'#1052'\'#1055#1088#1080#1085#1090#1077#1088' '#1095#1077#1082#1086#1074'\Data\Receipts'
        end
        object chbCopyErrorReceipts: TCheckBox
          Left = 16
          Top = 24
          Width = 281
          Height = 17
          Caption = #1050#1086#1087#1080#1088#1086#1074#1072#1090#1100' '#1095#1077#1082#1080' '#1089' '#1086#1096#1080#1073#1082#1072#1084#1080' '#1074' '#1087#1072#1087#1082#1091
          TabOrder = 0
        end
      end
    end
    object tsZReport: TTabSheet
      Caption = 'Z '#1086#1090#1095#1077#1090
      ImageIndex = 3
      DesignSize = (
        417
        309)
      object lblZReportFilePath: TLabel
        Left = 24
        Top = 248
        Width = 27
        Height = 13
        Caption = #1055#1091#1090#1100':'
      end
      object gbZReport: TGroupBox
        Left = 8
        Top = 40
        Width = 401
        Height = 161
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 1
        DesignSize = (
          401
          161)
        object btnProcessedReportPath: TButton
          Left = 369
          Top = 118
          Width = 24
          Height = 24
          Anchors = [akTop, akRight]
          Caption = '...'
          TabOrder = 0
          OnClick = btnProcessedReportPathClick
        end
        object edtProcessedReportPath: TEdit
          Left = 32
          Top = 120
          Width = 329
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 1
          Text = 'C:\Program Files\'#1064#1058#1056#1048#1061'-'#1052'\'#1055#1088#1080#1085#1090#1077#1088' '#1095#1077#1082#1086#1074'\Data\Receipts'
        end
        object rbRepMove: TRadioButton
          Left = 8
          Top = 96
          Width = 249
          Height = 17
          Caption = #1055#1077#1088#1077#1084#1077#1097#1072#1090#1100' '#1086#1073#1088#1072#1073#1086#1090#1072#1085#1085#1099#1077' '#1092#1072#1081#1083#1099' '#1074' '#1087#1072#1087#1082#1091':'
          TabOrder = 2
        end
        object rbRepSaveTime: TRadioButton
          Left = 8
          Top = 64
          Width = 289
          Height = 17
          Caption = #1047#1072#1087#1086#1084#1080#1085#1072#1090#1100' '#1076#1072#1090#1091' '#1087#1086#1089#1083#1077#1076#1085#1077#1075#1086' '#1086#1073#1088#1072#1073#1086#1090#1072#1085#1085#1086#1075#1086' '#1092#1072#1081#1083#1072
          TabOrder = 3
        end
        object rbRepDelete: TRadioButton
          Left = 8
          Top = 32
          Width = 305
          Height = 17
          Caption = #1059#1076#1072#1083#1103#1090#1100' '#1086#1073#1088#1072#1073#1086#1090#1072#1085#1085#1099#1077' '#1092#1072#1081#1083#1099
          TabOrder = 4
        end
      end
      object chbZReportEnabled: TCheckBox
        Left = 8
        Top = 16
        Width = 185
        Height = 17
        Caption = #1056#1072#1079#1088#1077#1096#1080#1090#1100' '#1089#1085#1103#1090#1080#1077' Z-'#1086#1090#1095#1077#1090#1086#1074
        TabOrder = 0
      end
      object chbSaveZReportEnabled: TCheckBox
        Left = 8
        Top = 216
        Width = 385
        Height = 17
        Caption = #1057#1086#1093#1088#1072#1085#1103#1090#1100' '#1076#1072#1085#1085#1099#1077' Z '#1086#1090#1095#1077#1090#1072' '#1074' '#1092#1072#1081#1083
        TabOrder = 2
      end
      object edtZReportFilePath: TEdit
        Left = 64
        Top = 248
        Width = 313
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 3
        Text = 'C:\Program Files\'#1064#1058#1056#1048#1061'-'#1052'\'#1055#1088#1080#1085#1090#1077#1088' '#1095#1077#1082#1086#1074'\Data\ZReports'
      end
      object btnZReportFilePath: TButton
        Left = 385
        Top = 246
        Width = 24
        Height = 24
        Anchors = [akTop, akRight]
        Caption = '...'
        TabOrder = 4
        OnClick = btnZReportFilePathClick
      end
    end
    object tsLogFile: TTabSheet
      Caption = #1051#1086#1075' '#1092#1072#1081#1083
      ImageIndex = 4
      DesignSize = (
        417
        309)
      object chbLogEnabled: TCheckBox
        Left = 8
        Top = 16
        Width = 161
        Height = 17
        Caption = #1042#1077#1089#1090#1080' '#1083#1086#1075
        TabOrder = 0
      end
      object gsLog: TGroupBox
        Left = 8
        Top = 40
        Width = 401
        Height = 257
        Anchors = [akLeft, akTop, akRight, akBottom]
        TabOrder = 1
        DesignSize = (
          401
          257)
        object lblLogPath: TLabel
          Left = 16
          Top = 40
          Width = 61
          Height = 13
          Caption = #1055#1072#1087#1082#1072' '#1083#1086#1075#1072':'
        end
        object edtLogPath: TEdit
          Left = 88
          Top = 40
          Width = 305
          Height = 21
          Anchors = [akLeft, akTop, akRight]
          TabOrder = 0
          Text = 'C:\Program Files\'#1064#1090#1088#1080#1093'-'#1052'\'#1044#1088#1072#1081#1074#1077#1088' '#1060#1056' A4\'
        end
      end
    end
    object tsPayTypes: TTabSheet
      Caption = #1058#1080#1087#1099' '#1086#1087#1083#1072#1090
      ImageIndex = 5
      DesignSize = (
        417
        309)
      object lblCashReceipts: TLabel
        Left = 8
        Top = 8
        Width = 184
        Height = 13
        Caption = #1053#1072#1079#1074#1072#1085#1080#1103' '#1090#1080#1087#1086#1074' '#1086#1087#1083#1072#1090' '#1074' '#1092#1072#1081#1083#1077' '#1095#1077#1082#1072
      end
      object lblCashPay: TLabel
        Left = 8
        Top = 24
        Width = 54
        Height = 13
        Caption = #1053#1072#1083#1080#1095#1085#1099#1077':'
      end
      object lblCashlessPay: TLabel
        Left = 8
        Top = 120
        Width = 71
        Height = 13
        Caption = #1041#1077#1079#1085#1072#1083#1080#1095#1085#1099#1077':'
      end
      object lblNonfiscal: TLabel
        Left = 8
        Top = 216
        Width = 81
        Height = 13
        Caption = #1053#1077#1092#1080#1089#1082#1072#1083#1100#1085#1099#1077':'
      end
      object mmCashPay: TMemo
        Left = 8
        Top = 40
        Width = 393
        Height = 73
        Anchors = [akLeft, akTop, akRight]
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object mmCashlessPay: TMemo
        Left = 8
        Top = 136
        Width = 393
        Height = 73
        Anchors = [akLeft, akTop, akRight]
        ScrollBars = ssVertical
        TabOrder = 1
      end
      object mmNonfiscalPay: TMemo
        Left = 8
        Top = 232
        Width = 393
        Height = 65
        Anchors = [akLeft, akTop, akRight, akBottom]
        ScrollBars = ssVertical
        TabOrder = 2
      end
    end
  end
  object OpenDialog: TOpenDialog
    Filter = #1060#1072#1081#1083#1099' '#1083#1086#1075#1072' (*.log)|*.log|'#1042#1089#1077' '#1092#1072#1081#1083#1099' (*.*)|*.*'
    Left = 368
    Top = 8
  end
end
