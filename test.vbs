Sub CreateExcels()

    Application.ScreenUpdating = False   ' 画面更新停止
    Application.Calculation = xlCalculationManual ' 自動計算OFF
    Application.EnableEvents = False    ' イベント停止
    
    Dim folderPath As String
    Dim fileName As String
    Dim target As String

    folderPath = "C:\Users\admin\Desktop\result.files\"

    fileName = Dir(folderPath & "*.html")   ' 最初の1件

    Do While fileName <> ""

        ' Debug.Print fileName
        target = folderPath & fileName
        GetDataFromHtml target
        
        fileName = Dir()       ' 次のファイル
    Loop
    
    ' GetDataFromHtml "C:\Users\miyuj\Desktop\result.files\0_file_list.txt.html"

    Application.ScreenUpdating = True
    Application.Calculation = xlCalculationAutomatic
    Application.EnableEvents = True

End Sub



Sub GetDataFromHtml(targetHtml As String)
    Dim wbFrom As Workbook
    Dim wbTo As Workbook

    Set wbFrom = Workbooks.Open(targetHtml)
    Set wbTo = Workbooks.Open("C:\Users\miyuj\Desktop\ex\forHTML.xlsx")
    
    Dim lastRow As Long
    Dim v As Variant
    Dim savePath As String
    
    With wbFrom.Sheets(1)
        lastRow = .Cells(.Rows.Count, 4).End(xlUp).Row
        .Range(.Cells(2, 4), .Cells(lastRow, 4)).Copy
    End With
    
    With wbTo.Sheets(1).Cells(3, 2)
        .PasteSpecial xlPasteValues
        .PasteSpecial xlPasteFormats
    End With
    
    Application.CutCopyMode = False
    
    Dim p As Long
    p = InStrRev(targetHtml, "\")

    If p > 0 Then
        targetHtml = Mid(targetHtml, p + 1)
    End If
    
    p = InStrRev(targetHtml, ".")   ' 後ろから . を探す

    If p > 0 Then
        targetHtml = Left(targetHtml, p - 1)
    End If
    
    ' Debug.Print targetHtml
    
    savePath = "C:\Users\miyuj\Desktop\ex\" & targetHtml & ".xlsx"

    wbFrom.Close SaveChanges:=False
    wbTo.SaveAs savePath
    wbTo.Close SaveChanges:=False
    


End Sub

