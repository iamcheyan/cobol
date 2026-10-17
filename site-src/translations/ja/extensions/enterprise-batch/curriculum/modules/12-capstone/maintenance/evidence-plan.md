# Evidence 計画

各テストの期待値と証拠の場所を示します。証拠は `maintenance/regression/red-green.sh` と `scripts/check.py` が実際に生成するものであり、合格結果を事前に記入してはいけません。

| テスト | 期待値 | 証拠の場所 |
|---|---|---|
| T1 正常 v1 | RC0；`A1` | `check.py check_day("normal","v1",0)` の出力 |
| T2 正常 v2 | RC0；`D1` を含む | `check.py check_day("extension","v2",0)` |
| T3 異常日 | RC4、公開 | `check.py check_day("abnormal","v1",4)` |
| T5 幅 guard | RC8、公開なし | `check.py check_layout_guard()` |
| T7 バージョン跨ぎ | GREEN | `maintenance/regression/red-green.sh` の `GREEN=0` |
| T8 4 種類の日 | 各ケースの RC | `check.py` の4日分のアサーション |
| T9 復旧 | 台帳 6 行、残高不変 | `check.py check_recovery()/check_rerun_idempotent()` |
| T10 安全な変更 | 元入力が未変更 | `check.py` の fixture SHA 不変アサーション |
| バイト解釈 | 27/31/32/47/55 バイト | `system/copybooks/*` + `validate.py length` |
| 事故 | 根本原因を再現可能 | `incidents/incident-01/reproduce/reproduce.sh` の `reproduce_rc=8` |

証拠ファイルには、バージョン、コンパイラーのバージョン、営業日、run_id、コマンド、元の RC、入力/出力チェックサム、照合表、結論、制約を含めてください。
