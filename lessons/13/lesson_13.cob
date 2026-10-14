      * Lesson 13: locate account keys in an OCCURS table.
      * 第 13 课：在 OCCURS 表中查找帐户密钥。
      * レッスン 13: OCCURS テーブルでアカウント キーを見つけます。
      * SEARCH checks table entries sequentially from a set index.
      * SEARCH 从一组索引开始顺序检查表条目。
      * SEARCH は、設定されたインデックスからテーブル エントリを順番にチェックします。
      * SEARCH ALL uses binary search and requires a sorted unique key.
      * SEARCH ALL 使用二分搜索并需要排序的唯一键。
      * SEARCH ALL は二分検索を使用し、ソートされた一意のキーが必要です。
      * The account keys below are stored in ascending text order.
      * 下面的帐户密钥按升序文本顺序存储。
      * 以下のアカウント キーはテキストの昇順で保存されます。
      * Both statements use an INDEXED BY table index for references.
      * 这两个语句都使用 INDEXED BY 表索引作为引用。
      * どちらのステートメントでも、参照に INDEXED BY テーブル インデックスを使用します。
      * A search target may be present or absent from the table.
      * 搜索目标可以存在于表中或不存在于表中。
      * 検索対象はテーブルに存在する場合もあれば、存在しない場合もあります。
      * AT END handles a search that reaches no matching account.
      * AT END 处理未到达匹配帐户的搜索。
      * AT END は、一致するアカウントに到達しない検索を処理します。
      * The table order and its ASCENDING KEY clause must agree.
      * 表顺序及其 ASCENDING KEY 子句必须一致。
      * テーブルの順序とその ASCENDING KEY 句は一致する必要があります。
      * SEARCH ALL does not sort data or check the actual key order.
      * SEARCH ALL 不会对数据进行排序或检查实际的键顺序。
      * SEARCH ALL は、データを並べ替えたり、実際のキーの順序を確認したりしません。
      * This sample uses four fixed account entries and no file input.
      * 此示例使用四个固定帐户条目并且没有文件输入。
      * このサンプルでは、​​4 つの固定アカウント エントリを使用し、ファイル入力は使用しません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SEARCH13.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The key clause describes the required order for SEARCH ALL.
      * key 子句描述了 SEARCH ALL 所需的顺序。
      * key 句は、SEARCH ALL に必要な順序を記述します。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
       01 WS-SEARCH-KEY PIC X(10) VALUE SPACES.
       PROCEDURE DIVISION.
      * Search for one present key and one missing key by both methods.
      * 通过这两种方法搜索一把存在的钥匙和一把丢失的钥匙。
      * 両方の方法で 1 つの存在キーと 1 つの欠落キーを検索します。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           MOVE "0002468101" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           MOVE "0005550000" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           STOP RUN.
      * Load four unique account keys in ascending order.
      * 按升序加载四个唯一的帐户密钥。
      * 4 つの一意のアカウント キーを昇順でロードします。
       1000-LOAD-ACCOUNTS.
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(1)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(2)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(3)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(4)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(4).
      * SEARCH checks each entry in sequence from index 1.
      * SEARCH 从索引 1 开始按顺序检查每个条目。
      * SEARCH は、インデックス 1 から順に各エントリをチェックします。
       2000-SEQUENTIAL-SEARCH.
           DISPLAY "SEARCH=SEQUENTIAL KEY=" WS-SEARCH-KEY
           SET WS-ACCOUNT-IDX TO 1
           SEARCH WS-ACCOUNT-ENTRY
               AT END
                   DISPLAY "SEQUENTIAL=NOT_FOUND"
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   DISPLAY "SEQUENTIAL=FOUND ACCOUNT="
                       WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                       " BALANCE="
                       WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           END-SEARCH.
      * SEARCH ALL performs binary search over the declared key order.
      * SEARCH ALL 对声明的键顺序执行二分搜索。
      * SEARCH ALL は、宣言されたキー順序に対して二分検索を実行します。
       3000-BINARY-SEARCH.
           DISPLAY "SEARCH=BINARY KEY=" WS-SEARCH-KEY
           SEARCH ALL WS-ACCOUNT-ENTRY
               AT END
                   DISPLAY "BINARY=NOT_FOUND"
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   DISPLAY "BINARY=FOUND ACCOUNT="
                       WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                       " BALANCE="
                       WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           END-SEARCH.
      * SEARCH starts at the current search index, so set it to 1 first.
      * SEARCH 从当前搜索索引开始，因此首先将其设置为 1。
      * SEARCH は現在の検索インデックスから開始されるため、最初に 1 に設定します。
      * On a miss, SEARCH advances the index through every table entry.
      * 如果未命中，SEARCH 会通过每个表条目推进索引。
      * 失敗した場合、SEARCH はすべてのテーブル エントリのインデックスを進めます。
      * SEARCH ALL selects positions while performing binary search.
      * SEARCH ALL 在执行二分搜索时选择位置。
      * SEARCH ALL は二分探索を実行しながら位置を選択します。
      * The WHEN condition uses the same table key and search target.
      * WHEN 条件使用相同的表键和搜索目标。
      * WHEN条件は同じテーブルキーと検索対象を使用します。
      * FOUND output reads balance from the matching occurrence.
      * FOUND 输出从匹配的事件中读取余额。
      * FOUND 出力は、一致するオカレンスから残高を読み取ります。
      * AT END runs after all sequential entries fail to match.
      * AT END 在所有顺序条目均无法匹配后运行。
      * AT END は、すべての連続エントリが一致しなかった後に実行されます。
      * SEARCH ALL uses AT END when the key is not present in the table.
      * 当表中不存在键时，SEARCH ALL 使用 AT END。
      * SEARCH ALL は、キーがテーブルに存在しない場合に AT END を使用します。
      * SEARCH ALL requires INDEXED BY in the OCCURS definition.
      * SEARCH ALL 需要 OCCURS 定义中的 INDEXED BY。
      * SEARCH ALL では、OCCURS 定義に INDEXED BY が必要です。
      * ASCENDING KEY states the expected order but does not create it.
      * ASCENDING KEY 说明预期的顺序，但不会创建它。
      * ASCENDING KEY は、予想される順序を示しますが、それを作成しません。
      * The values loaded in 1000-LOAD-ACCOUNTS are actually ascending.
      * 1000-LOAD-ACCOUNTS 中加载的值实际上是升序的。
      * 1000-LOAD-ACCOUNTS にロードされる値は実際には昇順です。
      * Account keys are unique, as required for this SEARCH ALL table.
      * 根据此 SEARCH ALL 表的要求，帐户密钥是唯一的。
      * この SEARCH ALL テーブルに必要なため、アカウント キーは一意です。
      * Fixed-width text keys preserve leading zeroes during comparison.
      * 固定宽度的文本键在比较期间保留前导零。
      * 固定幅のテキスト キーは、比較中に先頭のゼロを保持します。
      * The target 0002468101 matches the third account entry.
      * 目标 0002468101 与第三个帐户条目匹配。
      * ターゲット 0002468101 は 3 番目のアカウント エントリと一致します。
      * The target 0005550000 is between stored keys but is not present.
      * 目标 0005550000 位于存储的键之间，但不存在。
      * ターゲット 0005550000 は保存されたキーの間にありますが、存在しません。
      * Both search forms report the same match or miss for valid data.
      * 两个搜索表单都报告有效数据的相同匹配或缺失。
      * どちらの検索フォームでも、有効なデータについて同じ一致または不一致が報告されます。
      * The sequential form can inspect entries one by one.
      * 顺序形式可以一项一项地检查条目。
      * シーケンシャルフォームでは、エントリを 1 つずつ検査できます。
      * The binary form repeatedly narrows the remaining ordered range.
      * 二进制形式反复缩小剩余的有序范围。
      * バイナリ形式は、残りの順序付き範囲を繰り返し狭めます。
      * Never use SEARCH ALL on a table whose actual key order is wrong.
      * 切勿在实际键顺序错误的表上使用 SEARCH ALL。
      * 実際のキーの順序が間違っているテーブルでは決して SEARCH ALL を使用しないでください。
      * Compiler checks the key clause, not runtime value order.
      * 编译器检查关键子句，而不是运行时值顺序。
      * コンパイラは、実行時の値の順序ではなく、キー句をチェックします。
      * SEARCH ALL may be wrong if the table order is wrong.
      * 如果表顺序错误，SEARCH ALL 可能会出错。
      * テーブルの順序が間違っていると、SEARCH ALL が間違っている可能性があります。
      * Duplicate keys also violate this lookup contract.
      * 重复的密钥也违反了此查找契约。
      * 重複キーもこの検索規約に違反します。
      * Review every entry when changing the key or order.
      * 更改密钥或顺序时检查每个条目。
      * キーまたは順序を変更する場合は、すべてのエントリを確認してください。
      * This program does not sort the table before searching it.
      * 该程序在搜索之前不会对表进行排序。
      * このプログラムは、テーブルを検索する前にソートしません。
      * Lesson 14 will combine table search with account transactions.
      * 第 14 课将表格搜索与账户交易结合起来。
      * レッスン 14 では、テーブル検索とアカウント トランザクションを組み合わせます。
      * The table holds four accounts in WORKING-STORAGE.
      * 该表在 WORKING-STORAGE 中包含四个帐户。
      * テーブルには WORKING-STORAGE に 4 つのアカウントが保持されます。
      * The index is supplied by the table's INDEXED BY clause.
      * 该索引由表的 INDEXED BY 子句提供。
      * インデックスはテーブルの INDEXED BY 句によって提供されます。
      * Both searches use the same table index name.
      * 两个搜索都使用相同的表索引名称。
      * どちらの検索でも同じテーブル インデックス名が使用されます。
      * No arithmetic is performed on the index.
      * 不对索引执行任何算术运算。
      * インデックスに対して演算は実行されません。
      * The table is already loaded before either search begins.
      * 在任一搜索开始之前该表已加载。
      * テーブルは、いずれかの検索が開始される前にすでにロードされています。
      * Search keys and account keys have the same X(10) width.
      * 搜索键和帐户键具有相同的 X(10) 宽度。
      * 検索キーとアカウント キーの幅は同じ X(10) です。
      * The search miss is an ordinary result, not a runtime error.
      * 搜索未命中是一个普通结果，而不是运行时错误。
      * 検索ミスは通常の結果であり、実行時エラーではありません。
      * The output identifies the search method and key for each lookup.
      * 输出标识每次查找的搜索方法和键。
      * 出力では、各検索の検索方法とキーが特定されます。
      * STOP RUN ends this fixed-table search demonstration.
      * STOP RUN 结束这个固定表搜索演示。
      * STOP RUN は、この固定テーブル検索のデモンストレーションを終了します。
