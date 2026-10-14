      * Lesson 11: store a small batch in an OCCURS table.
      * 第 11 课：在 OCCURS 表中存储一小批数据。
      * レッスン 11: 小さなバッチを OCCURS テーブルに保存します。
      * OCCURS creates a fixed number of repeated data entries.
      * OCCURS 创建固定数量的重复数据条目。
      * OCCURS は、固定数の繰り返しデータ エントリを作成します。
      * A group entry repeats all of its subordinate elementary items.
      * 组条目重复其所有从属基本项目。
      * グループエントリは、その下位の基本項目をすべて繰り返します。
      * Numeric subscripts in parentheses select one table occurrence.
      * 括号中的数字下标选择表中的一个匹配项。
      * 括弧内の数値添字は、1 つのテーブルオカレンスを選択します。
      * This lesson uses an ordinary numeric subscript, not an index.
      * 本课程使用普通的数字下标，而不是索引。
      * このレッスンでは、インデックスではなく、通常の数値添字を使用します。
      * Table bound is four; the loop visits entries 1 through 4.
      * 表界为四；循环访问条目 1 到 4。
      * テーブルバインドは 4 つです。ループはエントリ 1 ～ 4 を訪問します。
      * Credits increase the sample balance and debits reduce it.
      * 贷方增加样本余额，借方减少样本余额。
      * 貸方ではサンプル残高が増加し、借方ではサンプル残高が減少します。
      * An unknown code is displayed and leaves the balance unchanged.
      * 显示未知代码并且余额保持不变。
      * 不明なコードが表示され、残高は変更されません。
      * Table data is loaded with MOVE before it is processed.
      * 表数据在处理之前使用 MOVE 加载。
      * テーブル データは、処理される前に MOVE でロードされます。
      * No file, external input, or dynamic table is used here.
      * 这里不使用文件、外部输入或动态表。
      * ここでは、ファイル、外部入力、または動的テーブルは使用されません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. OCCURS11.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Each 05 entry repeats a code and a two-decimal amount.
      * 每个 05 条目重复一个代码和一个两位小数的数量。
      * 各 05 エントリは、コードと小数第 2 位の金額を繰り返します。
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TXN-CODE PIC X.
             10 WS-TXN-AMOUNT PIC 9(5)V99.
      * The numeric field is a subscript for the table references.
      * 数字字段是表引用的下标。
      * 数値フィールドはテーブル参照の添字です。
       01 WS-SAMPLE-INDEX PIC 9(2) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-BALANCE PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      * Load the table, process its populated range, then report.
      * 加载表，处理其填充范围，然后报告。
      * テーブルをロードし、そのテーブルに設定された範囲を処理して、レポートします。
       0000-MAIN.
           PERFORM 1000-LOAD-TABLE
           PERFORM 2000-PROCESS-TABLE
           PERFORM 9000-REPORT
           STOP RUN.
      * Initialize all four occurrences using numeric subscripts.
      * 使用数字下标初始化所有四个出现的位置。
      * 数字の添字を使用して 4 つの出現箇所をすべて初期化します。
       1000-LOAD-TABLE.
           MOVE "C" TO WS-TXN-CODE(1)
           MOVE 125.50 TO WS-TXN-AMOUNT(1)
           MOVE "D" TO WS-TXN-CODE(2)
           MOVE 40.10 TO WS-TXN-AMOUNT(2)
           MOVE "X" TO WS-TXN-CODE(3)
           MOVE 25.00 TO WS-TXN-AMOUNT(3)
           MOVE "C" TO WS-TXN-CODE(4)
           MOVE 20.00 TO WS-TXN-AMOUNT(4).
      * Process populated entries through the configured last index.
      * 通过配置的最后一个索引处理填充的条目。
      * 設定された最後のインデックスを通じて、設定されたエントリを処理します。
       2000-PROCESS-TABLE.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-PROCESS-ENTRY
           END-PERFORM.
      * Read the code and amount from the current occurrence.
      * 读取当前发生的代码和金额。
      * 現在のオカレンスからコードと金額を読み取ります。
       2100-PROCESS-ENTRY.
           DISPLAY "ENTRY=" WS-SAMPLE-INDEX
               " CODE=" WS-TXN-CODE(WS-SAMPLE-INDEX)
               " AMOUNT=" WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
           EVALUATE WS-TXN-CODE(WS-SAMPLE-INDEX)
               WHEN "C"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           + WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=CREDIT"
               WHEN "D"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           - WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=DEBIT"
               WHEN OTHER
                   DISPLAY "ACTION=IGNORED_UNKNOWN_CODE"
           END-EVALUATE
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      * Report entries processed and the resulting account balance.
      * 报告已处理的条目以及由此产生的帐户余额。
      * 処理されたエントリとその結果のアカウント残高をレポートします。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT
           DISPLAY "FINAL-BALANCE=" WS-ACCOUNT-BALANCE.
      * WS-TRANSACTION-TABLE is the parent group for all table entries.
      * WS-TRANSACTION-TABLE 是所有表条目的父组。
      * WS-TRANSACTION-TABLE は、すべてのテーブル エントリの親グループです。
      * OCCURS 4 TIMES allocates four occurrences in this fixed table.
      * OCCURS 4 TIMES 在此固定表中分配四次出现。
      * OCCURS 4 TIMES は、この固定テーブルに 4 つのオカレンスを割り当てます。
      * Each occurrence includes both WS-TXN-CODE and WS-TXN-AMOUNT.
      * 每次出现都包含 WS-TXN-CODE 和 WS-TXN-AMOUNT。
      * 各オカレンスには、WS-TXN-CODE と WS-TXN-AMOUNT の両方が含まれます。
      * A group-level OCCURS repeats its entire subordinate structure.
      * 组级 OCCURS 重复其整个从属结构。
      * グループレベルの OCCURS は、その下位構造全体を繰り返します。
      * Both elementary fields use the same numeric subscript per entry.
      * 两个基本字段的每个条目使用相同的数字下标。
      * どちらの基本フィールドでも、エントリごとに同じ数値添え字が使用されます。
      * Subscripts are written in parentheses after the data name.
      * 下标写在数据名称后面的括号中。
      * 添字はデータ名の後ろの括弧内に記述します。
      * The first occurrence is addressed with subscript 1.
      * 第一次出现的位置用下标 1 表示。
      * 最初に出現したものには添え字 1 が付けられます。
      * The fourth and final occurrence is addressed with subscript 4.
      * 第四个也是最后一个出现的情况用下标 4 表示。
      * 4 番目と最後の出現には、添え字 4 が付けられます。
      * WS-LAST-SAMPLE must never exceed the declared table upper bound.
      * WS-LAST-SAMPLE 绝不能超过声明的表上限。
      * WS-LAST-SAMPLE は、宣言されたテーブルの上限を決して超えてはなりません。
      * The loop checks its end condition before each processing pass.
      * 循环在每次处理之前检查其结束条件。
      * ループは、各処理パスの前に終了条件をチェックします。
      * Index 4 is processed because the exit test uses greater-than.
      * 处理索引 4 是因为退出测试使用大于。
      * 終了テストではより大きいを使用するため、インデックス 4 が処理されます。
      * After index 4, index 5 meets the exit test.
      * 在索引4之后，索引5满足退出测试。
      * インデックス 4 の後に、インデックス 5 が終了テストを満たします。
      * The performed entry paragraph returns to the loop body.
      * 执行的入口段返回到循环体。
      * 実行されたエントリ段落はループ本体に戻ります。
      * The loop increments the processed count once per table entry.
      * 该循环将每个表条目的已处理计数递增一次。
      * このループは、テーブル エントリごとに 1 回、処理されたカウントをインクリメントします。
      * A numeric subscript is an ordinary numeric data item.
      * 数字下标是普通的数字数据项。
      * 数値添字は通常の数値データ項目です。
      * Lesson 12 introduces INDEXED BY and table index data items.
      * 第12课介绍INDEXED BY和表索引数据项。
      * レッスン 12 では、INDEXED BY およびテーブル インデックス データ項目を紹介します。
      * This table has fixed capacity even when fewer entries are used.
      * 即使使用较少的条目，该表也具有固定的容量。
      * このテーブルの容量は、使用するエントリが少なくても固定です。
      * This sample fills every allocated occurrence before the loop.
      * 该示例填充循环之前的每个分配的事件。
      * このサンプルでは、​​ループの前に割り当てられたすべてのオカレンスを埋めます。
      * OCCURS does not load values or check transaction business rules.
      * OCCURS 不加载值或检查交易业务规则。
      * OCCURS は値をロードしたり、トランザクション ビジネス ルールをチェックしたりしません。
      * EVALUATE keeps the already learned code classification explicit.
      * EVALUATE 使已经学习的代码分类保持明确。
      * EVALUATE は、すでに学習したコード分類を明示的に保ちます。
      * The unknown code branch leaves the running balance unchanged.
      * 未知代码分支使运行余额保持不变。
      * 不明なコード分岐により、実行残高は変更されません。
      * Entries are processed in the order selected by the subscript.
      * 条目按照下标选择的顺序进行处理。
      * エントリは添え字で選択された順序で処理されます。
      * No implicit sorting or lookup happens when a table is declared.
      * 声明表时不会发生隐式排序或查找。
      * テーブルが宣言された場合、暗黙的な並べ替えや検索は行われません。
      * Later lessons will search tables using account identifiers.
      * 后面的课程将使用帐户标识符搜索表。
      * 後のレッスンでは、アカウント識別子を使用してテーブルを検索します。
      * The four sample amounts are 125.50, 40.10, 25.00, and 20.00.
      * 四个样本量为 125.50、40.10、25.00 和 20.00。
      * 4 つのサンプル量は、125.50、40.10、25.00、および 20.00 です。
      * The accepted credit and debit sequence ends at balance 1105.40.
      * 接受的贷方和借方序列在余额 1105.40 处结束。
      * 受け入れられたクレジットとデビットのシーケンスは残高 1105.40 で終了します。
      * The ignored unknown-code amount is not added to the balance.
      * 忽略的未知代码金额不会添加到余额中。
      * 無視された不明コードの量は残高に追加されません。
      * The table is stored in WORKING-STORAGE for this program run.
      * 该表存储在 WORKING-STORAGE 中以供该程序运行。
      * このプログラムの実行では、テーブルは WORKING-STORAGE に保存されます。
      * Fixed OCCURS bounds simplify storage planning and table review.
      * 固定的 OCCURS 边界简化了存储规划和表审查。
      * 固定された OCCURS 境界により、ストレージ計画とテーブルのレビューが簡素化されます。
      * Keep table bound and loop range consistent.
      * 保持表边界和循环范围一致。
      * テーブルのバインドとループ範囲の一貫性を維持します。
      * Avoid using a subscript outside the declared occurrence range.
      * 避免使用声明的出现范围之外的下标。
      * 宣言された出現範囲外の添え字は使用しないでください。
      * This program displays fields, not the whole group record.
      * 该程序显示字段，而不是整个组记录。
      * このプログラムは、グループ レコード全体ではなく、フィールドを表示します。
      * STOP RUN ends this fixed-table demonstration.
      * STOP RUN 结束该固定工作台演示。
      * STOP RUN は、この固定テーブルのデモンストレーションを終了します。
