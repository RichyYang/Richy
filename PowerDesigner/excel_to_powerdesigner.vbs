Option Explicit

Dim mdl ' the current model
Set mdl = ActiveModel
If (mdl Is Nothing) Then
   MsgBox "There is no Active Model"
End If

Dim HaveExcel
Dim RQ
RQ = vbYes 'MsgBox("Is Excel Installed on your machine ?", vbYesNo + vbInformation, "Confirmation")
If RQ = vbYes Then
   HaveExcel = True
   ' Open & Create Excel Document
   Dim x1  '
   Set x1 = CreateObject("Excel.Application")
   x1.Workbooks.Open "E:/数据库结构.xls"
   x1.Workbooks(1).Worksheets("Sheet1").Activate
Else
   HaveExcel = False
End If

a x1, mdl

sub a(x1, mdl)
dim rwIndex
dim tableName
dim colname
dim table
dim col
dim count

on error Resume Next
For rwIndex = 2016 To 2015
        With x1.Workbooks(1).Worksheets("Sheet1")
            If .Cells(rwIndex, 1).Value = "" Then
               Exit For
            End If
            If .Cells(rwIndex, 3).Value = "" Then
               set table = mdl.Tables.CreateNew
               table.Name = .Cells(rwIndex + 1, 10).Value
               table.Code = .Cells(rwIndex + 1, 9).Value
               count = count + 1
            Else
               colName = .Cells(rwIndex, 1).Value
               set col = table.Columns.CreateNew
               'MsgBox .Cells(rwIndex, 1).Value, vbOK + vbInformation, "列"
               col.Name = .Cells(rwIndex, 1).Value
               'MsgBox col.Name, vbOK + vbInformation, "列"
               col.Code = .Cells(rwIndex, 3).Value
               
               if .Cells(rwIndex, 7).Value <> "" Then
                  col.Comment = "单位：" + .Cells(rwIndex, 7).Value + " 。  " + .Cells(rwIndex, 8).Value
               else
                  col.Comment = .Cells(rwIndex, 8).Value
               end if
               
               if .Cells(rwIndex, 2).Value = "Y" Then
                  col.Primary = true
               end if
               If .Cells(rwIndex, 4).Value = "C" Then
                  col.DataType = "NVARCHAR2(" + .Cells(rwIndex, 5).Value + ")"
               elseif .Cells(rwIndex, 4).Value = "D" Then
                  col.DataType = "DATE"
               elseif .Cells(rwIndex, 4).Value = "N" Then
                  if .Cells(rwIndex, 6).Value = "" Then
                     col.DataType = "NUMBER(" + .Cells(rwIndex, 5).Value + ")"
                  else
                     col.DataType = "NUMBER(" + .Cells(rwIndex, 5).Value + ", " + .Cells(rwIndex, 6).Value + ")"
                  end if
               end if
            End If
        End With
Next
MsgBox "生成数据表结构共计 " + CStr(count), vbOK + vbInformation, "表"

Exit Sub
End sub
