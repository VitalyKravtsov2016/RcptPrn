object fmMain: TfmMain
  Left = 459
  Top = 297
  AutoScroll = False
  Caption = 'fmMain'
  ClientHeight = 68
  ClientWidth = 322
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object TrayIcon1: TJvTrayIcon
    Active = True
    Icon.Data = {
      0000010001001010100000000000280100001600000028000000100000002000
      00000100040000000000C0000000000000000000000000000000000000000000
      000000008000008000000080800080000000800080008080000080808000C0C0
      C0000000FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF000000
      0000000000000000008770000000000088700770000000887787700770000777
      88877770070077888887777770007F8888F7777777707F88FF88877777707FFF
      8899888777707F88AA8887708770077F88877FF0800000077F7FFFFF00000000
      077FFFFFF00000000007FFFFFF00000000007FFF77000000000007770000FC7F
      0000F01F0000C007000080010000800100000001000000000000000000000000
      00000000000080010000E0070000F8030000FE000000FF030000FF8F0000}
    IconIndex = 0
    PopupMenu = pmTrayMenu
    OnClick = TrayIcon1Click
    OnDblClick = TrayIcon1Click
    Left = 8
    Top = 16
  end
  object pmTrayMenu: TPopupMenu
    Left = 40
    Top = 16
    object pmiShowHide: TMenuItem
      Caption = #1043#1083#1072#1074#1085#1086#1077' '#1086#1082#1085#1086
      OnClick = pmiShowHideClick
    end
    object pmiAbout: TMenuItem
      Bitmap.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000000000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00DDDDDDDDDDDD
        DDDDDDDDDD77777DDDDDDDDDD0000077DDDDDDDD0CCCCC077DDDDDD0CCFFFCC0
        77DDDD0CCCFFFCCC07DDDD0CCCFFFCCC077DD0CCCCFFFCCCC07DD0CCCCFFFCCC
        C07DD0CCCCFFFCCCC0DDDD0CCCCCCCCC07DDDD0CCCFFFCCC0DDDDDD0CCFFFCC0
        DDDDDDDD0CCCCC0DDDDDDDDDD00000DDDDDDDDDDDDDDDDDDDDDD}
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      ImageIndex = 3
      OnClick = pmiAboutClick
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object btnPrintXReport: TMenuItem
      Caption = #1056#1072#1089#1087#1077#1095#1072#1090#1072#1090#1100' X '#1086#1090#1095#1077#1090
      OnClick = btnPrintXReportClick
    end
    object btnPrintZReport: TMenuItem
      Caption = #1056#1072#1089#1087#1077#1095#1072#1090#1072#1090#1100' Z '#1086#1090#1095#1077#1090
      OnClick = btnPrintZReportClick
    end
    object miDivider2: TMenuItem
      Caption = '-'
    end
    object pmiTrayExit: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = pmiTrayExitClick
    end
  end
end