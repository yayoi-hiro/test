Dim path

' 選択文字列でパスを開く
'path = Editor.GetSelectedString()

' カーソルのある行でパスを開く
path = Editor.GetLineStr(0)

If path = "" Then
    MsgBox "パスが選択されていません"
    WScript.Quit 1
End If

Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")

' ダブルクォートと改行除去
path = Replace(path, """", "")
path = Replace(path, vbCrLf, "")

If fso.FileExists(path) Then
    'path = fso.GetParentFolderName(path)
    CreateObject("WScript.Shell").Run "explorer /select,""" & path & """"
ElseIf fso.FolderExists(path) Then
    CreateObject("WScript.Shell").Run "explorer """ & path & """"
Else
    MsgBox "ファイルまたはフォルダが存在しません" & vbCrLf & path
    WScript.Quit 1
End If
