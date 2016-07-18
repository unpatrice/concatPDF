unit myShellAPI;

interface

uses Windows,ShellApi,Classes,SysUtils;
function FindFiles (folderName,mask:string;aSL:TSTRINGList):integer;
function RecycleBinDelete(strFileName: string): boolean;
function DirectoryCopy(sFrom, sTo: string; Protect: boolean;Silent:boolean): boolean;
procedure MakeDir(Dir: String); // recursive enable
procedure ExecNewProcess(ProgramName: string);

implementation
procedure ExecNewProcess(ProgramName: string);
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CreateOK: Boolean;
begin
  { fill with known state }
  FillChar(StartInfo, SizeOf(TStartupInfo), #0);
  FillChar(ProcInfo, SizeOf(TProcessInformation), #0);
  StartInfo.cb := SizeOf(TStartupInfo);
  StartInfo.dwFlags:=STARTF_USESHOWWINDOW;
  StartInfo.wShowWindow:=SW_HIDE;
  CreateOK := CreateProcess(nil, PChar(ProgramName), nil, nil, False,
    CREATE_NEW_PROCESS_GROUP + NORMAL_PRIORITY_CLASS,
    nil, nil, StartInfo, ProcInfo);

  { check to see if successful }
  if CreateOK then
    //may or may not be needed. Usually wait for child processes
    WaitForSingleObject(ProcInfo.hProcess, 15000); //INFINITE
end;

function FindFiles (folderName,mask:string;aSL:TSTRINGList):integer;
var
  sr: TSearchRec;
  i, FileAttrs: Integer;
  SL: TStringList;

begin
  FileAttrs := 0;
  FileAttrs := FileAttrs + faAnyFile;
  i:=0;
  if FindFirst(foldername + '\' + mask, FileAttrs, sr) = 0 then
  begin
    repeat
      if (sr.Name<>'.') and (sr.Name<>'..') then
      begin
        inc(i);
        aSL.Add(foldername + '\' + sr.Name);
      end;
    until FindNext(sr) <> 0;
    FindClose(sr);
  end;
  result:=i;
end;

function RecycleBinDelete(strFileName: string): boolean;
var
  recFileOpStruct: TSHFileOpStruct;
begin
  // clear the structure
  FillChar(recFileOpStruct, SizeOf(TSHFileOpStruct), 0);

  with recFileOpStruct do begin
    wFunc := FO_DELETE;
    pFrom := PChar(strFileName);
    fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_SILENT;
  end;

  // set the return with sucess of the operation
  result := (0 = ShFileOperation(recFileOpStruct));
end;

function DirectoryCopy(sFrom, sTo: string; Protect: boolean;Silent:boolean): boolean;
{ Copies files or directory to another directory. }
var
  F: TShFileOpStruct;
  ResultVal: integer;
  tmp1, tmp2: string;
begin
  FillChar(F, SizeOf(F), #0);
  try
    F.Wnd := 0;
    F.wFunc := FO_COPY;
{ Add an extra null char }
    tmp1 := sFrom + #0;
    tmp2 := sTo + #0;
    F.pFrom := PChar(tmp1);
    F.pTo := PChar(tmp2);

    if Protect then
      F.fFlags := FOF_RENAMEONCOLLISION or FOF_SIMPLEPROGRESS
    else
      if Silent then
       begin
         F.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
       end
       else F.fFlags := FOF_SIMPLEPROGRESS;

    F.fAnyOperationsAborted := False;
    F.hNameMappings := nil;
    Resultval := ShFileOperation(F);
    Result := (ResultVal = 0) and (F.fAnyOperationsAborted=false);
  finally

  end;
end;

procedure MakeDir(Dir: String);
  function Last(What: String; Where: String): Integer;
  var
    Ind : Integer;

  begin
    Result := 0;

    for Ind := (Length(Where)-Length(What)+1) downto 1 do
        if Copy(Where, Ind, Length(What)) = What then begin
           Result := Ind;
           Break;
        end;
  end;

var
  PrevDir : String;
  Ind     : Integer;

begin
  {
  if Copy(Dir,2,1) <> ':' then
     if Copy(Dir,3,1) <> '\' then
        if Copy(Dir,1,1) = '\' then
           Dir := 'C:'+Dir
        else
           Dir := 'C:\'+Dir
     else
        Dir := 'C:'+Dir;
  }
  if not DirectoryExists(Dir) then begin
     // if directory don't exist, get name of the previous directory

     Ind     := Last('\', Dir);         //  Position of the last '\'
     PrevDir := Copy(Dir, 1, Ind-1);    //  Previous directory

     // if previous directoy don't exist,
     // it's passed to this procedure - this is recursively...
     if not DirectoryExists(PrevDir) then
        MakeDir(PrevDir);

     // In thats point, the previous directory must be exist.
     // So, the actual directory (in "Dir" variable) will be created.
     CreateDir(Dir);
  end;
end;


end.

