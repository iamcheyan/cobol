       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
      * This program coordinates the complete reconciliation batch.
      * 中文：此程序协调完整的对账批次。
      * 日本語：このプログラムは照合バッチ全体を統括する。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The worker modules share these exact record and counter layouts.
      * 中文：工作模块共享这些完全一致的记录和计数器布局。
      * 日本語：ワーカーモジュールはこれらと同一のレコードおよびカウンター構成を共有する。
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * Reset the account table, counters and worker error flag.
      * 中文：重置账户表、计数器和工作模块错误标志。
      * 日本語：口座テーブル、カウンター、ワーカーエラーフラグをリセットする。
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
      * Read the account master and apply the transaction stream.
      * 中文：读取账户主数据并应用交易流。
      * 日本語：口座マスターを読み込み、取引ストリームを適用する。
      * The posting module owns both input files and business rules.
      * 中文：记账模块负责两个输入文件和业务规则。
      * 日本語：記帳モジュールが2つの入力ファイルと業務ルールを管理する。
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * Do not sync a partial account table after a file failure.
      * 中文：文件故障后不要同步不完整的账户表。
      * 日本語：ファイル障害後に不完全な口座テーブルを同期しない。
           IF WS-FAILED NOT = "Y"
      * The sync module owns SQLite, the report and database status.
      * 中文：同步模块负责 SQLite、报表和数据库状态。
      * 日本語：同期モジュールが SQLite、レポート、データベース状態を管理する。
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
      * Validate batch arithmetic before reporting final counters.
      * 中文：报告最终计数前先验证批次算术关系。
      * 日本語：最終カウンターを報告する前にバッチの計算整合性を検証する。
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
      * Business rejects count as rejects, not system failures.
      * 中文：业务拒绝计为拒绝记录，不计为系统故障。
      * 日本語：業務上の拒否は拒否件数に数え、システム障害とはしない。
           DISPLAY "SUMMARY ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TX=" WS-TRANSACTION-COUNT
                   " POSTED=" WS-POSTED-COUNT
                   " REJECTED=" WS-REJECTED-COUNT
                   " UPDATED=" WS-UPDATED-COUNT
                   " UNCHANGED=" WS-UNCHANGED-COUNT
                   " INSERTED=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
      * The shell receives a nonzero status only for a system failure.
      * 中文：只有发生系统故障时，shell 才会收到非零状态。
      * 日本語：システム障害の場合に限り、シェルにゼロ以外のステータスを返す。
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
      * Every read transaction must be either posted or rejected.
      * 中文：每笔读取的交易都必须记账或拒绝。
      * 日本語：読み込んだ各取引は記帳または拒否のいずれかに分類する。
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "ERROR=TRANSACTION COUNT MISMATCH"
               MOVE "Y" TO WS-FAILED
           END-IF
      * A successful sync classifies every loaded account exactly once.
      * 中文：同步成功时，每个已加载账户都恰好归类一次。
      * 日本語：同期が成功すると、読み込んだ各口座をちょうど1回分類する。
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "ERROR=SYNC COUNT MISMATCH"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      * LOADPOST32 reads fixed 27- and 20-character records.
      * 中文：LOADPOST32 读取固定长度为 27 和 20 个字符的记录。
      * 日本語：LOADPOST32 は27文字および20文字の固定長レコードを読み込む。
      * Amount fields contain integer cents with an implied decimal.
      * 中文：金额字段保存整数分，隐含小数点。
      * 日本語：金額項目には暗黙の小数点を持つ整数セントを格納する。
      * The worker keeps at most twenty accounts in the shared table.
      * 中文：工作模块在共享表中最多保存二十个账户。
      * 日本語：ワーカーは共有テーブルに最大20口座を保持する。
      * Duplicate account keys fail before posting begins.
      * 中文：重复账户键会在记账开始前导致失败。
      * 日本語：口座キーが重複していると、記帳開始前に失敗する。
      * Deposits and permitted withdrawals update the table.
      * 中文：存款和允许的取款会更新此表。
      * 日本語：入金と許可された出金によってテーブルを更新する。
      * Overdrafts and unknown types or accounts are business rejects.
      * 中文：透支以及未知交易类型或账户均属于业务拒绝。
      * 日本語：残高不足、未知の取引種別や口座は業務上の拒否となる。
      * Business rejects do not change the final account balance.
      * 中文：业务拒绝不会改变最终账户余额。
      * 日本語：業務上の拒否では最終的な口座残高は変わらない。
      * Accepted and rejected records use separate sequential files.
      * 中文：接受和拒绝的记录分别写入不同的顺序文件。
      * 日本語：受理レコードと拒否レコードは別々の順編成ファイルに書き込む。
      * The batch log records each transaction decision.
      * 中文：批次日志记录每笔交易的判定结果。
      * 日本語：バッチログに各取引の判定を記録する。
      * SYNCDB32 looks up the final account by its primary key.
      * 中文：SYNCDB32 根据主键查询最终账户。
      * 日本語：SYNCDB32 は主キーで最終口座を検索する。
      * A matching database balance is reported as UNCHANGED.
      * 中文：数据库余额相同时，报告为 UNCHANGED。
      * 日本語：データベース残高が一致すれば UNCHANGED と報告する。
      * A different balance is updated to the computed file result.
      * 中文：余额不同时，会更新为根据文件计算出的结果。
      * 日本語：残高が異なる場合は、ファイルから計算した結果に更新する。
      * A missing database key is inserted from the account master.
      * 中文：数据库中不存在该键时，从账户主数据插入记录。
      * 日本語：データベースにキーがない場合、口座マスターから挿入する。
      * The report states the decision made for every loaded account.
      * 中文：报表说明对每个已加载账户作出的判定。
      * 日本語：レポートに読み込んだ各口座への判定を記載する。
      * On rerun with identical inputs, the final balances converge.
      * 中文：使用相同输入重新运行时，最终余额会收敛到相同结果。
      * 日本語：同じ入力で再実行すると、最終残高は同じ結果に収束する。
      * Replaying the input starts from its declared opening balances.
      * 中文：重放输入时，会从其中声明的期初余额开始。
      * 日本語：入力を再処理する際は、宣言された開始残高から始める。
      * It therefore does not apply a deposit twice to database state.
      * 中文：因此，不会将同一笔存款重复应用到账户数据库状态。
      * 日本語：したがって、データベース状態に入金を二重適用しない。
      * Outputs and database changes do not share an atomic transaction.
      * 中文：输出文件与数据库更改不属于同一原子事务。
      * 日本語：出力とデータベース変更は単一の原子トランザクションではない。
      * The run script seeds a reproducible SQLite starting database.
      * 中文：运行脚本会创建可复现的 SQLite 初始数据库。
      * 日本語：実行スクリプトは再現可能な SQLite 初期データベースを用意する。
      * The run-existing action checks deterministic restart behavior.
      * 中文：运行现有数据操作用于检查确定性的重启行为。
      * 日本語：既存データでの実行操作により、決定的な再起動動作を確認する。
      * A production batch would add a durable batch identifier.
      * 中文：生产批次会添加持久化的批次标识符。
      * 日本語：本番バッチでは永続的なバッチ識別子を追加する。
      * It would also define a transaction commit and recovery protocol.
      * 中文：还会定义事务提交和恢复协议。
      * 日本語：さらにトランザクションのコミットおよび復旧プロトコルを定める。
      * Those boundaries are documented instead of being simulated here.
      * 中文：这些边界会在此处记录，而不进行模拟。
      * 日本語：ここではシミュレーションせず、これらの境界を文書化する。
      * Module calls use the shared Copybook layout by reference.
      * 中文：模块调用通过引用使用共享的 Copybook 布局。
      * 日本語：モジュール呼び出しでは共有 Copybook 構成を参照渡しで使用する。
      * This driver owns the final summary and process return status.
      * 中文：此驱动程序负责最终汇总和进程返回状态。
      * 日本語：このドライバーが最終集計とプロセスの戻りステータスを管理する。
      * The posting and sync modules own their own files and SQL work.
      * 中文：记账和同步模块分别管理自己的文件和 SQL 操作。
      * 日本語：記帳モジュールと同期モジュールは、それぞれのファイルと SQL 処理を管理する。
      * Additional design notes for this integrated batch.
      * 中文：此集成批次的补充设计说明。
      * 日本語：この統合バッチに関する追加の設計メモ。
      * The driver converts worker status to the process return code.
      * 中文：驱动程序将工作模块状态转换为进程返回码。
      * 日本語：ドライバーはワーカーの状態をプロセス戻りコードに変換する。
      * Workers receive these tables by reference and update shared state.
      * 工作模块通过引用接收这些表并更新共享状态。
      * 日本語：ワーカーは各テーブルを参照で受け取り、状態を更新する。
      * Each counter has a role in the batch arithmetic checks above.
      * 中文：每个计数器都用于上面的批次算术检查。
      * 日本語：各カウンターは上記のバッチ計算チェックで役割を持つ。
      * Posted and rejected counts partition the transaction input.
      * 中文：已记账和已拒绝计数共同划分全部交易输入。
      * 日本語：記帳件数と拒否件数で取引入力全体を区分する。
      * Sync counts classify every account after successful SQL work.
      * 中文：SQL 操作成功后，同步计数会对每个账户进行归类。
      * 日本語：SQL 処理の成功後、同期件数で各口座を分類する。
      * Amount text represents integer cents, not localized decimals.
      * 中文：金额文本表示整数分，而非本地化的小数格式。
      * 日本語：金額テキストは地域別小数表記ではなく、整数セントを表す。
      * The account lookup costs one scan for each input transaction.
      * 中文：每笔输入交易都需要扫描一次来查询账户。
      * 日本語：入力取引ごとに口座検索のスキャンが1回必要となる。
      * Larger masters need a deliberate table or indexed lookup design.
      * 中文：对于更大的主数据，需要专门设计表结构或索引查询方案。
      * 日本語：より大きなマスターには、テーブル設計または索引検索を計画する必要がある。
      * This sample caps master rows to keep memory use predictable.
      * 中文：此示例限制主数据行数，以便控制内存用量。
      * 日本語：このサンプルはメモリ使用量を予測可能にするため、マスター行数を制限する。
      * Rebuilds seed a clean database; reruns preserve database rows.
      * 中文：重建会创建干净数据库；重新运行则保留数据库记录。
      * 日本語：再構築では空のデータベースを用意し、再実行ではデータベース行を保持する。
      * Checks use temporary data so the lesson fixtures stay unchanged.
      * 中文：检查使用临时数据，因此课程样例数据保持不变。
      * 日本語：チェックでは一時データを使い、レッスンのフィクスチャを変更しない。
       END PROGRAM LESSON32.
