program concatPDF;

uses
  Forms,
  concatPDF_code in 'concatPDF_code.pas' {Form1};

{$R *.res}
var
  i:Integer;
  batch:longbool=false;

// C:\BUISINE\DELPHI6\Projects\concatPDF\pdfList.txt C:\BUISINE\DELPHI6\Projects\concatPDF\output.pdf -display

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  batch:=false;
  if ParamCount>1 then
    begin
      batch:=true;
      with Form1 do
      begin
//        concatenerPDFPathList:=ParamStr(1);
        if (ParamCount>=3) and (ParamStr(3)='-display')
            then displayResult_CB.Checked:=true;

        PDFConcatenationList_Edt.Text:=ParamStr(1);
        outputPdfFilepath:=ParamStr(2);
        try
          Concatenate_BtnClick(nil);
        except
        end;

      end;

    end;
  if not batch then
    begin
      Form1.Visible:=true;
      Application.Run ;
    end
    else form1.Close;
  form1.Free;
end.
