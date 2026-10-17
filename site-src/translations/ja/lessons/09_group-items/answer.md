---
_translated_from: lessons/09_group-items/answer.md
_translated_by: site-src/translation agent
---
# 第 09 課変更演習：解答例

`WS-ACCOUNT-NUMBER` の初期値を `VALUE "0007654321".` に変更し、再コンパイルして実行します。

```sh
cobc -x -Wall -o build/lesson_09 lesson.cob && ./build/lesson_09
```

標準出力では次の3行だけが変化し、終了コードは `0` です。

```text
口座番号=0007654321
グループデータ=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
外部記録=[C0001042ADA LOVELACE0007654321ATXN-00000001D0012550PENDING]
```

口座番号は58バイトのレコードの21〜30バイトにあります（先行する `8+12` バイトの後）。この10文字だけを置き換えるため、幅と宣言順は変わらず、2つのグループ出力が同じように変化します。全長は58バイトのままです。
