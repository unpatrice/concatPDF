Unit TLogManager;
     
Interface

Uses Classes, Dialogs, SysUtils;

Type
  TLog = Class
    Procedure CreateLog(LogDirPath: String);

  private
    { Private declarations }
    DATLOT: String;

    logFile: TextFile;
  public
    { Public declarations }
    logFileName: String;
  published
    Function LogIt(logStr: String): String;
    Function WarnIt(logStr: String): String;
  protected
  End;

Implementation

Function TLog.LogIt(logStr: String): String;
Var
  timestamp: String;
  fh: integer;
  toAbort, logExists: LongBool;
Begin
  // ouverture du log
  fh := 0;
  toAbort :=false;
  logExists :=false;
  If FileExists(logFileName) = false Then
    Begin
      fh := filecreate(logFileName);
      If fh < 0 Then
        Begin
          showmessage('impossible de créer le log ' + logfilename);
          logFileName := '';
          toabort := true;
        End;
    End
  Else
    logExists := true;
  If toabort = true Then exit;
  If fh > 0 Then FileClose(fh);
  AssignFile(logFile, logFileName);
  Append(logFile);

  // écriture dans le log
  timestamp := formatdatetime('YYYY/MM/DD hh:mm:ss', now);
  If (logstr <> '') Then
    writeln(logfile, timestamp + ' : ' + logstr)
  Else
    writeln(logfile, logstr);
  flush(logFile);

  //fermeture du log
  If logFileName <> '' Then CloseFile(logFile);

  result := logStr;
End;

Function TLog.WarnIt(logStr: String): string;
Begin
  showmessage(logStr);
  result:=LogIt(logstr);
End;

//

Procedure TLog.CreateLog(LogDirPath: String);
Begin
  DATLOT := FormatDateTime('yyyy-mm-dd', Now);
  //chdir(ExtractfilePath(Application.ExeName) + 'log');
  logFileName := LogDirPath + 'log\log_' + DATLOT + '.txt';

End;



End.

