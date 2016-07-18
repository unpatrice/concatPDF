unit concatPDF_code;

interface

uses
  idglobal, Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, math, ExtCtrls,tlogmanager,shellAPI,myshellapi,strutils;
const
  bufSize = 40000000;
const
  chaineRech = ' 0 obj'#0; //'Pages /Count'#0;
  chaineRech2 = 'endobj'#0;
  chaineRech4 = 'endobj'#10;
  chaineRech3 = ' 0 R'#0;
  headerBin = '%PDF-1.4'#10'1 0 obj'#10'<< /Type /Catalog'#10'/Outlines 2 0 R'#10'/Pages 3 0 R'#10'>>'#10'endobj'#10'2 0 obj'#10'<< /Count 0'#10'/Type /Outlines'#10'>>'#10'endobj'#10#0;
  footerBin = #10'trailer << /Root 1 0 R >>'#13#10'%%EOF'#0;
  pagesRech = '/Pages ';

//Declare the message body name
const sx_CustomMsg= 'oneConcatPdfDone';

type
  TForm1 = class(TForm)
    Button1: TButton;
    Concatenate_Btn: TButton;
    PDFConcatenationList_Edt: TLabeledEdit;
    Label1: TLabel;
    fichiersConcat_LB: TLabel;
    displayResult_CB: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Concatenate_BtnClick(Sender: TObject);
  private
    { Private declarations }
    curMSStream: TMemoryStream;
    curFSStream: TFileStream;
    nbObj: integer;
    pagesList: TStringList;
    theLog: TLOG;
    doublePagesObject:boolean;
    kidsArray:string;
    function ajoutePdfObj(aMS: Tmemorystream): integer;
    function isPageObj(aMS: TMemoryStream): boolean;
    procedure addPagesObj;
    function removePDFProtection(aPDFFilepath: string): boolean;
    function isPDFProtected(aPDFFilepath: string): boolean;
  public
    { Public declarations }
    outputPdfFilepath: string;
    function concatWith(aPDF: string): boolean;
    function logIt(s: string): string;
 
  end;

var
  Form1: TForm1;
  WProc: Pointer; //This is needed for correct handling of other messages
  sxCustomMsg: cardinal; //This is the actual handle of the message

implementation

{$R *.dfm}
function TForm1.logIt(s: string): string;
begin
  result := theLog.LogIt(s);
end;

procedure ReverseBytes(Source, Dest: Pointer; Size: Integer);
var
  Index: Integer;
begin
  for Index := 0 to Size - 1 do
    Move(Pointer(LongInt(Source) + Index)^, 
        Pointer(LongInt(Dest) + (Size - Index - 1))^ , 1);
end;

function getKidsOfKids (kidsList:string;pBuf:PChar;count:integer):string;
var
    i,j,pagesIdx:integer;
    trouve:Boolean;
    catalogNumber:integer;
    s,s1:string;
    destBuf:Pchar;
    onePagesObjNum:integer;
begin
    Result:='';
    s1:=kidsList;
      Fetch(s1,'#');
    while length(s1)>0 do
    begin

      onePagesObjNum:=strtoint(Fetch(s1,'#'));
      // recup de l obj
      s:=inttostr(onePagesObjNum)+' 0 obj';
      i:=count;
      while ((StrlComp(@pBuf[i],pchar(s) , length(s)) <> 0)
      or ((pBuf[i-1]<>#13) and (pBuf[i-1]<>#10) and (pBuf[i-1]<>#20)) ) and (i>0) do dec(i);
      if i>0 then
        begin
          j:=i;
          while (StrlComp(@pBuf[j],'endobj', 6) <> 0) and (j<count) do inc(j);
          if j<count then
            begin
              GetMem(destBuf,j-i+1);
              StrLCopy(destBuf,@pBuf[i+6],j-i);
              s:=trim(destBuf);
              FreeMem(destBuf);

              fetch(s,'/Kids');
              if length(s)>0 then
                begin
                  s:=fetch(s,']');
                  fetch(s,'[');
                  s:=trim(s);
                  s:=AnsiReplaceStr(s,' 0 R','#');
                  s:='#'+AnsiReplaceStr(s,#13#10,'')+'#';
                  s:=AnsiReplaceStr(s,'##','#');
                  s:=AnsiReplaceStr(s,' ','');

                  Result:=Result+s;
                end;
            end;
        end;
    end; // fin while
    Result:=AnsiReplaceStr(Result,'##','#');
    if length(Result)=0 then Result:=kidsList;
end;

function getKids (pBuf:PChar;count:integer):string;
var
    i,j,pagesIdx:integer;
    trouve:Boolean;
    catalogNumber:integer;
    s,s1:string;
    destBuf:Pchar;
begin
    Result:='';

    // premiere recherche
    i:=count;
    while (StrlComp(@pBuf[i], '/Root ', length('/Root ')) <> 0) and (i>0) do dec(i);
    if i>0 then
      begin
        j:=i; // root obj
        GetMem(destBuf,1000);
        StrLCopy(destBuf,@pBuf[i+6],5);
        s:=trim(destBuf);
        FreeMem(destBuf);
        j:=strtointdef(fetch(s,' '),0); // root obj number
        if j>0 then
          begin
            s:=inttostr(j)+' 0 obj';
            while (StrlComp(@pBuf[i],pchar(s) , length(s)) <> 0) and (i>0) do dec(i);
            if i>0 then
              begin
                j:=i;
                while (StrlComp(@pBuf[j],'endobj', 6) <> 0) and (j<count) do inc(j);
                if j<count then
                  begin
                    GetMem(destBuf,j-i+1);
                    StrLCopy(destBuf,@pBuf[i+6],j-i);
                    s:=trim(destBuf);
                    FreeMem(destBuf);
                    fetch(s,'/Pages');
                    fetch(s,' ');
                    j:=strtointdef(fetch(s,' '),0); // pages number
                    if j>0 then
                      begin
                        s:=inttostr(j)+' 0 obj';
                        while (StrlComp(@pBuf[i],pchar(s) , length(s)) <> 0) and (i>0) do dec(i);
                        if i>0 then
                          begin

                            j:=i;
                            while (StrlComp(@pBuf[j],'endobj', 6) <> 0) and (j<count) do inc(j);
                            if j<count then
                              begin
                                GetMem(destBuf,j-i+1);
                                StrLCopy(destBuf,@pBuf[i+6],j-i);
                                s:=trim(destBuf);
                                FreeMem(destBuf);
                                fetch(s,'/Kids');
                                if length(s)>0 then
                                  begin
                                    s:=fetch(s,']');

                                    fetch(s,'[');
                                    s:=trim(s);
                                    s:=AnsiReplaceStr(s,' 0 R','#');
                                    s:='#'+AnsiReplaceStr(s,#13#10,'')+'#';
                                    s:=AnsiReplaceStr(s,'##','#');
                                    s:=AnsiReplaceStr(s,' ','');
                                    // detect kids of kids
                                    Result:=s;
                                    Result:=getKidsOfKids(Result,pBuf,count);

                                    trouve := true;
                                    exit;
                                  end  else i:=0;
                              end else i:=0;
                          end;


                      end else i:=0;

                  end else i:=0;
              end;
          end else i:=0;

      end;

    // seconde recherche
    //i := 0;
    trouve := false;
    while (i < count) and not trouve do
    begin
      if (length(Result)>0) and (i>=173936) then DebugBreak;

      if (pBuf[i] = pagesRech[1]) and (StrlComp(@pBuf[i], pagesRech, length(pagesRech) - 1) = 0) then
        trouve := true;
      if not trouve then inc(i)
      else
      begin
        pagesIdx:=i;

        // recherche debut <<
        while (i > 0) and not (StrlComp(@pBuf[i], '<<', 2) = 0) do dec(i);
        j:=i;
        while (j < count) and not (StrlComp(@pBuf[j], '>>', 2) = 0) do inc(j);

        // on est en présence de << xxx /Kids [] /Pages xxx >>
        GetMem(destBuf,1000);
        StrLCopy(destBuf,@pBuf[i],j-i);
        s:=trim(destBuf);
        FreeMem(destBuf);
        if pos('/Kids',s)>0 then
          begin
            fetch(s,'/Kids');
            s:=fetch(s,']');
            fetch(s,'[');
            s:=trim(s);
            s:=AnsiReplaceStr(s,' 0 R','#');
            s:='#'+AnsiReplaceStr(s,#13#10,'')+'#';
            s:=AnsiReplaceStr(s,'##','#');
            Result:=s;
            exit;
          end
        else
         begin
          // on est en présence de << /Type /Catalog /Pages 2 0 R /Metadata 6 0 R >>
          i:=pagesIdx;

          while not IsNumeric(pBuf[i]) do inc(i);
          j := i;
          while IsNumeric(pBuf[j]) do inc(j);
          s:=copy(pBuf,i+1,j-i);
          catalogNumber:=StrToIntDef(s,0);  // page tree number
          if catalogNumber=0 then
            begin
             s:=copy(pBuf,i,j-i-1);
             catalogNumber:=StrToIntDef(s,0);
            end;
          j:=i;
          trouve:=false;
          i:=0;
          // recherche du contenu du page tree object
          while (i<count) and not trouve do
          begin
            if (StrlComp(@pBuf[i], pchar(#10+s+' 0 obj'), length(#10+s+' 0 obj') ) = 0) then trouve:=true;
            DebugOutput(inttostr(i));
            if not trouve then inc(i)
            else
            begin
              trouve:=false;
              while (i<count) and not trouve do
                begin
                  if (StrlComp(@pBuf[i], pchar('/Kids'), length('/Kids') ) = 0) then trouve:=true;
                  DebugOutput(inttostr(i));
                  if not trouve then inc(i)
                  else
                  begin
                    trouve:=false;
                    while not IsNumeric(pBuf[i]) do inc(i);
                    j := i;
                    while (pBuf[j]<>']') and (pBuf[j]<>'>') and (pBuf[j]<>'/') do inc(j);
                    trouve:=true;
                    GetMem(destBuf,1000);
                    StrLCopy(destBuf,@pBuf[i],j-i);
                    s:=trim(destBuf);
                    s:=AnsiReplaceStr(s,' 0 R','#');
                    s:='#'+AnsiReplaceStr(s,#13#10,'')+'#';
                    s:=AnsiReplaceStr(s,'##','#');
                    FreeMem(destBuf);
                    Result:=s;
                  end;
               end;

            end;
          end;
        end;

      end;
    end;

end;

function TForm1.concatWith(aPDF: string): boolean;

var
  sStream: TFileStream;
  aMS: TMemoryStream;
  pBuf, p: PChar;
  i, j: integer;
  cnt: Integer;
  trouve, trouveCount, trouveFin: boolean;
  s: string;
  maxObj: integer;
  nbPages:integer;

begin
  doublePagesObject:=false;
  nbPages:=0;
  logIt('concatWith('+aPDF+')');
  sStream := TFileStream.Create(aPDF, fmOpenRead or fmShareDenyWrite);
  GetMem(pBuf, sStream.size); // bufSize);
  cnt := sStream.Read(pBuf^, sstream.size); //bufSize);
  if (StrlComp(@pBuf[0], '%PDF', 4) = 0) then
  begin
    i := 0;
    trouve := false;
    maxObj := 0;
    kidsArray:= getKids(pBuf,cnt);
    while (i < cnt) and not trouve do
    begin
      if (pBuf[i] = chaineRech[1]) and (StrlComp(@pBuf[i], chaineRech, length(chaineRech) - 1) = 0) then
        trouve := true;
      if not trouve then inc(i)
      else
      begin
        j := i;
        dec(i);
        while IsNumeric(pBuf[i]) do dec(i);
        inc(i);
         //s:=(copy(pBuf,i+1,j-i));
         //DebugOutput('object #'+s+':'+inttostr(i)+' '+inttostr(j-i));
        j := i;
        trouveFin := false;
        while (j < cnt) and not trouveFin do
        begin
          if (pBuf[j] = chaineRech2[1]) and (StrlComp(@pBuf[j], chaineRech2, length(chaineRech2) - 1) = 0) then
            trouveFin := true;
          if not trouve and (pBuf[j] = chaineRech4[1]) and (StrlComp(@pBuf[j], chaineRech4, length(chaineRech4) - 1) = 0) then
            trouveFin := true;
          if not trouveFin then inc(j)
          else
          begin
            j := j + length(chaineRech2);
            aMS := TMemoryStream.Create;
            sStream.Seek(i, soFromBeginning);
            aMS.CopyFrom(sStream, j - i);
                 //ShowMessage(inttostr(aMS.size));
            maxObj := max(maxObj, ajoutePdfObj(aMS));
            aMS.Free;
            i := j;
          end;
        end;
        trouve := false;
      end;
    end;
  //curFSStream.CopyFrom(sStream,0);
  end else maxObj:=nbObj;
  FreeMem(pBuf);
  sStream.Free;
  result := true;
  nbObj := maxObj;
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
  theLog := TLOG.Create;
  if not DirectoryExists(ExtractFilePath(Application.ExeName) + 'log') then
    CreateDir(ExtractFilePath(Application.ExeName) + 'log');
  theLog.CreateLog(ExtractfilePath(Application.ExeName));
  theLog.LogIt('Démarrage de l''application');
  pagesList := TStringList.Create;
  curMSStream := TMemoryStream.Create;
  outputPdfFilepath := ExtractFilePath(Application.ExeName) + 'output.pdf';
  sxCustomMsg:= RegisterWindowMessage(sx_CustomMsg);
end;

procedure TForm1.Button1Click(Sender: TObject);

begin
  nbObj := 3;
  //curFSStream:= TFileStream.Create(ExtractFilePath(Application.ExeName)+'header.bin', fmOpenRead);
  //curMSStream.CopyFrom(curFSStream,0);
  //curFSStream.free;
  curMSStream.WriteBuffer(headerBin, length(headerBin));
  curFSStream := TFileStream.Create(outputPdfFilepath, fmCreate);
  concatWith('C:\BUISINE\DELPHI6\Projects\concatPDF\CPI_BK-002-RH_10025859495.pdf');
  concatWith('C:\BUISINE\DELPHI6\Projects\concatPDF\164240497.pdf');
  concatWith('c:\test\immatabs.pdf');
//  concatWith('C:\BUISINE\DELPHI6\Projects\concatPDF\164240497.pdf');

  //concatWith('C:\BUISINE\DELPHI6\Projects\concatPDF\test.pdf.p1');
  addPagesObj;
  curFSStream.CopyFrom(curMSStream, 0);
  curMSStream.LoadFromFile(ExtractFilePath(Application.ExeName) + 'footer.bin');
  curFSStream.CopyFrom(curMSStream, 0);
  curFSStream.Free;
end;

function TForm1.ajoutePdfObj(aMS: TMemorystream): integer;
var
  newMS: TMemoryStream;
  newFS: TFileStream;
  s: string;
  pBuf, p: PChar;
  i, j: integer;
  cnt: Integer;
  trouve, trouveCount, trouveFin: boolean;
  numObj: integer;
  reprisePtr: integer;
  maxObj: integer;
  deb, fin: integer;
  firstObj: integer;
  isObjAPage: boolean;
  paramParent: boolean;
begin
  newMS := TMemoryStream.Create;
  GetMem(pBuf, aMS.size); // bufSize);
  isObjAPage := isPageObj(aMS);
  aMS.Seek(0, soFromBeginning);
  cnt := aMS.Read(pBuf^, aMS.size); //bufSize);
  cnt := aMS.size;
  i := 0;
  firstObj := 0;
  trouve := false;
  reprisePtr := 0;
  maxObj := 0;
  while (i < cnt) and not trouve do
  begin
    if (pBuf[i] = chaineRech[1]) and (StrlComp(@pBuf[i], chaineRech, length(chaineRech) - 1) = 0) and (cnt-i>length(chaineRech)-1) then
      trouve := true;
    if (pBuf[i] = chaineRech3[1]) and (StrlComp(@pBuf[i], chaineRech3, length(chaineRech3) - 1) = 0) and (cnt-i>length(chaineRech)-1) then
      trouve := true;
    if not trouve then inc(i)
    else
    begin

      deb := i;
      dec(deb);
      s := '';
      while IsNumeric(pBuf[deb]) do
      begin
        s := pBuf[deb] + s;
        dec(deb);
      end;
      if reprisePtr > 0 then
      begin
        aMS.Seek(reprisePtr, soFromBeginning);
        newMS.CopyFrom(aMS, deb - reprisePtr + 1);
      end;
      reprisePtr := i;
      paramParent := false;
//      if isObjAPage and (i > 10) and (StrlComp(@pBuf[i - 9], '/Parent', length('/Parent') - 1) = 0) then
//        paramParent := true;
      if isObjAPage and (i > 10) and (StrlComp(@pBuf[deb - 7], '/Parent', length('/Parent') - 1) = 0) then
        paramParent := true;
      inc(deb);
      numObj := strtoint(s);
      if paramParent then logIt('obj #'+s+' declared as paramParent => #3');
      if maxObj = 0 then
        begin
          logIt('firstObj #'+s+' -> '+inttostr(numObj + nbObj));
          firstObj := numObj + nbObj;
        end;
      maxObj := max(maxObj, numObj + nbObj);
      if paramParent then s := '3' else
        begin
          logIt('obj #'+s+' -> '+inttostr(numObj + nbObj));
          s := inttostr(numObj + nbObj);
        end;
      newMS.Write(s[1], length(s));
      inc(i);
      trouve := false;
    end;
  end;
  if reprisePtr > 0 then
  begin
    aMS.Seek(reprisePtr, soFromBeginning);
    newMS.CopyFrom(aMS, i - reprisePtr);
  end;
  //newFS:=TFileStream.Create(outputPdfFilepath+'.p1',fmcreate);
  //newFS.CopyFrom(newMS,0);
  //newFS.Free;
  curMSStream.CopyFrom(newMS, 0);
  if isPageObj(newMS) then
    begin
      if (pos('#'+inttostr(firstObj-nbObj)+'#',kidsArray)>0) then
        begin
          logIt('ajout au catalog de la page '+inttostr(firstObj-nbObj));
          pagesList.Add(format('%d 0 R', [firstObj]));
        end
        else
        begin
          logIt('non-ajout au catalog de la page '+inttostr(firstObj-nbObj));
        end;
     end;
  newMS.Free;
  result := maxObj;
  FreeMem(pBuf);
//  ShowMessage(inttostr(aMS.Size));
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  pagesList.Free;
  curMSStream.Free;
  logIt('Fin de l''application concatPDF');
  theLog.free;  
end;

function TForm1.isPageObj(aMS: TMemoryStream): boolean;
const
  chaineType = '/Type'#0;
var
  trouve: boolean;
  s: string;
  pBuf, p: PChar;
  i, j: integer;
  cnt: Integer;
  chainePage, chainePages: string;
begin
  chainePage := '/Page';
  chainePages := '/Pages';
  GetMem(pBuf, aMS.size); // bufSize);
  aMS.Seek(0, soFromBeginning);
  cnt := aMS.Read(pBuf^, aMS.size); //bufSize);
  cnt := aMS.size;
  with aMS do
  begin
    Seek(0, soFromBeginning);
    i := 0;
    trouve := false;
    while (i < cnt) and not trouve do
    begin
      if (pBuf[i] = chaineType[1]) and (StrlComp(@pBuf[i], chaineType, length(chaineType) - 1) = 0) then
        trouve := true;
      if trouve then
      begin
        j := i + length(chaineType) - 1;
        s := copy(pBuf + j, 1, 50);
        if (pos(chainePage, s) > 0) and (pos(chainePages, s) = 0) then
          result := true else trouve := false;
      end;
      if not trouve then inc(i);
    end;
  end;
  FreeMem(pBuf);
end;

procedure TForm1.addPagesObj;
var
  i: integer;
  aSS: TStringStream;
  s: string;
begin
  s := '3 0 obj'#13#10'<< /Count ';
  s := s + inttostr(pagesList.Count) + #13#10 + '/Kids [';
  s := s + pagesList.GetText;
  s := s + ']'#13#10 + '/Type /Pages'#13#10'>>'#13#10'endobj'#13#10;
  aSS := TStringStream.create(s);
  curMSStream.CopyFrom(aSS, 0);
  aSS.free;
end;

procedure TForm1.Concatenate_BtnClick(Sender: TObject);
var
  aSL: TStringList;
  i: integer;
begin
  Concatenate_Btn.Enabled := false;
  nbObj := 3;
  curMSStream.WriteBuffer(headerBin, length(headerBin) - 1);
//  curFSStream:= TFileStream.Create(ExtractFilePath(Application.ExeName)+'header.bin', fmOpenRead);
//  curMSStream.CopyFrom(curFSStream,0);
//  curFSStream.free;
  curFSStream := TFileStream.Create(outputPdfFilepath, fmCreate);
  aSL := TStringList.Create;
  with aSL do
  begin
    LoadFromFile(PDFConcatenationList_Edt.Text);
    if Count > 0 then
    begin
      fichiersConcat_LB.Visible := true;
      Label1.Visible := true;
    end;
    for i := 0 to Count - 1 do
    begin
      if isPDFProtected(Strings[i]) then removePDFProtection(Strings[i]);
      concatWith(Strings[i]);
      curFSStream.CopyFrom(curMSStream, 0);
      curMSStream.Size:=0;
      FlushFileBuffers(curFSStream.Handle);
      PostMessage(HWND_BROADCAST, sxCustomMsg, 0, 0);
      fichiersConcat_LB.Caption := logIt (format('%d/%d', [i + 1, count]));
      Application.ProcessMessages;
    end;
    free;
  end;
  addPagesObj;

  // footer
  curMSStream.WriteBuffer(footerBin, length(footerBin) - 1);

  curFSStream.CopyFrom(curMSStream, 0);

//  curMSStream.LoadFromFile(ExtractFilePath(Application.ExeName)+'footer.bin');
//  curFSStream.CopyFrom(curMSStream,0);
  curFSStream.Free;

  Concatenate_Btn.Enabled := true;
  if displayResult_CB.Checked then logIt('affichage du PDF');
  if displayResult_CB.Checked and FileExists(outputPdfFilepath)
    then ShellExecute(handle, 'open', pchar(outputPdfFilepath), nil, nil, SW_SHOWNORMAL);
end;

function TForm1.removePDFProtection(aPDFFilepath: string): boolean;
const
  gsExeFile='gs8.71\bin\gswin32.exe';
var
  myCmdLine:string;
  pdfProtecRemovedFilepath:string;
begin
  logIt('removePDFProtection('+aPDFFilepath+') en cours ...');
  result:=false;
  try
    if not FileExists(aPDFFilepath) then exit;
    pdfProtecRemovedFilepath:=ChangeFileExt(aPDFFilepath,'.unsecure.pdf');
    myCmdLine:=ExtractFilePath(Application.ExeName)+gsExeFile+' -safer -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile=';
    myCmdLine:=myCmdLine+pdfProtecRemovedFilepath+' '+aPDFFilepath;
    ExecNewProcess(logIt (myCmdLine));
    if not FileExists(pdfProtecRemovedFilepath) then begin
      ShowMessage('impossible de trouver :'+pdfProtecRemovedFilepath);
      exit;
      end;
    DeleteFile(aPDFFilepath);
    RenameFile(pdfProtecRemovedFilepath,aPDFFilepath);
    result:=true;
  except
    on e : Exception do logIt('exception levee : '+e.Message);
  end;
  logIt('removePDFProtection('+aPDFFilepath+') termine');
end;

function TForm1.isPDFProtected(aPDFFilepath: string): boolean;
var
  aSS:TStringStream;
  aFS:TFileStream;
begin
  result:=false;
  if not FileExists(aPDFFilepath) then logIt(aPDFFilepath+' inexistant!');
  aFS:=TFileStream.Create(aPDFFilepath,fmOpenRead and fmShareDenyNone);
  aSS:=TStringStream.create('');
  aSS.CopyFrom(aFS,0);
  aFS.Free;
  if pos ('/Encrypt',aSS.DataString)>0 then result:=true;
  if pos ('/Linearized',aSS.DataString)>0 then result:=true;

  aSS.Free;
end;
end.

