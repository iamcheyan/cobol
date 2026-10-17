# 07.1 SORT：取引ファイルの決定的なソート契約

## インターフェースと順序

入出力ともTRANSACTION v1です。1レコードはASCII 55バイト + LFで、LFは55バイトに含みません。入力業務日は引数で与え、各行をGregorian暦で検証します。口座、取引ID、日付、連番、方向（C/D）、13桁の符号なし金額（0は有効）、status（Nのみ）を検証します。IDはASCII大文字A–Zと0–9のみです。空入力は許可されます。空でないファイルの最終行はLF終端でなければなりません。最初に固定長PICへ読み込み、後から元の幅を推測してはいけません。

業務ソートキーは`(account_id 1–10, sequence_no 35–40, transaction_id 11–26)`で、全3要素が厳密昇順です。元の55フィールドバイトをすべて保持し、標準LFを出力します。sequenceが同じでもIDが異なれば有効で、`transaction_id`で順序を決めます。全体で重複する`transaction_id`（非隣接行や異なる口座を含む）は契約エラーRC8となり、公開しません。同一複合キーは必ず重複IDにも該当するため拒否されます。完全一致キーに対する実行時の安定性に依存しないでください。

手計算例：Z…001はsequence 000001、A…002とM…003はsequence 000002です。業務キー順の出力はZ…001、A…002、M…003です。辞書順ではsequence 1のZはsequence 2のAより後になりますが、業務順ではZが先でなければなりません。同一sequence内ではAがMより先です。これにより全行辞書順やIDだけのソートではないことも分かります。完全な例は`expected/normal.dat`を参照してください。

## プログラム境界とRC

COBOLのSD sort-workレコードはTRANSACTION-V1.CPYで構成します。SORTのINPUT PROCEDUREが1バイトずつ読み、検証してからRELEASEします。OUTPUT PROCEDUREはRETURN順に55バイトレコードを書きます。runnerは`COB_SORT_MEMORY`を明示設定し、GnuCOBOLの大きな128M poolを既定で継承しません。値は1M以上が必要です。ソートpoolを超えた作業領域はディスクにspillします。独立した外部cut/sortは全体transaction IDの一意性確認のみで、取引順序の生成には使いません。

| RC | 条件 | 公開 |
|---:|---|---|
| 0 | 入力契約有効、ID一意、SORT-RETURN=0、出力検証成功 | 原子的に公開 |
| 8 | 長さ/文字/フィールド/日付エラー、またはID重複 | なし |
| 12 | open/read/write/lock/build/一時work file/権限/予期しないSORT-RETURN/検証/公開の失敗 | なし |

検証器は出力ストリームのバイト、全キー昇順、入力フィールドの保持、入出力件数保存、ID一意性を確認します。候補stdoutや部分ファイルは正式成果物ではありません。SORTのwork file資源エラーは`SORT-RETURN`で確認し、RC12へ対応付けます。
