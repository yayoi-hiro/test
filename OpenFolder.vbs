Dim path
path = Editor.GetSelectedString()

If path = "" Then
    MsgBox "パスが選択されていません"
    WScript.Quit
End If

Dim fso
Set fso = CreateObject("Scripting.FileSystemObject")

' ダブルクォート除去
path = Replace(path, """", "")

If fso.FileExists(path) Then
    'path = fso.GetParentFolderName(path)
ElseIf fso.FolderExists(path) Then
Else
    MsgBox "ファイルまたはフォルダが存在しません"
    WScript.Quit
End If

CreateObject("WScript.Shell").Run "explorer /select,""" & path & """"