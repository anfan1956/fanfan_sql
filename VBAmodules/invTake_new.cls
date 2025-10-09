VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "invTake_new"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Public WithEvents xlsheet As Worksheet
Attribute xlsheet.VB_VarHelpID = -1

Private Sub xlsheet_Change(ByVal Target As Range)

    Dim lo As ListObject, sList As String, loStock As ListObject, rn As Range, n As Integer
    Dim lr As ListRow, rg As Range, loCheck As ListObject, sql As String, barcodeid As Long
    Dim barcode As Variant, loBC As ListObject, i As Integer, j As Integer, takeid As Long
    Dim result As Variant, invType As String, rnType As Range, days As Integer
    Dim bcPosition As Integer, showroom As String

With Application
    .ScreenUpdating = False
    .EnableEvents = False
    .EnableSound = True
End With
xlsheet.Unprotect
Set lo = Target.Worksheet.ListObjects("inv.list")
On Error Resume Next

    If Not rnCell("showroom", lo) Is Nothing Then
        showroom = rnCell("showroom", lo)
    End If
On Error GoTo 0
Set loStock = Target.Worksheet.ListObjects("stock_by_book")
bcPosition = loStock.ListColumns("Баркод").index
Set loBC = Target.Worksheet.ListObjects("BC_entry_inv")

Select Case xlsheet.name
    Case "инв. ведомость"
        Set rnType = rnCell("Тип инвент.", lo)
        takeid = rnCell("инвентаризация №", lo)

        'days = rnCell("Срок, дней", lo)
End Select
Set rn = rnCell("введите баркод", loBC)

If Not Intersect(Target, rn) Is Nothing Then
    barcodeid = IIf(Len(Target) = 6, Target, left(Right(Target, 7), 6))
    rn.value = barcodeid
On Error Resume Next
j = 0
With loStock.ListColumns(bcPosition).DataBodyRange
    ' Use Application.Match instead of WorksheetFunction.Match
    result = Application.match(barcodeid, .Cells, 0)
    ' Check if result is an error
    If Not IsError(result) Then
        j = result
    Else
        j = 0 ' Value not found
    End If
End With
On Error GoTo 0

    
    If j > 0 Then
            MessageBeep &H10
            'MsgBox "Это баркод уже есть"
        Target.ClearContents
        GoTo coda

    End If
        
    Select Case xlsheet.name
        'The first row for consignment Efim
        Case "CONSIGNMENT RETURN"
            sql = "select brand, article, cost, barcodeid, orderID, orderType, category, color, size, status, "
            sql = sql & "shop, lastTran, lastTranDate, showroom from inv.invTake_info_(" & barcodeid & ")"
        Case "инв. ведомость"
            sql = "declare @barcodeid int = " & Target & ";"
            sql = sql & "select  "
            sql = sql & "  [Марка]"
            sql = sql & ", [Артикул]"
            sql = sql & ", [Баркод]"
            sql = sql & ", [Категория]"
            sql = sql & ", [Цвет]"
            sql = sql & ", [Размер]"
            sql = sql & ", [Числится как:]"
            sql = sql & ", [В магазине]"
            sql = sql & ", [Последняя операция]"
            sql = sql & ", [Дата]"
            sql = sql & "from inv.invTakeBarcodeData(@barcodeid);"
        End Select
    Set rs = cn.Execute(sql)
    If rs.EOF Then
        MsgBox "баркод " & barcodeid & " в базе не найден"
        Target.ClearContents
        GoTo coda
    End If
    
'    If showroom <> rs.fields("showroom").value _
'        And showroom <> Empty Then
'            MsgBox "Этот баркод поставлен из другого шоурума - " & rs.fields("showroom").value
'        Target.ClearContents
'        GoTo coda
'    End If
    
    Set rn = loStock.HeaderRowRange.Resize(1, 1)
        If loStock.ListRows(1).Range.Cells(1) = Empty Then
            i = 1
        Else
            i = loStock.ListRows.COUNT + 1
        End If
            Set rn = rn.Offset(i)
    ActiveWindow.scrollRow = WorksheetFunction.Max(2, rn.row - 15)
'    ActiveWindow.SmallScroll Down:=2
    
'    With rn
'        For i = 0 To rs.fields.COUNT - 2
'            rn.Offset(0, i) = rs.fields(i)
'        Next
'    End With
        
        'Application.wait (Now + TimeValue("0:00:001"))
    Select Case xlsheet.name
        Case "инв. ведомость"
            rn.CopyFromRecordset rs
            sql = "exec inv.invTake_p " & takeid & ", " & barcodeid & ", " & days & ";"
            result = var_value(sql)
            If result(0, 0) = 0 Then
                Beep
                
                MsgBox result(1, 0)
                rn.EntireRow.Delete
                i = i - 1
            End If
            rnCell("Учтено в этом док.", lo) = i
            Set rn = rnCell("Тип инвент.", lo)
        Case "CONSIGNMENT RETURN"
            Set rn = rnCell("qty", lo)
            rn = WorksheetFunction.COUNT(loStock.ListColumns("Закупка").DataBodyRange)
            Set rn = rnCell("cost", lo)
            rn = WorksheetFunction.Sum(loStock.ListColumns("Закупка").DataBodyRange)
                    
    End Select
    
    loStock.Range.EntireColumn.AutoFit
    Target.ClearContents
End If

If Not Intersect(Target, rn) Is Nothing Then
    If Target <> Empty Then
        sql = "set nocount on; update it set it.typeid =tt.typeid from inv.inventorytakes it "
        sql = sql & "cross apply inv.invTake_types tt where it.inventorytakeID = "
        sql = sql & takeid & " and takeType = '" & rnType & "'; select @@ROWCOUNT;"
        Dim upCount As Integer
        upCount = scalar_value(sql)
    Else
        MsgBox "Нужно выбрать тип инвентаризации"
        Target.Select
        GoTo noProtect
    End If
End If

    
coda:
Target.Select
With xlsheet
    .protect
    .EnableSelection = xlUnlockedCells
End With
noProtect:
With Application
    .EnableEvents = True
    .EnableSound = False
End With
    
End Sub


