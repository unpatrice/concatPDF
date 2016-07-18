object Form1: TForm1
  Left = 192
  Top = 140
  Width = 606
  Height = 132
  Caption = 'Concatenation de fichier PDF'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 344
    Top = 24
    Width = 101
    Height = 13
    Caption = 'fichiers concat'#233'n'#233's : '
    Visible = False
  end
  object fichiersConcat_LB: TLabel
    Left = 456
    Top = 24
    Width = 41
    Height = 13
    Caption = '000/000'
    Visible = False
  end
  object Button1: TButton
    Left = 16
    Top = 56
    Width = 75
    Height = 25
    Caption = 'Button1'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Concatenate_Btn: TButton
    Left = 248
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Concat'#233'ner'
    TabOrder = 1
    OnClick = Concatenate_BtnClick
  end
  object PDFConcatenationList_Edt: TLabeledEdit
    Left = 16
    Top = 24
    Width = 201
    Height = 21
    EditLabel.Width = 168
    EditLabel.Height = 13
    EditLabel.Caption = 'Liste des fichiers PDF '#224' concat'#233'ner'
    LabelPosition = lpAbove
    LabelSpacing = 3
    TabOrder = 2
    Text = 'C:\buisine\DELPHI6\Projects\concatPDF\listePDF.txt'
  end
  object displayResult_CB: TCheckBox
    Left = 120
    Top = 56
    Width = 129
    Height = 17
    Caption = 'displayResult_CB'
    TabOrder = 3
  end
end
