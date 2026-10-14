      * Lesson 08: run a small fixed-data account transaction batch.
      * 第 08 课：运行小型固定数据帐户交易批次。
      * レッスン 08: 小規模な固定データ アカウントのトランザクション バッチを実行します。
      * This lesson combines fields, math, IF, EVALUATE, and PERFORM.
      * 本课程结合了领域、数学、IF、EVALUATE 和 PERFORM。
      * このレッスンでは、フィールド、数学、IF、EVALUATE、および PERFORM を組み合わせます。
      * Named paragraphs separate setup, processing, and reporting.
      * 命名段落将设置、处理和报告分开。
      * 名前付き段落は、セットアップ、処理、レポートを分離します。
      * Five fixed transactions exercise accepted and rejected paths.
      * 五个固定交易执行接受和拒绝路径。
      * 5 つの固定トランザクションは、承認されたパスと拒否されたパスを実行します。
      * No file, database, table, or terminal input is used here.
      * 这里不使用文件、数据库、表或终端输入。
      * ここでは、ファイル、データベース、テーブル、または端末入力は使用されません。
      * D credits the balance; W debits it when funds are sufficient.
      * D 贷记余额；当资金充足时，W 将其记入借方。
      * D は残高を入金します。資金が十分にある場合は、W から借方に記入されます。
      * Other transaction codes are rejected for review.
      * 其他交易代码不予审核。
      * 他のトランザクション コードはレビューのために拒否されます。
      * All amounts use two fractional positions for this example.
      * 在此示例中，所有金额均使用两个小数位置。
      * この例では、すべての金額に 2 つの小数点以下の位置が使用されます。
      * This is a learning batch, not a production ledger system.
      * 这是一个学习批次，而不是生产分类帐系统。
      * これは学習バッチであり、生産台帳システムではありません。
      * Its input and output remain deterministic across runs.
      * 它的输入和输出在运行过程中保持确定性。
      * その入力と出力は実行全体にわたって決定的なままです。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH08.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Initial account balance before processing the sample batch.
      * 处理样本批次之前的初始帐户余额。
      * サンプルバッチを処理する前の初期アカウント残高。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-CURRENT-BALANCE PIC 9(7)V99 VALUE ZERO.
      * Sample index and last index control the inline PERFORM loop.
      * 样本索引和最后一个索引控制内联 PERFORM 循环。
      * サンプル インデックスと最後のインデックスは、インライン PERFORM ループを制御します。
       01 WS-SAMPLE-INDEX PIC 9(3) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
      * The current sample code and amount are loaded on each pass.
      * 当前的示例代码和数量会在每次传递时加载。
      * 現在のサンプル コードと量は各パスでロードされます。
       01 WS-TRANSACTION-CODE PIC X VALUE SPACE.
       01 WS-TRANSACTION-AMOUNT PIC S9(5)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE ZERO.
      * Counters distinguish processed, accepted, and rejected records.
      * 计数器区分已处理、已接受和已拒绝的记录。
      * カウンタは、処理されたレコード、受け入れられたレコード、および拒否されたレコードを区別します。
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main calls the three batch stages in dependency order.
      * Main 按依赖顺序调用三个批处理阶段。
      * Main は 3 つのバッチ ステージを依存関係の順序で呼び出します。
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-BATCH
           PERFORM 9000-REPORT
           STOP RUN.
      * Initialize shared balance and counters before processing.
      * 在处理之前初始化共享余额和计数器。
      * 処理前に共有残高とカウンターを初期化します。
       1000-INITIALIZE.
           MOVE WS-OPENING-BALANCE TO WS-CURRENT-BALANCE
           MOVE ZERO TO WS-PROCESSED-COUNT
           MOVE ZERO TO WS-ACCEPTED-COUNT
           MOVE ZERO TO WS-REJECTED-COUNT
           DISPLAY "BATCH=START"
           DISPLAY "OPENING-BALANCE=" WS-OPENING-BALANCE.
      * Process each fixed record in sequence using its sample number.
      * 使用样本编号按顺序处理每个固定记录。
      * 各固定レコードをサンプル番号を使用して順番に処理します。
       2000-PROCESS-BATCH.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-LOAD-SAMPLE
               PERFORM 2200-CLASSIFY-AND-POST
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM.
      * Load the code and amount associated with each sample number.
      * 加载与每个样品编号相关的代码和数量。
      * 各サンプル番号に関連付けられたコードと量をロードします。
       2100-LOAD-SAMPLE.
           EVALUATE WS-SAMPLE-INDEX
               WHEN 1
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE 125.50 TO WS-TRANSACTION-AMOUNT
               WHEN 2
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 40.10 TO WS-TRANSACTION-AMOUNT
               WHEN 3
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 1500.00 TO WS-TRANSACTION-AMOUNT
               WHEN 4
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE -5.00 TO WS-TRANSACTION-AMOUNT
               WHEN 5
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE 25.00 TO WS-TRANSACTION-AMOUNT
               WHEN OTHER
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE ZERO TO WS-TRANSACTION-AMOUNT
           END-EVALUATE
           DISPLAY "RECORD=" WS-SAMPLE-INDEX
               " CODE=" WS-TRANSACTION-CODE
               " AMOUNT=" WS-TRANSACTION-AMOUNT.
      * Classify the current record and apply only accepted amounts.
      * 对当前记录进行分类并仅应用接受的金额。
      * 現在の記録を分類し、承認された金額のみを適用します。
       2200-CLASSIFY-AND-POST.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       COMPUTE WS-CURRENT-BALANCE =
                           WS-CURRENT-BALANCE
                               + WS-TRANSACTION-AMOUNT
                       COMPUTE WS-ACCEPTED-COUNT =
                           WS-ACCEPTED-COUNT + 1
                       DISPLAY "RESULT=ACCEPTED REASON=DEPOSIT"
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "RESULT=REJECTED"
                           " REASON=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN "W"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       IF WS-TRANSACTION-AMOUNT
                           <= WS-CURRENT-BALANCE
                           COMPUTE WS-CURRENT-BALANCE =
                               WS-CURRENT-BALANCE
                                   - WS-TRANSACTION-AMOUNT
                           COMPUTE WS-ACCEPTED-COUNT =
                               WS-ACCEPTED-COUNT + 1
                           DISPLAY "RESULT=ACCEPTED"
                               " REASON=WITHDRAWAL"
                       ELSE
                           COMPUTE WS-REJECTED-COUNT =
                               WS-REJECTED-COUNT + 1
                           DISPLAY "RESULT=REJECTED"
                               " REASON=INSUFFICIENT_FUNDS"
                       END-IF
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "RESULT=REJECTED"
                           " REASON=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN OTHER
                   COMPUTE WS-REJECTED-COUNT =
                       WS-REJECTED-COUNT + 1
                   DISPLAY "RESULT=REJECTED"
                       " REASON=UNKNOWN_TRANSACTION_CODE"
           END-EVALUATE.
      * Report totals and the balance after the complete sample batch.
      * 完成样品批次后报告总计和余额。
      * 完全なサンプルバッチ後の合計と残高を報告します。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT
           DISPLAY "ACCEPTED=" WS-ACCEPTED-COUNT
           DISPLAY "REJECTED=" WS-REJECTED-COUNT
           DISPLAY "FINAL-BALANCE=" WS-CURRENT-BALANCE.
      * The main paragraph is the program's only entry sequence.
      * 主要段落是程序唯一的输入序列。
      * メイン段落は、プログラムの唯一のエントリ シーケンスです。
      * Each PERFORM returns to the statement after its paragraph call.
      * 每个 PERFORM 返回到其段落调用之后的语句。
      * 各 PERFORM は、段落呼び出しの後にステートメントに戻ります。
      * The process paragraph uses PERFORM VARYING for record iteration.
      * 该流程段落使用 PERFORM VARYING 进行记录迭代。
      * プロセス段落では、レコードの反復に PERFORM VARYING を使用します。
      * The load paragraph separates fixed data from business rules.
      * 加载段落将固定数据与业务规则分开。
      * ロード段落は、固定データをビジネス ルールから分離します。
      * EVALUATE maps the sample index to its fixed code and amount.
      * EVALUATE 将样本索引映射到其固定代码和数量。
      * EVALUATE は、サンプル インデックスをその固定コードと量にマッピングします。
      * A second EVALUATE selects deposit, withdrawal, or unknown logic.
      * 第二个 EVALUATE 选择存款、取款或未知逻辑。
      * 2 番目の EVALUATE では、入金、出金、または不明なロジックを選択します。
      * IF checks positive amount and available funds before posting.
      * IF 在过账前检查正金额和可用资金。
      * IF は、転記前にプラスの金額と利用可能な資金をチェックします。
      * Rejected records increase the count and leave balance unchanged.
      * 被拒绝的记录会增加计数并保持余额不变。
      * 拒否されたレコードの数は増加し、残高は変更されません。
      * Accepted records change the balance and accepted count together.
      * 已接受的记录会同时更改余额和已接受的计数。
      * 受け入れられたレコードは残高と受け入れられた数を一緒に変更します。
      * The processed count increases once after each complete record.
      * 每完成一条记录后，处理的计数就会增加一次。
      * 処理された数は、レコードが完了するたびに 1 回増加します。
      * Five records produce two accepted and three rejected outcomes.
      * 五个记录产生两个接受的结果和三个拒绝的结果。
      * 5 つのレコードから、2 つの承認結果と 3 つの拒否結果が生成されます。
      * The credit raises balance from 1000.00 to 1125.50.
      * 信贷将余额从 1000.00 提高到 1125.50。
      * クレジットにより残高が 1000.00 から 1125.50 に増加します。
      * The valid withdrawal lowers balance to 1085.40.
      * 有效提款使余额降至 1085.40。
      * 有効な引き出しにより、残高は 1085.40 まで下がります。
      * Oversized withdrawals are rejected without changing balance.
      * 巨额提款将被拒绝，且余额不会改变。
      * 過剰な出金は残高を変更せずに拒否されます。
      * The negative deposit is rejected before the balance is changed.
      * 在余额更改之前，负存款将被拒绝。
      * マイナスのデポジットは、残高が変更される前に拒否されます。
      * The unknown code is rejected without posting its amount.
      * 未知代码被拒绝，且未公布其金额。
      * 不明なコードは金額を通知せずに拒否されます。
      * Counters report record outcomes, not accounting entries.
      * 计数器报告记录结果，而不是会计分录。
      * カウンタは会計エントリではなく、記録の結果を報告します。
      * Initialization precedes every transaction-processing step.
      * 初始化在每个事务处理步骤之前进行。
      * 初期化は、すべてのトランザクション処理ステップの前に行われます。
      * The report reads shared totals after processing returns.
      * 处理退货后，报告会读取共享总计。
      * レポートは、処理が返された後に共有合計を読み取ります。
      * Periods end each paragraph's final sentence.
      * 每个段落的最后一句话都以句号结束。
      * 各段落の最後の文はピリオドで終わります。
      * EVALUATE embeds samples until the table lesson.
      * EVALUATE 嵌入示例直到表格课程。
      * EVALUATE は、テーブル レッスンまでサンプルを埋め込みます。
      * Later lessons store samples in reusable data structures.
      * 后面的课程将样本存储在可重用的数据结构中。
      * 後のレッスンでは、サンプルを再利用可能なデータ構造に保存します。
      * Production batches also need file status and restart handling.
      * 生产批次还需要文件状态和重新启动处理。
      * 実稼働バッチには、ファイル ステータスと再起動処理も必要です。
      * Define production rules for concurrency and idempotency.
      * 定义并发性和幂等性的生产规则。
      * 同時実行性と冪等性の運用ルールを定義します。
      * STOP RUN ends this integrated language-basics example.
      * STOP RUN 结束这个集成的语言基础示例。
      * STOP RUN は、この統合された言語の基本の例を終了します。
