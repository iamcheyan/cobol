# COBOLの知識マップとステップアップの道筋

本課は、全29テーマを網羅するためのコース目録の索引です。これまでのテーマを、GNUCOBOL開発の全体像の中に位置づけるのに役立ちます。COBOLは標準規格、歴史的な方言、ベンダー拡張の範囲が広いため、以下では中核となるバッチ処理のコースと、個別の環境が必要なテーマを明確に区別しています。使用頻度の低いキーワードやIBM独自の環境を、実際に操作した内容であるかのようには扱いません。

## 中核となる言語知識マップ

| 知識領域 | 知識項目 | 対応するコース |
|---|---|---|
| プログラム構成 | IDENTIFICATION / ENVIRONMENT / DATA / PROCEDURE DIVISION；SECTION、Paragraph、ピリオドとスコープ終端子 | [01](../01-program-anatomy/)、[02](../02-source-format/) |
| ソースコードの規則 | 固定形式、自由形式、Area A/B、標識領域、コメント、継続行、コンパイラの桁数制限 | [02](../02-source-format/) |
| 識別子 | ユーザー名、予約語、命名規則、リテラル、文字列の引用符、コメント | [03](../03-names-comments-literals/) |
| データ階層 | 01–49、66 RENAMES、77、78定数、88条件名；グループ項目と基本項目；WORKING-STORAGE / LOCAL-STORAGE / LINKAGE | [04](../04-data-hierarchy/)、[07](../07-conditions-88/) |
| データ記述 | PIC記号 X/A/9/V/S/P、編集記号、VALUE、JUSTIFIED、SIGN、USAGE DISPLAY/COMP/COMP-3；REDEFINES；OCCURS / OCCURS DEPENDING ON；SYNCHRONIZED | [05](../05-picture-storage/)、[10](../10-tables-occurs-search/)、[14](../14-copybooks-redefines/) |
| データ操作 | MOVE、INITIALIZE、SET、CORRESPONDING、算術動詞、COMPUTE、ROUNDED、ON SIZE ERROR | [06](../06-values-move-arithmetic/)、[07](../07-conditions-88/) |
| 制御フロー | IF/ELSE、EVALUATE、PERFORM、ループ、インラインPERFORM、EXIT PERFORM、段落呼び出し | [08](../08-branching-evaluate/)、[09](../09-loops-perform/) |
| テーブル | OCCURS、添字、INDEXED BY、SEARCH、SEARCH ALL、ソートの前提条件と境界 | [10](../10-tables-occurs-search/)、[18](../18-sort-merge/) |
| 文字列 | STRING、UNSTRING、INSPECT、DELIMITED BY、TALLYING、WITH POINTER、参照変更 | [11](../11-strings-unstring-inspect/) |
| ファイル処理 | SELECT、ASSIGN、FD/SD、OPEN、READ、WRITE、REWRITE、DELETE、CLOSE、ファイル状態、順編成／行順編成／相対編成／索引編成 | [12](../12-sequential-files/)、[13](../13-file-status-errors/) |
| モジュール化 | COPY、Copybook、COPY REPLACING、REDEFINES、CALL、CANCEL、LINKAGE、BY REFERENCE/CONTENT/VALUE、RETURNING | [14](../14-copybooks-redefines/)、[15](../15-subprograms-linkage/) |
| 組み込み関数 | TRIM、LENGTH、NUMVAL、CURRENT-DATE、日付／整数／数値関数と入力変換の検証 | [16](../16-intrinsic-functions-dates/) |
| バッチ業務処理 | コントロールブレイク、小計／総計、レポート、SORT/MERGE、エラーカウント、ジョブ終了コード | [17](../17-reports-control-break/)、[18](../18-sort-merge/)、[25](../25-project-csv-pipeline/)、[26](../26-project-fixed-records/) |
| 開発品質 | コンパイル方言、警告、診断、デバッグ、ビルド依存関係、テスト用フィクスチャ、ログ、冪等なジョブ | [19](../19-modules-environment/)、[20](../20-debugging-diagnostics/)、[21](../21-compiler-options/)、[22](../22-bash-build-run/)、[23](../23-bash-tests-batch/)、[24](../24-bash-pipelines-scheduling/) |

## 個別のコースが必要なGnuCOBOLのテーマ

これらの機能は、使用する端末、外部データベースやプロトコル、コンパイルとビルドの方法、利用シーンに依存します。まず中核コースを修了し、その後、GnuCOBOL Programmer's Guideとローカル環境の`cobc --help`を参照して、対象プロジェクトのバージョンに合わせて学習してください。

- **ACCEPT / DISPLAYの拡張機能**：コマンドライン引数、環境変数、標準入力、端末属性、戻り値。
- **SORT/MERGEの実践**：SD作業ファイル、入力／出力手続き、一時ディレクトリ、大規模データセットのリソース方針。
- **相対編成ファイルと索引編成ファイル**：キー定義、INVALID KEY、ロック、並行アクセス。ファイルシステムの動作は実機で検証する必要があります。
- **画面節（SCREEN SECTION）**：対話型端末での入出力。純粋なバックグラウンドバッチプログラムには適しません。
- **レポート作成機能（REPORT SECTION）**：レポートのページ制御と旧式実行環境との互換性。
- **呼び出し規約とリンク**：静的／動的呼び出し、共有ライブラリ、Cインターフェース、ABI、デプロイ時の依存関係。
- **SQL／組み込みデータベース**：対応するデータベースクライアント、プリコンパイラ、またはGnuCOBOL統合モジュールが必要です。基本の`cobc`環境では標準機能として利用できません。
- **XML／JSON／sockets／CGI／GUI**：GnuCOBOLライブラリ、外部プログラム、またはプラットフォーム拡張を通じて実現します。まず対象環境のモジュールとライセンスを確認してください。
- **オブジェクト指向COBOLと現代標準との違い**：コンパイラの実装と対象ランタイムに依存します。特定ベンダーの大型機方言を、GnuCOBOL共通の構文として扱わないでください。
- **国際化、文字セット、ロケール**：UTF-8、EBCDIC、照合順序、decimal point、ロケールは、実際の入力と対象システムで検証する必要があります。
- **セキュリティと本番運用**：ファイル権限、パストラバーサル、一時ファイル、機密データのログ出力、並行制御、監査、再試行、冪等性。

## 次に取り組むこと

修了課題[28](../28-capstone-night-batch/)から実際のデータ処理フローを1つ選び、入出力契約と失敗パターンの一覧を作成してから、使用する発展テーマを追加してください。テーマを追加する際は、「個別ディレクトリ + 説明 + 固定形式のソースコード + コンパイル／実行コマンド + 改変演習 + プラグイン演習」というコース構成に沿ってください。
