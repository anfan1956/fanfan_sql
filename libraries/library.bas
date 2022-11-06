Attribute VB_Name = "library"
Option Explicit
Public Const VPNcommon = "10.0.0.30"

Function greeting() As String
    greeting = "Hello, world"
End Function
Function cbAdd(left As Integer, top As Integer, width As Integer, height, caption As String, actions As String) As Button
    
    'добавляет кнопку для исполнения макро
    Dim ws As Worksheet
    Set ws = ActiveSheet
    Set cbAdd = ws.Buttons.Add(left, top, width, height)
    With cbAdd
        .Characters.Text = caption
        .OnAction = actions
    End With
End Function

Function ws_insert(wsname As String) As Worksheet
    'Перевставляет листок и дает ему название
    With Application
        .ScreenUpdating = False
        .DisplayAlerts = False
            If worksheet_exist(wsname) Then Worksheets(wsname).Delete
            Set ws_insert = Worksheets.Add
            ws_insert.Name = wsname
        .DisplayAlerts = True
    End With
End Function

Function lo_from_array(ws As Worksheet, rn As Range, lo_array As Variant, Optional lo_name As String) As ListObject
    'создает таблицу/header на странице и дает ей название
    With rn
        .value = "Графа"
        .Offset(0, 1) = "Значение"
        .Offset(1).Resize(UBound(lo_array) + 1) = WorksheetFunction.Transpose(lo_array)
        Set lo_from_array = ws.ListObjects.Add(xlSrcRange, rn.CurrentRegion, , xlYes, , "tablestylemedium11")
        If lo_name <> "" Then lo_from_array.Name = lo_name
        lo_from_array.Range.Columns.AutoFit
    End With
End Function

Function vValid(sql As String, ff As Boolean, cap As String) As Variant

    Dim data As Variant
        Call newConnection(ff)
            Set rs = cn.Execute(sql)
                data = rs.GetRows
                data = WorksheetFunction.Transpose(data)
            With frmValidationNew
                .caption = "select " & cap
                .Label1.caption = cap
                With .ComboBox1
                    .Style = fmStyleDropDownList
                    .List = data
                    .SetFocus
                End With
                .Show
                If Not .cancelled Then
                    vValid = .ComboBox1.Text
                End If
            End With
        cn.Close
        Set cn = Nothing
End Function
Function sValid(sql As String, Optional cnn As ADODB.Connection, Optional fanfan As Boolean) As String

    'Создает строку для валидации
    Dim rs As ADODB.Recordset, vValidation
        If cnn Is Nothing Then
            Call newConnection(fanfan)
            Set cnn = cn
        End If
        Set rs = cnn.Execute(sql)
        If rs.EOF = False Then
            vValidation = rs.GetRows
            sValid = vValidation(0, 0)
            For i = 1 To UBound(vValidation, 2)
                sValid = sValid & ", " & vValidation(0, i)
            Next
        End If
End Function

Function vValid_string(sql As String, Optional fanfan_base As Boolean) As String
Dim rs As ADODB.Recordset, vValidation

    Call newConnection(fanfan_base)
    Set rs = cn.Execute(sql)
    If rs.EOF = False Then
        vValidation = rs.GetRows
        vValid_string = vValidation(0, 0)
        For i = 1 To UBound(vValidation, 2)
            vValid_string = vValid_string & ", " & vValidation(0, i)
        Next
    End If
End Function
Function CheckFileExists(full_filename As String) As Boolean

Dim strFileExists As String
    strFileExists = Dir(full_filename)

    If strFileExists <> "" Then
        CheckFileExists = True
    End If
 
End Function

Function worksheet_exist(wsname As String) As Boolean
'originally introduced in use.fan.inv

    Dim wb As Workbook, ws As Worksheet
    Set wb = ThisWorkbook
    For Each ws In wb.Worksheets
        If ws.Name = wsname Then
            worksheet_exist = True
            Exit For
        End If
    Next
End Function
Function pt_onthe_fly( _
            ws As Worksheet, rn As Range, rs As ADODB.Recordset, ptName As String, _
            row_fields As Variant, Optional datafield As String, Optional data_fields As Variant, _
            Optional page_fields As Variant) As PivotTable
'origin  - timesheets
            
    Dim pche As PivotCache, wb As Workbook, item
    Set wb = ActiveWorkbook
    Application.ScreenUpdating = False
    Set pche = wb.PivotCaches.Add(xlExternal)
    Set pche.Recordset = rs

    Set pt_onthe_fly = ws.PivotTables.Add(PivotCache:=pche, TableDestination:=rn, tablename:=ptName)
    With pt_onthe_fly
        wb.ShowPivotTableFieldList = False
        .RowAxisLayout xlTabularRow
        .InGridDropZones = True
        If datafield <> "" Then
            .AddDataField .PivotFields(datafield), " сумма", xlSum
            .PivotFields(" сумма").NumberFormat = "#,##.00; -[red]#,##.00;"
        End If
        If IsArray(data_fields) Then
            For Each item In data_fields
                With .PivotFields(item)
                        .Orientation = xlDataField
                        .NumberFormat = "#,##.00; -[red]#,##.00;"
                        .Function = xlSum
                        .caption = " " & item
                End With
            Next
        .DataPivotField.Orientation = xlColumnField
        End If

        If IsArray(row_fields) Then
            For Each item In row_fields
                With .PivotFields(item)
                    .Orientation = xlRowField
                    .Subtotals(1) = False
                End With
            Next
        Else
            With .PivotFields(row_fields)
                .Orientation = xlRowField
                .Subtotals(1) = False
            End With
        End If
        If Not IsMissing(page_fields) Then
            If IsArray(page_fields) Then
                For Each item In page_fields
                    With .PivotFields(item)
                            .Orientation = xlPageField
                        .Subtotals(1) = False
                    End With
                Next
            Else
                With .PivotFields(page_fields)
                    .Orientation = xlPageField
                End With
            End If
        End If
    End With

End Function

Function personid_authorized() As Integer
Dim sPass As String, person As String, sql As String, vData
Application.EnableEvents = False

sql = "select username from org.users  "

Call newConnection(True)
Set rs = cn.Execute(sql)
vData = WorksheetFunction.Transpose(rs.GetRows)

    With frmAttendance
        .Label1.caption = "пароль"
        .caption = "авторизация отчетного лица: "
        .cbCancel.Cancel = True
        .cbOK.Default = True
        .ComboBox1.List = vData
        .Show
        If .cancelled Then GoTo Coda
        sPass = .TextBox2.Text
    End With

sSQL = "declare @n int; select @n= personID from org.users u "
sSQL = sSQL & " join org.persons p on p.personID=u.userID "
'sSQL = sSQL & "where p.lfmname = '" & accountable & "'  and password= '" & sPass & "'; "
sSQL = sSQL & "select isnull(@n, 0);"
Call newConnection(True)
'iAccPersonid = scalar_value(sSQL, cnn:=cn)
'If iAccPersonid = 0 Then
'    MsgBox "неверный пароль"
'    GoTo coda
'End If

Coda:
Application.EnableEvents = True
End Function
Sub call_authority()
    Dim personid As Integer
    personid = personid_authorized
    If personid = 0 Then
        MsgBox "wrong"
    Else: MsgBox "OK"
    End If
End Sub
Sub deleteallconnections()
Dim cnnon As WorkbookConnection
Application.DisplayAlerts = False
If wkb.Connections.count = 0 Then Exit Sub
For Each cnnon In wkb.Connections
            Select Case left(cnnon.Name, 10)
                Case "Connection"
                    cnnon.Delete
            End Select
Next
Application.DisplayAlerts = True
End Sub

'------------------------------------------------------------------------------------------------------

Function generate_code() As String
    generate_code = str(WorksheetFunction.RandBetween(100000, 999999))
End Function
'------------------------------------------------------------------------------------------------------


Sub Send_PushNotification(the_code As String, employee As String, Optional sale As String, _
    Optional opertype As String)

'Activate "Microsoft XML, v6.0" under Tools -- References
Dim ACCESS_TOKEN As String, ACCESS_TOKEN_INPUT As String, pb_title_input As String, pb_body_input As String, _
        pb_title As String, pb_body As String, Url As String, postData As String
Dim Request As Object '   , the_code As String

'original version did not have an argument, so the_code was generated
'the_code = generate_code
'=======================================
'CHANGE THE FOLLOWING
ACCESS_TOKEN_INPUT = "o.meqgj9miVYRL6ce1lhJ1B89NqX5tGw5u"
pb_title_input = "Authorization Code"
pb_body_input = the_code & "\n\n" & employee
If sale <> "" Then
    pb_title_input = "Cash Sale:"
    pb_body_input = sale & pb_body_input
ElseIf opertype <> "" Then
    pb_body_input = opertype & ", " & pb_body_input
End If
'=======================================
'Authentication
ACCESS_TOKEN = "Bearer " & ACCESS_TOKEN_INPUT

'Variables
pb_title = """" & pb_title_input & """"
pb_body = """" & pb_body_input & """"

'Use XML HTTP
Set Request = CreateObject("MSXML2.ServerXMLHTTP.6.0")

'Specify Target URL
Url = "https://api.pushbullet.com/v2/pushes"

'Open Post Request
Request.Open "Post", Url, False

'Request Header
Request.setRequestHeader "Authorization", ACCESS_TOKEN
Request.setRequestHeader "Content-Type", "application/json;charset=UTF-8"

'Concatenate PostData
postData = "{""type"":""note"",""title"":" & pb_title & ",""body"":" & pb_body & "}"
'Send the Post Data
Request.send postData

'[OPTIONAL] Get response text (result)
'MsgBox Request.responseText

End Sub

'-------------------------------------------------------------------
'Reference Microsoft Shell Controls and Automation
'Reference Microsoft Scripting Runtime
Sub getProps_2()
    Dim PATH_FOLDER As Variant 'as variant, not as string
    Dim objShell As Shell
    Dim objFolder As Folder3
    Dim dProps As Dictionary
    Dim fileProps(500) As Variant, sFileProp As String
    Dim fi As Object, oj_file As Object
    Dim i As Long, j As Long, V As Variant
    Dim dFileProps As Dictionary
    Dim filePropIDX() As Long
    Dim wbRes As Workbook, wsRes As Worksheet, rRes As Range, vRes As Variant
    Dim s_file_name  As String
    Dim sTag As String
    
s_file_name = "_M3Q8760.jpg"
PATH_FOLDER = "S:\approved_photos\PJ"
    
'determine where results will go
Set wbRes = ActiveWorkbook
Set wsRes = wbRes.Worksheets("Sheet4") 'change to suit
    Set rRes = wsRes.Cells(1, 1)

    Set objShell = New Shell
    Set objFolder = objShell.Namespace(PATH_FOLDER)
    
'Get desired extended property index
    With objFolder
        For i = 0 To 500 'UBound(fileProps)
            fileProps(i) = .GetDetailsOf(.items, i)
        Next i
' file property "Tags" index =18
        sFileProp = .GetDetailsOf(.items, 18)
    End With
    

'desired properties
V = Array("Name", "Title", "Subject", "Tags")
'V = Array("Name", "Date modified", "Authors", "Camera Maker", "Camera Model", "Dimensions", "F-Stop", "Subject")

ReDim filePropIDX(0 To UBound(V))

Dim file_tags_idx As Integer
With Application.WorksheetFunction
    For i = 0 To UBound(V)
        filePropIDX(i) = .Match(V(i), fileProps, 0) - 1
    Next i
    file_tags_idx = .Match("Tags", fileProps, 0) - 1
End With
    
Set dFileProps = New Dictionary



For Each fi In objFolder.items
    If fi.Name = s_file_name Then
        Set oj_file = fi
        sTag = objFolder.GetDetailsOf(oj_file, 18)
    End If
'    If fi.name Like "*.*" Then
'        ReDim V(0 To UBound(filePropIDX))
'            For I = 0 To UBound(V)
'                V(I) = objFolder.GetDetailsOf(fi, filePropIDX(I))
'
'            Next I
'
'            dFileProps.Add Key:=fi.Path, item:=V
'    End If
'
Next fi
    

'Create results array and write to worksheet
ReDim vRes(0 To dFileProps.count, 1 To UBound(filePropIDX) + 1)
Dim result As String
result = objFolder.GetDetailsOf(s_file_name, 18)
'Headers:
For j = 0 To UBound(filePropIDX)
    vRes(0, j + 1) = fileProps(filePropIDX(j))
Next j

'data
i = 0
For Each V In dFileProps.Keys
    i = i + 1
    For j = 0 To UBound(dFileProps(V))
        vRes(i, j + 1) = dFileProps(V)(j)
        
    Next j
Next V
    
'write to the worksheet
Application.ScreenUpdating = False
Set rRes = rRes.Resize(UBound(vRes, 1) + 1, UBound(vRes, 2))
With rRes
    .EntireColumn.Clear
    .value = vRes
    With .Rows(1)
        .Font.Bold = True
        .HorizontalAlignment = xlCenter
    End With
    .EntireColumn.AutoFit
End With
Application.ScreenUpdating = True
End Sub
Function photo_barcodeid(s_path As String, s_file_name As String) As Long
Dim barcodeid As Long, tag As String, delimiter As Integer
tag = file_property(s_path, s_file_name)
On Error Resume Next
delimiter = WorksheetFunction.Find(";", tag)
On Error GoTo 0
If delimiter = 0 Then
    photo_barcodeid = CLng(tag)
Else
    photo_barcodeid = left(tag, delimiter - 1)
End If
End Function


Function file_property(s_path As String, s_file_name As String, Optional prop_name As Integer = 18) As String
'V = Array("Name", "Title", "Subject", "Tags") - then names of file properties as per Microsoft
    Dim PATH_FOLDER As Variant 'as variant, not as string
    Dim objShell As Shell
    Dim objFolder As Folder3
    Dim fi As Object, oj_file As Object
    Dim sTag As String
        
'PATH_FOLDER = "S:\approved_photos\PJ"
PATH_FOLDER = left(s_path, Len(s_path) - 1)
    
Set objShell = New Shell
Set objFolder = objShell.Namespace(PATH_FOLDER)
  

For Each fi In objFolder.items
    If fi.Name = s_file_name Then
        Set oj_file = fi
        sTag = objFolder.GetDetailsOf(oj_file, 18)
    End If
Next fi
file_property = sTag

Application.ScreenUpdating = True
End Function
Sub DeleteAllFilesInDir(pvDir)
Dim fso, oFile, oFolder, f_name As String


    Set fso = CreateObject("Scripting.FileSystemObject")
    Set oFolder = fso.GetFolder(pvDir)
    For Each oFile In oFolder.Files
            f_name = pvDir & oFile.Name
            fso.DeleteFile f_name
    Next


Set fso = Nothing
Set oFile = Nothing
Set oFolder = Nothing
End Sub
Sub Python_proc(pyth_proc As String, Optional pyth_arg As String)
Dim PID

ChDrive python_path
ChDir python_path
PID = Shell("python " & pyth_proc & " " & pyth_arg, 0)


End Sub

Sub pyth_caller()
Dim bool As String, ws As Worksheet, rn As Range
Application.ScreenUpdating = False
Set ws = ActiveSheet
Set rn = ws.Cells(1)
bool = rn
Call Python_proc("images_to_sizes.py", bool)
End Sub
'
'Private Declare Function GetEnvVar Lib "kernel32" Alias "GetEnvironmentVariableA" _
'    (ByVal lpName As String, ByVal lpBuffer As String, ByVal nSize As Long) As Long

Function GetEnvironmentVariable(var As String) As String
Dim numChars As Long

    GetEnvironmentVariable = String(255, " ")

    numChars = GetEnvVar(var, GetEnvironmentVariable, 255)

End Function
Sub call_enf()
Dim env_s, i As Integer, ws As Worksheet, rn As Range, batch As Boolean, env_test As String
Application.ScreenUpdating = False

env_test = "environ_test"
Set ws = ws_insert(env_test)


Set rn = ws.Cells(1)
With rn
    For i = 1 To 255
        .Offset(i) = Environ(i)
        If Environ(i) = "inBatch = True" Then
            
        End If
    Next
End With
rn.value = Environ(15)

's = GetEnvironmentVariable("InBatch")
End Sub

Function return_table(sql As String, Optional anfan_base As Boolean, Optional cnn As ADODB.Connection) As Variant
Dim rs As ADODB.Recordset, fanfan_base As Boolean
    If Not anfan_base Then fanfan_base = True
    If cnn Is Nothing Then
        Call newConnection(fanfan_base)
        Set rs = cn.Execute(sql)
        If Not rs.EOF Then
            return_table = rs.GetRows
        End If
        cn.Close
        Set cn = Nothing
    End If
End Function

Function frmValue(sql As String, fCap As String, Optional new_base As Boolean, _
    Optional id As Long) As Variant
Dim fanfan_base As Boolean, values
'returns value of combobox styled as listbox

If new_base = False Then fanfan_base = True
Call newConnection(fanfan_base)
Set rs = cn.Execute(sql)
values = WorksheetFunction.Transpose(rs.GetRows)
    With frmValidationNew
        .caption = fCap
        With .Label1
            .top = 20
            .left = 30
            .caption = "выберите значение"
            .TextAlign = fmTextAlignLeft
        End With
        .width = 250
        With .ComboBox1
            
            .left = 30
            .top = 50
            .width = 180
            .List = values
            .Style = fmStyleDropDownList
            If id Then
                .ColumnCount = 2
                .ColumnWidths = 180
            End If
            .SetFocus
        End With
        With .cbCancel
            .left = 30
            .caption = "отмена"
        End With
        .cbOK.left = 150
        .Show
        If Not .cancelled Then
            frmValue = .ComboBox1.Text
            If id Then
                With .ComboBox1
                    frmValue = .List(.ListIndex, 1)
                End With
            End If
        End If
    End With
End Function
Function lo_table(sql As String, fan_fan As Boolean, _
        ws As Worksheet, Optional rn As Range, Optional lo_name As String _
        ) As ListObject
If rn Is Nothing Then Set rn = ws.Cells(1)
Call newConnection(fan_fan)
Set rs = cn.Execute(sql)
For i = 0 To rs.fields.count - 1
    rn.Offset(0, i) = rs.fields(i).Name
Next
    rn.Offset(1).CopyFromRecordset rs
    Set lo_table = ws.ListObjects.Add(xlSrcRange, rn.CurrentRegion, , xlYes)
    If lo_name <> "" Then lo_table.Name = lo_name
End Function


Function user_id(username As String)
' return userid if the password is correct
Dim iUserid As Integer, sSQL As String, sPass As String

With frmPass
    .caption = "Aвторизация: " & username
    .CommandButton1.Cancel = True
    .CommandButton2.Default = True
    .Show
    If .cancelled Then
        GoTo Coda
    End If
    sPass = .TextBox1.Text
End With

sSQL = "declare @n int; select @n= personID from org.users u "
sSQL = sSQL & " join org.persons p on p.personID=u.userID "
sSQL = sSQL & "where p.lfmname = '" & username & "'  and password= '" & sPass & "'; "
sSQL = sSQL & "select isnull(@n, 0);"
user_id = scalar_value(sSQL, cnn:=cn)
Coda:

End Function

Function rs_conn(sql As String, Optional anfan_base As Boolean) As ADODB.Recordset
    Dim fanfan_base As Boolean
    
    If Not anfan_base Then fanfan_base = True
    Call newConnection(fanfan_base)
    Set rs_conn = cn.Execute(sql)
End Function

Function info_type(ws As Worksheet, _
            lo As ListObject, fields As Variant) As String
' this function creates a string @info to be declared as table type as proc parameter
' it iterates through a table , with lo listcolums as arguments
    Dim info As String, lr As ListRow, i As Integer, j As Integer
    
    For Each lr In lo.ListRows
        If Not lr.Range.EntireRow.Hidden Then
            info = info & "("
            For j = 0 To UBound(fields)
                info = info & lr.Range.Cells(lo.ListColumns(fields(j)).Index) _
                    & ", "
            Next
            info = left(info, Len(info) - 2) & "), "
        End If
    Next
    info_type = left(info, Len(info) - 2)
End Function
Function exec_sql(sql As String, anfan_base As Boolean)
Dim fanfan_base As Boolean
If anfan_base = False Then fanfan_base = True
Call newConnection(fanfan_base)
Set rs = cn.Execute

End Function
Sub keep_pt_filters()
Dim ws As Worksheet, pt As PivotTable, vFields, dict As Scripting.Dictionary
    Set ws = ActiveSheet
    Set pt = ws.PivotTables(1)
    vFields = Array("месяц", "магазин", "форма_оплаты")
    Set dict = pt_hiddens(ws, pt)
End Sub
Sub pt_filters(ws As Worksheet, pt As PivotTable, vFields)
Dim item, ptf As PivotField, pti As PivotItem
For Each item In vFields
    For Each ptf In pt.PivotFields
        If ptf.Name = item Then
            For Each pti In ptf.PivotItems
           
                If pti.Visible = True Then
                    MsgBox pti.caption
                End If
            Next
        End If
    Next
Next

End Sub
Function pt_hiddens(ws As Worksheet, pt As PivotTable) As Scripting.Dictionary
Dim item, ptf As PivotField, pti As PivotItem, dict As Scripting.Dictionary
Set dict = New Scripting.Dictionary
    For Each ptf In pt.ColumnFields
            For Each pti In ptf.PivotItems
                If IsDate(pti) Then pti.value = Format(pti.value, "dd.MM.yyyy")
                If pti.Visible = False Then
                    dict(ptf.Name) = dict(ptf.Name) & pti.value & ","
                End If
            Next
            If dict(ptf.Name) <> Empty Then
                dict(ptf.Name) = left(dict(ptf.Name), Len(dict(ptf.Name)) - 1)
            End If
    Next
    
    For Each ptf In pt.RowFields
            For Each pti In ptf.PivotItems
                If pti.Visible = False Then
                    dict(ptf.Name) = dict(ptf.Name) & pti.value & ","
                End If
            Next
            If dict(ptf.Name) <> Empty Then
                dict(ptf.Name) = left(dict(ptf.Name), Len(dict(ptf.Name)) - 1)
            End If
    Next
    
    For Each ptf In pt.PageFields
            For Each pti In ptf.PivotItems
                    If ptf.CurrentPage <> pti Then
                        dict(ptf.Name) = dict(ptf.Name) & pti.value & ","
    '                    Debug.Print dict(ptf.Name)
                    End If
                
            Next
            If dict(ptf.Name) <> Empty Then
                dict(ptf.Name) = left(dict(ptf.Name), Len(dict(ptf.Name)) - 1)
    '            Debug.Print dict(ptf.Name)
            End If
    Next
Set pt_hiddens = dict
End Function

Function user_authorized(data As Variant) As Integer
Dim sql As String, userid As Integer, password As String

With frmAthorization
    .caption = "авторизация"
    .Label2.caption = "пользователь"
    .Label1.caption = "пароль"
    With .TextBox1
        .TabIndex = 1
        .PasswordChar = "*"
    End With
    With .ComboBox1
        .TabIndex = 0
        .SetFocus
        .List = data
    End With
    .cbCancel.TabIndex = 2
    With .cbOK
        .TabIndex = 3
        .Default = True
    End With
    .Show
    If Not .cancelled Then
        userid = .ComboBox1.List(.ComboBox1.ListIndex, 1)
        password = .TextBox1.Text
        sql = "if exists (select * from org.users u where "
        sql = sql & "u.userid = " & userid & " and "
        sql = sql & "u.password = '" & password & "') "
        sql = sql & "select 'True'  else select 'False'"
        Set rs = cn.Execute(sql)
        data = rs.GetRows
        If data(0, 0) Then
            user_authorized = userid
        Else
            user_authorized = 0
        End If
    End If
End With

End Function


Enum SMSCols
    Receiver = 2    ' col B
    TextMessage = 3 ' col C
    Status = 5      ' col E
End Enum

Private Const StartRow As Long = 10

Option Explicit
Public Sub Send_SMS(the_code As String, phone As String, Optional issue As String)

        On Error GoTo ErrorHandler

        Dim Request As Object
        Dim response As Object
        Dim ACCESS_TOKEN As String
        Dim TARGET_DEVICE_IDEN As String
        Dim ReceiverNumber As String
        Dim TextMessage As String
        Dim StatusResponse As String
        Dim postData As String
        Dim Url As String
        Dim LastRow_Receiver As Long
        Dim LastRow_Status As Long
        Dim i As Long
        Dim rec_phone As String, text_message As String
        

        ACCESS_TOKEN = ACCESS_TOKEN_pc
        TARGET_DEVICE_IDEN = """" & DEVICE_ID & """"
        rec_phone = "+7" & phone
        text_message = the_code
        If issue <> "" Then text_message = text_message & "\n" & issue


              'Get receiver number & text message
            ReceiverNumber = """" & rec_phone & """"
            TextMessage = """" & text_message & """"
              
              'Remove line breaks (as this will lead to JSON error)
           TextMessage = Replace(TextMessage, vbCrLf, "|")

              'Use XML HTTP
           'Set Request = CreateObject("Microsoft.XMLHTTP")
           Set Request = CreateObject("MSXML2.ServerXMLHTTP.6.0")
              'Specify Target URL
           Url = "https://api.pushbullet.com/v2/texts"
          
              'Open Post Request
           Request.Open "Post", Url, False
          
              'Request Header
           Request.setRequestHeader "Access-Token", ACCESS_TOKEN_pc
           Request.setRequestHeader "Content-Type", "application/json;charset=UTF-8"
          
              'Concatenate PostData
           postData = "{""data"":{""target_device_iden"":" & TARGET_DEVICE_IDEN & ",""addresses"":[" & ReceiverNumber & "],""message"":" & TextMessage & "}}"

              'Send the Post Data
           Request.send postData
              
              'Parse Reponse to JsonConverter and construct StatusReponse text
           Set response = JsonConverter.ParseJson(Request.responseText)
           If Request.Status = 200 Then
               StatusResponse = "Status Code: " & Request.Status & " | Status Text: Sent successfully"
           Else
               StatusResponse = "Status Code: " & Request.Status & " | Status Text: " & response("error")("message")
           End If

              'Return status to worksheet
           'ws.Cells(i, SMSCols.Status) = Format(Now, "mm/dd/yyyy HH:mm:ss") & "| " & StatusResponse
' disabled this message - confusing
           'MsgBox Format(Now, "mm/dd/yyyy HH:mm:ss") & "| " & StatusResponse

              'Wait for 2 seconds
 '          Application.Wait (Now + TimeValue("0:00:02"))

EndIt:
       Exit Sub

ErrorHandler:
       DisplayError Err.Source, Err.Description, "SendSMS.SendSMS", Erl
       Resume EndIt

End Sub


Function array_query(sql As String, cn As Connection) As Variant
Set rs = cn.Execute(sql)
If Not rs.EOF Then
    array_query = rs.GetRows
    array_query = TransposeArray(array_query)
Else
    array_query = Null
End If
End Function
Function array_dim(data As Variant) As Integer
Dim k As Integer, res As Integer
On Error Resume Next
Do While Err.Number = 0
    k = k + 1
    res = UBound(data, k)
Loop
array_dim = k - 1
On Error GoTo 0

End Function
Function rnCell(sString As String, lo As ListObject) As Variant
    With lo.ListColumns(1).DataBodyRange
        Set rnCell = .Cells(WorksheetFunction.Match(sString, .Cells, 0)).Offset(0, 1)
    End With
End Function
Function rnCell_str(sString As String, lo As ListObject) As String
    With lo.ListColumns(1).DataBodyRange
        rnCell_str = .Cells(WorksheetFunction.Match(sString, .Cells, 0)).Offset(0, 1)
    End With
End Function

Public Sub PythonOutput_orig()

    Dim fso As New FileSystemObject
    Dim oShell As Object, oCMD As String
    Dim PID
    Dim oExec As Object, oOutput As Object
    Dim arg As Variant
    Dim s As String, sLine As String, pythonScriptPath As String, file As String

    pythonScriptPath = "D:/Development/jobs/excel_samples.py"

    Set oShell = CreateObject("WScript.Shell")
    'arg = " -windowstyle hidden"
    'oCmd = "python " & pythonScriptPath & " " & arg


    'Set oExec = oShell.Exec(oCmd)

'    Set oOutput = oExec.StdOut
    

'    While Not oOutput.AtEndOfStream
'        sLine = oOutput.ReadLine
'        If sLine <> "" Then s = s & sLine & vbNewLine
'    Wend

    'Debug.Print s
    PID = Shell("python " & pythonScriptPath, 0)
    file = "D:\Development\jobs\result.txt"
    Open file For Input As #1
    Do Until EOF(1)
        Line Input #1, textline
        arg = arg & textline
    Loop
    Debug.Print arg
    file.Close

    Set oOutput = Nothing: Set oExec = Nothing
    Set oShell = Nothing

End Sub
Function PythonOutput_old(pythonScriptPath As String, Optional arg As String) As Variant

    Dim PID
    Dim file As String
    Dim s As Variant
    Dim textline

    PID = Shell("python " & pythonScriptPath & " " & arg, 0)
    file = "D:\Development\jobs\result.txt"
    Application.Wait (Now + TimeValue("0:00:002"))
    
    Open file For Input As #1
        Line Input #1, textline
        s = textline
    Do Until EOF(1)
        Line Input #1, textline
        s = s & "; " & textline
    Loop
    
    Close (1)
    PythonOutput = Split(s, "; ")
    Kill file
    
End Function
Function PythonOutput3(pyth_flle As String, Optional arg As String) As Variant

    Dim PID
    Dim file As String, pythonScriptPath As String
    Dim s As Variant
    Dim textline

    'python_path_sms  - Const
    pythonScriptPath = python_path_sms & pyth_flle & ".py"
    PID = Shell("python " & pythonScriptPath & " " & arg, 0)
    '---------------------
    Debug.Print "python " & pythonScriptPath & " " & arg
    file = "D:\Development\jobs\result.txt"
    Application.Wait (Now + TimeValue("0:00:02"))
    
    Open file For Input As #1
        Line Input #1, textline
        s = textline
    Do Until EOF(1)
        Line Input #1, textline
        s = s & "; " & textline
    Loop
    
    Close (1)
    PythonOutput2 = Split(s, "; ")
    Kill file
    
End Function
Function PythonOutput(pyth_flle As String, Optional arg As String) As Variant

    Dim PID
    Dim file As String, pythonScriptPath As String
    Dim s As Variant
    Dim textline

    'python_path_sms  - Const
    pythonScriptPath = python_path_sms & pyth_flle & ".py"
    PID = Shell("python " & pythonScriptPath & " " & arg, 0)
    '---------------------
    'Debug.Print "python " & pythonScriptPath & " " & arg
    file = "D:\Development\jobs\result.txt"
    Application.Wait (Now + TimeValue("0:00:10"))
    PythonOutput = Read_UTF_8_Text_File(file)

    Kill file
    
End Function
Function PythonOutput_s(pyth_flle As String, Optional arg As String) As Variant

    Dim pythonScriptPath As String
    Dim s As Variant, file As String
    Dim oShell As Object, sCMD As String

    Set oShell = CreateObject("WScript.Shell")

    'python_path_sms  - Const
    pythonScriptPath = python_path_sms & pyth_flle & ".py"
    sCMD = "python " & pythonScriptPath & " " & arg
    s = oShell.Run(sCMD, 0, True)
    file = "D:\Development\jobs\result.txt"
    PythonOutput_s = Read_UTF_8_Text_File(file)
    If IsArray(PythonOutput_s) Then
        'Kill file
    End If
    
End Function

Function TransposeArray(MyArray As Variant) As Variant
    Dim x As Long, y As Long
    Dim maxX As Long, minX As Long
    Dim maxY As Long, minY As Long
    
    Dim tempArr As Variant
    
    'Get Upper and Lower Bounds
    maxX = UBound(MyArray, 1)
    minX = LBound(MyArray, 1)
    maxY = UBound(MyArray, 2)
    minY = LBound(MyArray, 2)
    
    'Create New Temp Array
    ReDim tempArr(minY To maxY, minX To maxX)
    
    'Transpose the Array
    For x = minX To maxX
        For y = minY To maxY
            tempArr(y, x) = MyArray(x, y)
        Next y
    Next x
    
    'Output Array
    TransposeArray = tempArr
    
End Function

Function customer_id(phone As String) As Long
Dim sql As String

sql = "SELECT p.personID FROM cust.persons p JOIN "
sql = sql & "cust.connect c ON c.personID=p.personID "
sql = sql & "WHERE c.connect= " & "'" & phone & "'"
customer_id = scalar_value(sql)
End Function
Function phone_string(Optional count As Integer) As String
Dim ws As Worksheet, lo As ListObject, str As String
Dim lr As ListRow, lc As ListColumn

If worksheet_exists("клиенты для СМС") Then
    Set ws = Worksheets("клиенты для СМС")
    Set lo = ws.ListObjects("cust_list")
    Set lc = lo.ListColumns("phone")
    With lo
        For Each lr In lo.ListRows
            With lr.Range
                If lr.Range.Cells(lo.ListColumns("include").Index) = "yes" _
                                    And Not lr.Range.EntireRow.Hidden Then
                        str = str & 7 & .Cells(lc.Index) & ", "

                End If
            End With
        Next
    End With
    phone_string = left(str, Len(str) - 2)
    
    
End If
    
End Function
Function phone_string_1( _
        Optional cycle_count As Integer, Optional start_row As Integer _
    ) As String
    
Dim ws As Worksheet, lo As ListObject, str As String, i As Integer
Dim lr As ListRow, lc As ListColumn, lrcount As Integer, end_row As Integer

If worksheet_exists("клиенты для СМС") Then
    Set ws = Worksheets("клиенты для СМС")
    Set lo = ws.ListObjects("cust_list")
    Set lc = lo.ListColumns("phone")
    With lo
        end_row = WorksheetFunction.Max(start_row - cycle_count, 1)
        For i = start_row To end_row Step -1
            Set lr = lo.ListRows(i)
            With lr.Range
                If lr.Range.Cells(lo.ListColumns("include").Index) = "yes" _
                                    And Not lr.Range.EntireRow.Hidden Then
                        str = str & 7 & .Cells(lc.Index) & ", "
                        lr.Range.EntireRow.Hidden = True
                End If
            End With
        Next
    End With
    phone_string_1 = left(str, Len(str) - 2)
    
    
End If
    
End Function
Function phone_string_2( _
        Optional cycle_count As Integer, Optional start_row As Integer _
    ) As String
    
Dim ws As Worksheet, lo As ListObject, str As String, i As Integer
Dim lr As ListRow, lc As ListColumn, lrcount As Integer, end_row As Integer

If worksheet_exists("клиенты для СМС") Then
    Set ws = Worksheets("клиенты для СМС")
    Set lo = ws.ListObjects("cust_list")
    Set lc = lo.ListColumns("phone")
    With lo
        end_row = WorksheetFunction.Max(start_row - cycle_count, 1)
        For i = start_row To end_row Step -1
            Set lr = lo.ListRows(i)
            With lr.Range
                If lr.Range.Cells(lo.ListColumns("include").Index) = "yes" _
                                    And Not lr.Range.EntireRow.Hidden Then
                        str = str & 7 & .Cells(lc.Index) & "; "
                        lr.Range.EntireRow.Hidden = True
                End If
            End With
        Next
    End With
    phone_string_2 = left(str, Len(str) - 2)
    
End If
    
End Function
Public Function Read_UTF_8_Text_File(file_path As String)
    'ensure reference is set to Microsoft ActiveX DataObjects library (the latest version of it).
    'under "tools/references"... references travel with the excel file, so once added, no need to worry.
    'if not you will get a type mismatch / library error on line below.
    
    Dim adoStream As ADODB.Stream
    Dim var_String As Variant, errNumber As Integer
    
    Set adoStream = New ADODB.Stream

    adoStream.Charset = "UTF-8"
    adoStream.Open
    On Error Resume Next
        adoStream.LoadFromFile "D:\Development\jobs\result.txt"  'change this to point to your text file
        adoStream.LoadFromFile file_path  'change this to point to your text file
        errNumber = Err.Number
    On Error GoTo 0
    If errNumber <> 0 Then
        
        Read_UTF_8_Text_File = ""
        
    Else
    'split entire file into array - lines delimited by CRLF
        Read_UTF_8_Text_File = WorksheetFunction.Transpose(Split(adoStream.ReadText, vbCrLf))
    End If
    
End Function
Sub print_my_ip()
Debug.Print my_ip
End Sub

Function my_ip()

    Dim file As String, pythonScriptPath As String
    Dim s As Variant, response As String
    Dim oShell As Object, sCMD As String
    Set oShell = CreateObject("WScript.Shell")


ChDrive "D"
ChDir "\Development\Jobs"
sCMD = "python -c  ""import sql_sms as s; print(s.my_ip())"""
    s = oShell.Run(sCMD, 0, True)

    file = "D:\Development\jobs\result.txt"
    my_ip = Read_UTF_8_Text_File(file)(1)

End Function
Sub tst()

Dim vButtons As Variant, action As String, ws As Worksheet
vButtons = Array( _
    "на главную", _
    "новый ордер", _
    "сканировать баркод", _
    "записать чек", _
    "записать на счет клиента", _
    "скидка не весь чек", _
    "скидка на баркод", _
    "цена на баркод" _
)

action = "test_buttons"
Call buttons_add(vButtons, action, 10, 30, 95, 150, ws)
End Sub
Sub buttons_add(vButtons As Variant, action As String, but_in_colum As Integer, _
    gap As Integer, position_h, width_v As Integer, Optional ws As Worksheet, _
    Optional black As Boolean)

Dim bt As Button, n As Integer, k As Integer, j As Integer
Dim But(0 To 50) As Button

    If ws Is Nothing Then
        Set ws = ws_insert("buttons")
    Else
        Dim ws_protected As Boolean
        ws_protected = ws.ProtectContents
        If ws_protected = True Then ws.Unprotect
        For Each bt In ws.Buttons
            bt.Delete
        Next
    End If
    
    n = UBound(vButtons) + 1
    i = 0
    j = 0
    k = but_in_colum
    Do While i + j * k < n
        For i = 0 To k - 1
            Set But(i + j * k) = ws.Buttons.Add(position_h + j * (width_v + gap), 15 * i, width_v, 15)
            With But(i + j * k)
                .Text = vButtons(i + j * k)
                .OnAction = action
                .Font.Color = -16777012
                .Font.Color = -11489280
                If black Then .Font.Color = 0
            End With
            If i + j * k = n - 1 Then
                Exit For
            End If
        Next
        j = j + 1
        i = 0
    Loop
    If ws_protected = True Then ws.Protect
End Sub
Sub test_buttons()
    Dim ButtonText As String
    ButtonText = ActiveSheet.Shapes(Application.caller).AlternativeText
    Select Case ButtonText
        Case "на главную"
            MsgBox ButtonText
        Case "скидка на баркод"
            MsgBox ButtonText
        
    End Select
End Sub
Function fields_filled(lo As ListObject, Optional except_array As Variant) As Boolean
Dim rn As Range, lc As ListColumn
    Set lc = lo.ListColumns(2)
    For Each rn In lc.DataBodyRange.Cells
        If belongs_to_array(rn.Offset(0, -1), except_array) = False Then
            If rn = "" Then
                rn.Select
                MsgBox "Все поля в таблице должны быть заполнены."
                Exit Function
            End If
        End If
    Next
    If rn Is Nothing Then fields_filled = True
End Function

Function lo_name_exists(ws As Worksheet, loname As String) As Boolean
    Dim lo As ListObject
    
For Each lo In ws.ListObjects
    If lo.Name = loname Then
        lo_name_exists = True
        Exit For
    End If
Next

End Function

Function name_exists(the_name As String) As Boolean
Dim wb As Workbook, nm As Name
Set wb = ThisWorkbook
For Each nm In wb.Names
    If nm.Name = the_name Then
        name_exists = True
        Exit For
    End If
Next
End Function

Function this_shop() As String
Dim sql As String
    sql = "SELECT d.divisionfullname FROM org.divisions d "
    sql = sql & " WHERE d.divisionID = org.division_id_ws('" & CompName & "')"
    this_shop = scalar_value(sql)
End Function
Function scalar_value(sql As String, Optional newbase As Boolean, Optional cnn As ADODB.Connection) As Variant
Dim vScalar As Variant, fanfan_base As Boolean
If newbase = False Then fanfan_base = True
If cnn Is Nothing Then
    Call newConnection(fanfan_base)
    Set cnn = cn
End If
    Set rs = cnn.Execute(sql)
    If Not rs.EOF Then
        vScalar = rs.GetRows
        scalar_value = vScalar(0, 0)
        If IsNull(scalar_value) Then scalar_value = 0
    Else
        scalar_value = ""
    End If
End Function
Function var_value(sql As String, Optional newbase As Boolean, _
    Optional cnn As ADODB.Connection) As Variant
Dim fanfan_base As Boolean

If newbase = False Then fanfan_base = True
If cnn Is Nothing Then
    Call newConnection(fanfan_base)
    Set cnn = cn
End If
    Set rs = cnn.Execute(sql)
    If Not rs.EOF Then
        var_value = rs.GetRows
    Else
        var_value = ""
    End If

End Function

Function shop_attendance_date(shop As String, sDate As String) As Variant
Dim sql As String, att As Variant

    sql = "SELECT person FROM org.attendance_date_shop_f"
    sql = sql & "(org.division_id('" & shop & "'), '" & sDate & "') "
    att = var_value(sql)
    att = WorksheetFunction.Transpose(att)
    shop_attendance_date = WorksheetFunction.Transpose(att)
    
End Function
Function lo_string(lo As ListObject, fields As Variant, Optional not_empty As String) As String
' use this function to cycle fields into sql info string
' optional not_empty if we give table a kind of filter criteria ("yes", for example)
Dim info As String, lr As ListRow, item As Variant
    For Each lr In lo.ListRows
        With lr.Range
            If Not .EntireRow.Hidden Then
                If not_empty <> "" Then
                    If Not .Cells(lo.ListColumns(not_empty).Index) = Empty Then
                        info = info & "("
                        For Each item In fields
                            info = info & IIf(.Cells(lo.ListColumns(item).Index) = Empty, 0, _
                                .Cells(lo.ListColumns(item).Index)) & ", "
                        Next
                        info = left(info, Len(info) - 2) & "), "
                    End If
                Else
                    info = info & "("
                    For Each item In fields
                        info = info & IIf(.Cells(lo.ListColumns(item).Index) = Empty, 0, _
                            .Cells(lo.ListColumns(item).Index)) & ", "
                    Next
                    info = left(info, Len(info) - 2) & "), "
                End If
            End If
        End With
    Next
    If info <> "" Then lo_string = left(info, Len(info) - 2)
End Function
Function VPN_is_on() As Boolean
    If my_ip = localserver Then
    Else
        VPN_is_on = True
    End If
End Function
Function ws_renew(wsname As String) As Worksheet
    Application.DisplayAlerts = False
    If worksheet_exists(wsname) Then Worksheets(wsname).Delete
    Set ws_renew = Worksheets.Add
    ws_renew.Name = wsname
    Application.DisplayAlerts = True
End Function
Function barcode_id(Optional manual As Boolean) As Long
Application.ScreenUpdating = False
    With frmSimple
        If manual Then
            .StartUpPosition = manual
            .left = 9000
            .top = 300
        End If
        .caption = "БАРКОД"
        .Label1.caption = "отсканируйте баркод"
        With .cbOK
            .Default = True
        End With
            .cbCancel.Cancel = True
        .Show
        If Not .cancelled Then
            If .TextBox1.value <> "" Then
                barcode_id = left(Right(.TextBox1.value, 7), 6)
            End If
        End If
    End With
End Function
Function POS_lo(ws_name As String, lo_name As String, Optional extra As String) As ListObject
Dim ws As Worksheet, items As Variant, rn As Range, fields As String, divisions
Dim sql As String, divisionid As Integer, workstationid As Integer, sdivision As String
Dim emps, sEmpls As String
    
    Application.ScreenUpdating = False
    Set ws = ws_insert(ws_name)
    Set rn = ws.Cells(1)
    items = Array("Дата", "Магазин", "Продавец", "Клиент", "Кл. телефон")
    fields = Join(items, ", ") & ", " & extra
    If extra = "" Then fields = left(fields, Len(fields) - 2)
    items = Split(fields, ", ")
    Set POS_lo = lo_from_array(ws, rn, items, lo_name)
    rnCell("Дата", POS_lo) = Date
    
sql = "select workstation, divisionid, division, workstationid from org.active_divisions_f('" _
    & Format(Date, "yyyyMMdd") & "')"
divisions = return_table(sql)
If IsArray(divisions) Then
    For i = 0 To UBound(divisions, 2)
        If divisions(0, i) = CompName Then
            rnCell("Магазин", POS_lo) = divisions(2, i)
            divisionid = divisions(1, i)
            workstationid = divisions(3, i)
        End If
        sdivision = sdivision & divisions(2, i) & ", "
    Next
    sdivision = left(sdivision, Len(sdivision) - 2)
End If
Set rn = rnCell("Магазин", POS_lo)
If sdivision <> "" Then
    rn.Validation.Add xlValidateList, , , sdivision
End If

If workstationid <> 0 Then
    sql = "select personID, lfmname from org.registered_emps_f ('" _
        & Format(Date, "yyyyMMdd") & "') where workstationID = " _
        & workstationid
    emps = return_table(sql)
    If IsArray(emps) Then
        For i = 0 To UBound(emps, 2)
            sEmpls = sEmpls & emps(1, i) & ", "
        Next i
        sEmpls = left(sEmpls, Len(sEmpls) - 2)
        Set rn = rnCell("Продавец", POS_lo)
        rn.Validation.Add xlValidateList, , , sEmpls
        If UBound(emps, 2) = 0 Then rn = sEmpls
    End If
End If

End Function
Function lo_sale_receipt(rn As Range, ws As Worksheet, saleid As Long, _
        Optional barcodeid As Long) As ListObject
Dim sql As String, vData As Variant, lc As ListColumn
    sql = "select к.баркод, к.артикул, к.марка, к.категория, к.цвет, к.размер, к.ценник, " & _
        "к.оплачено from inv.sale_receipt_func(" & saleid & ") к"
    Call newConnection(True)
    Set rs = cn.Execute(sql)
    For n = 0 To rs.fields.count - 1
        rn.Offset(0, n) = rs.fields(n).Name
    Next
    vData = rs.GetRows
    rn.Offset(1).Resize(UBound(vData, 2) + 1, UBound(vData, 1) + 1) = WorksheetFunction.Transpose(vData)
    Set lo_sale_receipt = ws.ListObjects.Add(xlSrcRange, rn.CurrentRegion, , xlYes, , "TableStyleMedium3")
    With lo_sale_receipt
        .Name = "список_баркодов"
        Set lc = .ListColumns.Add
        With lc
            .Name = "к возврату"
            .DataBodyRange.Validation.Add xlValidateList, , , "да, нет"
        End With
        If barcodeid <> 0 Then
            n = WorksheetFunction.Match(barcodeid, lo_sale_receipt.ListColumns(1).DataBodyRange, 0)
            With lo_sale_receipt.ListRows(n).Range
                .Cells(.Cells.count) = "да"
            End With
        End If
        .ShowTotals = True
        .ListColumns("оплачено").TotalsCalculation = xlTotalsCalculationSum
        With .ListColumns("к возврату").Total
            .FormulaR1C1 = "=SUMIF([к возврату],""да"",[оплачено])"
            .NumberFormat = Numformatshort
        End With
        .Range.EntireColumn.AutoFit
        .ShowAutoFilter = False
    End With
End Function
Function ArrayTranspose2(InputArray As Variant) As Variant
' Transpose a 2-Dimensional VBA array.
    Dim arrOutput As Variant

    Dim i As Long
    Dim j As Long
    Dim iMin As Long
    Dim iMax As Long
    Dim jMin As Long
    Dim jMax As Long
    Dim addI As Long, addJ As Long
    
    
    addI = IIf(LBound(InputArray, 1) = 0, 1, 0)
    addJ = IIf(LBound(InputArray, 2) = 0, 1, 0)
    iMin = LBound(InputArray, 1) + addI
    iMax = UBound(InputArray, 1) + addI
    jMin = LBound(InputArray, 2) + addJ
    jMax = UBound(InputArray, 2) + addJ

    ReDim arrOutput(jMin To jMax, iMin To iMax)

    For i = iMin To iMax
        For j = jMin To jMax
            arrOutput(j, i) = InputArray(i - addI, j - addJ)
        Next j
    Next i

    ArrayTranspose2 = arrOutput
End Function
Sub test()
Dim rn As Range
Set rn = ActiveCell
rn = ThisWorkbook.Path
End Sub


