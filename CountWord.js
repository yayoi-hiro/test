if (!IsTextSelected()) {
    Editor.InfoMsg("文字列を選択してください。");
}
else {

    var word = GetSelectedString(0);

    // 前回の検索マークを消す
    SearchClearMark();

    // 文頭へ移動
    GoFileTop();

    // 検索マークを付ける
    // 0x0002 : 大文字・小文字を区別
    // 0x0010 : 検索ダイアログを閉じる
    // 0x0020 : 先頭から再検索
    // 0x0800 : 検索履歴に登録しない
    SearchNext(word, 0x0832);

    // 出現回数を数える
    var count = 0;

    for (var i = 1; i <= GetLineCount(0); i++) {
        var line = GetLineStr(i);

        var pos = 0;
        while ((pos = line.indexOf(word, pos)) != -1) {
            count++;
            pos += word.length;
        }
    }

    Editor.InfoMsg("「" + word + "」は " + count + " 件見つかりました。");
}