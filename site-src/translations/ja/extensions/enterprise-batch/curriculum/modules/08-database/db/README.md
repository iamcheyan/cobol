# db：schema、seed、reset、ツールイメージ

| ファイル | 役割 |
|---|---|
| `schema.sql` | `schema_version=001`のDDL（再実行可能。先にDROPしCREATE） |
| `seed.sql` | 合成顧客/口座/probeデータ（実データや認証情報なし） |
| `reset.sql` | schemaを保持して業務テーブルを消去。実行中コースDBのリセット用 |
| `Dockerfile` | ESQLツールイメージ（P1の固定GixSQL commitと2つのローカルpatchを再利用） |

## ビルドと実行

```bash
lab=$(cd curriculum/modules/08-database && pwd)
bash "$lab/scripts/docker-image.sh"       # cobol-course-gixsql:m08を生成/再利用
```

`Dockerfile`は`gixsql-cursor-null.patch`と`gixsql-closed-cursor.patch`を参照します。この2つはP1の`curriculum/validation/database/`由来で、`scripts/docker-image.sh`が一時build contextへコピーします（**P1ファイルは変更しません**）。モジュール08のCOBOLとDB実験はこのイメージ内で実行します。

## 実行中コースDBを手動でリセット

```bash
PGHOST=… PGPORT=5432 PGUSER=postgres psql_dsn bash "$lab/scripts/reset.sh" --db
# または明示的に：
psql -v ON_ERROR_STOP=1 -f "$lab/db/schema.sql"
psql -v ON_ERROR_STOP=1 -f "$lab/db/seed.sql"
```

自動実験は使い捨てコンテナを利用し、終了時に削除します。このディレクトリのreset scriptは明示指定されたコースDBだけに作用します。
