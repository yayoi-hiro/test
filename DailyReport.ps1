# 共通処理を読み込む
. "$PSScriptRoot\Common.ps1"

# Text        ：手順名（必須）
# Description ：補足説明（省略可）
# Action      ：「実行」ボタンの処理（省略可）

# Start-Process "C:\Work\DailyReport\手順.txt"
# Open-Folder "C:\Work\DailyReport"
# Open-Excel 


$Steps = @(
    @{
        Text = "資料フォルダを開く"
        Action = {
            Open-Folder "C:\Users\miyuj\Desktop\logput"
        }
    },
    @{
        Text = "日次報告Excelを開く"
        Description = "前日のデータをコピーして、本日の内容を入力します。`r`n入力後、内容に間違いがないことを確認してください。"
        Action = {
            Open-Excel "C:\Users\miyuj\Desktop\logput\ex\001_local項目.xlsx"
        }
    },
   @{
        Text = "Excelの編集・確認が完了した"
    },
    @{
        Text = "メールを作成する"
        Description = "メールを送信"
        Action = {
            Create-Mail `
                "日次報告" `
                "お疲れ様です。`r`n`r`n本日の日次報告です。`r`n`r`nよろしくお願いいたします。"
        }
    },
    @{
        Text = "メールの内容・添付ファイルを確認した"
        Action = { Start-Process "C:\Users\miyuj\Desktop\logput\comb2.txt" }
    },
    @{
        Text = "メールを送信した"
    }
)

Show-Flow -Title "日次報告" -Steps $Steps