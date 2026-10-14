      *第 13 课：在 OCCURS 表中查找帐户密钥。
      *SEARCH 从已设定的索引开始，SEARCH 按顺序检查表项。
      *SEARCH ALL 使用二分搜索并需要排序的唯一键。
      *下面的帐户密钥按升序文本顺序存储。
      *这两个语句都使用 INDEXED BY 表索引作为引用。
      *搜索目标可以存在于表中或不存在于表中。
      *AT END 处理未到达匹配帐户的搜索。
      *表顺序及其 ASCENDING KEY 子句必须一致。
      *SEARCH ALL 不会对数据进行排序或检查实际的键顺序。
      *此示例使用四个固定帐户条目并且没有文件输入。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SEARCH13.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *key 子句描述了 SEARCH ALL 所需的顺序。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
       01 WS-SEARCH-KEY PIC X(10) VALUE SPACES.
       PROCEDURE DIVISION.
      *通过这两种方法搜索一把存在的钥匙和一把丢失的钥匙。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           MOVE "0002468101" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           MOVE "0005550000" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           STOP RUN.
      *按升序加载四个唯一的帐户密钥。
       1000-LOAD-ACCOUNTS.
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(1)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(2)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(3)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(4)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(4).
      *SEARCH 从索引 1 开始按顺序检查各个表项。
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
      *SEARCH ALL 对声明的键顺序执行二分搜索。
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
      *SEARCH 从当前索引开始，因此先将索引设为 1。
      *如果未命中，SEARCH 会逐个检查表项并推进索引。
      *SEARCH ALL 在执行二分搜索时选择位置。
      *WHEN 条件使用相同的表键和搜索目标。
      *找到匹配项时，输出逻辑从该表项读取余额。
      *AT END 在所有顺序条目均无法匹配后运行。
      *当表中不存在键时，SEARCH ALL 使用 AT END。
      *SEARCH ALL 需要 OCCURS 定义中的 INDEXED BY。
      *ASCENDING KEY 说明预期的顺序，但不会创建它。
      *1000-LOAD-ACCOUNTS 中加载的值实际上是升序的。
      *根据此 SEARCH ALL 表的要求，帐户密钥是唯一的。
      *固定宽度的文本键在比较期间保留前导零。
      *目标 0002468101 与第三个帐户条目匹配。
      *目标 0005550000 位于存储的键之间，但不存在。
      *两个搜索表单都报告有效数据的相同匹配或缺失。
      *顺序形式可以一项一项地检查条目。
      *二进制形式反复缩小剩余的有序范围。
      *切勿在实际键顺序错误的表上使用 SEARCH ALL。
      *编译器检查关键子句，而不是运行时值顺序。
      *如果表顺序错误，SEARCH ALL 可能会出错。
      *重复的密钥也违反了此查找契约。
      *更改密钥或顺序时检查每个条目。
      *该程序在搜索之前不会对表进行排序。
      *第 14 课将表格搜索与账户交易结合起来。
      *该表在 WORKING-STORAGE 中包含四个帐户。
      *该索引由表的 INDEXED BY 子句提供。
      *两个搜索都使用相同的表索引名称。
      *不对索引执行任何算术运算。
      *在任一搜索开始之前该表已加载。
      *搜索键和帐户键具有相同的 X(10) 宽度。
      *搜索未命中是一个普通结果，而不是运行时错误。
      *输出标识每次查找的搜索方法和键。
      *STOP RUN 结束这个固定表搜索演示。
