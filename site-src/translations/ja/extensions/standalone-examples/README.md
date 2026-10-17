# 独立したCOBOLの例

これらの例は、32課の主課程とは独立して読んで実行できます。まず対応する主課程を学び、その後、特定のテーマの演習として利用することをおすすめします。

| 例 | 対応する課 | 演習テーマ |
|---|---|---|
| `INPUTCSV.COB` | 第18、23課 | `UNSTRING`、Copybook、CSV出力 |
| `FIXEDREC.COB` | 第10、17課 | 固定長レコード、`REDEFINES`、状態検証 |
| `TBLSRCH.COB` | 第11、13課 | `OCCURS`、`SEARCH ALL` |
| `BATCHRPT.COB` | 第22、32課 | ソート済み入力、制御ブレーク、監査レポート |

このディレクトリから実行します。

```sh
make check
make run
make clean
```
