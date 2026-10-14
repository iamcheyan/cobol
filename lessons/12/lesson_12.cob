      * Lesson 12: traverse an OCCURS table with an INDEXED BY item.
      * 第 12 课：使用 INDEXED BY 项遍历 OCCURS 表。
      * レッスン 12: INDEXED BY 項目を使用して OCCURS テーブルを走査します。
      * The table index is declared in the table's OCCURS clause.
      * 表索引在表的 OCCURS 子句中声明。
      * テーブルのインデックスは、テーブルの OCCURS 句で宣言されます。
      * SET assigns and increments the index used in table references.
      * SET 分配并递增表引用中使用的索引。
      * SET は、テーブル参照で使用されるインデックスを割り当てて増分します。
      * Unlike a subscript, an index has USAGE INDEX, not a numeric PIC.
      * 与下标不同，索引具有 USAGE INDEX，而不是数字 PIC。
      * 添字とは異なり、インデックスには数値 PIC ではなく USAGE INDEX が含まれます。
      * The program displays a loaded account table in occurrence order.
      * 程序按发生顺序显示加载的帐户表。
      * プログラムは、ロードされたアカウント テーブルを出現順に表示します。
      * All four entries are loaded before the indexed traversal begins.
      * 所有四个条目均在索引遍历开始之前加载。
      * インデックス付き走査が開始される前に、4 つのエントリすべてがロードされます。
      * No SEARCH, arithmetic on the index, or external input is used.
      * 不使用搜索、索引算术或外部输入。
      * SEARCH、インデックスの算術演算、または外部入力は使用されません。
      * The last-entry count controls when the traversal ends.
      * 最后条目计数控制遍历何时结束。
      * 最終エントリ数は、トラバースがいつ終了するかを制御します。
      * This example keeps the table and traversal range synchronized.
      * 此示例使表和遍历范围保持同步。
      * この例では、テーブルと走査範囲の同期を維持します。
      * No index value is displayed as though it were a numeric field.
      * 没有索引值显示，就好像它是数字字段一样。
      * インデックス値は数値フィールドのように表示されません。
      * Literal subscripts initialize known positions in the table.
      * 文字下标初始化表中的已知位置。
      * リテラル添字は、テーブル内の既知の位置を初期化します。
      * Each literal writes one occurrence by its number.
      * 每个文字按其编号写入一次出现的情况。
      * 各リテラルは、その番号によって 1 つの出現を書き込みます。
      * The table entries are groups of two elementary items.
      * 表条目是两个基本项的组。
      * テーブル エントリは 2 つの基本項目のグループです。
      * The index is named at OCCURS, not in WORKING-STORAGE.
      * 该索引在 OCCURS 中命名，而不是在 WORKING-STORAGE 中命名。
      * インデックスの名前は、WORKING-STORAGE ではなく OCCURS に付けられます。
      * One index selects each child of its current occurrence.
      * 一个索引选择其当前出现的每个子项。
      * 1 つのインデックスは、現在のオカレンスの各子を選択します。
      * SET assigns the starting table occurrence explicitly.
      * SET 显式指定起始表出现次数。
      * SET は開始テーブルのオカレンスを明示的に割り当てます。
      * SET UP BY advances the index by one table entry.
      * SET UP BY 将索引前进一个表条目。
      * SET UP BY は、インデックスをテーブル エントリ 1 つ進めます。
      * A numeric count can be compared with an index.
      * 数字计数可以与索引进行比较。
      * 数値カウントはインデックスと比較できます。
      * The loop checks its condition before displaying an account.
      * 循环在显示帐户之前检查其条件。
      * このループは、アカウントを表示する前にその状態をチェックします。
      * The last increment does not display another table entry.
      * 最后一个增量不显示另一个表条目。
      * 最後の増分では、別のテーブル エントリは表示されません。
      * No extra subscript is required on an indexed reference.
      * 索引引用不需要额外的下标。
      * インデックス付き参照には追加の添え字は必要ありません。
      * Field names retain their meaning under either selector.
      * 字段名称在任一选择器下均保留其含义。
      * フィールド名は、どちらのセレクターでも意味を保持します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INDEX12.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Each account entry contains its key and current sample balance.
      * 每个帐户条目都包含其密钥和当前样本余额。
      * 各口座エントリには、そのキーと現在のサンプル残高が含まれています。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
      * The index is implicit in INDEXED BY; it has no PIC declaration.
      * 索引是隐含在INDEXED BY中的；它没有 PIC 声明。
      * INDEXED BY ではインデックスは暗黙的です。 PIC 宣言はありません。
       01 WS-LAST-ACCOUNT PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Load every table occurrence before the index traverses it.
      * 在索引遍历表之前加载每个表出现的位置。
      * インデックスがテーブルを走査する前に、すべてのテーブルオカレンスをロードします。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           PERFORM 2000-DISPLAY-ACCOUNTS
           PERFORM 9000-REPORT
           STOP RUN.
      * Populate each account by its ordinary numeric subscript.
      * 用其普通数字下标填充每个帐户。
      * 各アカウントに通常の数値の下付き文字を入力します。
       1000-LOAD-ACCOUNTS.
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(1)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(2)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(3)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(4)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(4).
      * Set the table index, visit each occurrence, then increment it.
      * 设置表索引，访问每个事件，然后递增它。
      * テーブルのインデックスを設定し、出現するたびにアクセスして、それを増加させます。
       2000-DISPLAY-ACCOUNTS.
           SET WS-ACCOUNT-IDX TO 1
           PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT
               PERFORM 2100-DISPLAY-ONE-ACCOUNT
               SET WS-ACCOUNT-IDX UP BY 1
           END-PERFORM.
      * Use the current index in both fields of the account entry.
      * 在帐户条目的两个字段中使用当前索引。
      * アカウントエントリの両方のフィールドで現在のインデックスを使用します。
       2100-DISPLAY-ONE-ACCOUNT.
           DISPLAY "ACCOUNT="
               WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
               " BALANCE="
               WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      * Report how many loaded entries the indexed loop visited.
      * 报告索引循环访问了多少加载条目。
      * インデックス付きループが訪問したロードされたエントリの数を報告します。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT.
      * INDEXED BY declares an index associated with this OCCURS table.
      * INDEXED BY 声明与此 OCCURS 表关联的索引。
      * INDEXED BY は、この OCCURS テーブルに関連付けられたインデックスを宣言します。
      * WS-ACCOUNT-IDX is not a PIC numeric working-storage field.
      * WS-ACCOUNT-IDX 不是 PIC 数字工作存储字段。
      * WS-ACCOUNT-IDX は、PIC 数値作業記憶フィールドではありません。
      * SET WS-ACCOUNT-IDX TO 1 selects the first occurrence.
      * SET WS-ACCOUNT-IDX TO 1 选择第一个匹配项。
      * SET WS-ACCOUNT-IDX TO 1 は、最初の出現を選択します。
      * SET UP BY 1 advances to the next occurrence in the table.
      * SET UP BY 1 前进到表中的下一个出现位置。
      * SET UP BY 1 は、テーブル内の次の出現箇所に進みます。
      * Both selectors use parentheses in table references.
      * 两个选择器在表引用中都使用括号。
      * どちらのセレクターもテーブル参照で括弧を使用します。
      * The data item declaration tells which selector is being used.
      * 数据项声明告诉我们正在使用哪个选择器。
      * データ項目の宣言は、どのセレクターが使用されているかを示します。
      * Lesson 11 instead used WS-SAMPLE-INDEX PIC 9(2) as a subscript.
      * 第 11 课改为使用 WS-SAMPLE-INDEX PIC 9(2) 作为下标。
      * レッスン 11 では、代わりに WS-SAMPLE-INDEX PIC 9(2) を添え字として使用しました。
      * A numeric subscript stores a number naming the table occurrence.
      * 数字下标存储命名表出现的数字。
      * 数値添字には、テーブルオカレンスの名前を付ける番号が格納されます。
      * An index is a separate selector whose value is set with SET.
      * 索引是一个单独的选择器，其值通过 SET 设置。
      * インデックスは、SET で値が設定される別個のセレクターです。
      * An index is not a PIC field for numeric calculations.
      * 索引不是用于数值计算的 PIC 字段。
      * インデックスは数値計算用の PIC フィールドではありません。
      * Use SET UP or SET DOWN to move an index through table entries.
      * 使用 SET UP 或 SET DOWN 在表条目中移动索引。
      * テーブル エントリ間でインデックスを移動するには、SET UP または SET DOWN を使用します。
      * The table has a declared maximum of four occurrences.
      * 该表声明最多出现四次。
      * テーブルには宣言された最大出現数が 4 つあります。
      * WS-LAST-ACCOUNT is a numeric count, not the index itself.
      * WS-LAST-ACCOUNT 是一个数字计数，而不是索引本身。
      * WS-LAST-ACCOUNT は数値カウントであり、インデックス自体ではありません。
      * The index is compared with the populated account count.
      * 该索引与填充的帐户数进行比较。
      * インデックスは、入力されたアカウント数と比較されます。
      * After index 4, the next index is beyond the last entry.
      * 在索引 4 之后，下一个索引超出最后一个条目。
      * インデックス 4 の後の次のインデックスは最後のエントリの後にあります。
      * The loop then ends before attempting another table reference.
      * 然后循环在尝试另一个表引用之前结束。
      * その後、別のテーブル参照を試行する前にループが終了します。
      * Account numbers retain leading zeroes in the text key.
      * 帐号在文本键中保留前导零。
      * 口座番号はテキスト キーの先頭のゼロを保持します。
      * A zero balance still belongs to a populated entry.
      * 零余额仍然属于已填充的条目。
      * ゼロ残高は依然として設定されたエントリに属します。
      * The processed count increases once per visited occurrence.
      * 每访问一次，处理的计数就会增加一次。
      * 処理された数は、訪問されたオカレンスごとに 1 回増加します。
      * The index itself is not used as the processed count.
      * 索引本身不用作已处理的计数。
      * インデックス自体は処理数として使用されません。
      * All indexed fields in one group occurrence use the same index.
      * 一组出现中的所有索引字段都使用相同的索引。
      * 1 つのグループ オカレンスのすべてのインデックス付きフィールドは、同じインデックスを使用します。
      * Each occurrence repeats both number and balance fields.
      * 每次出现都会重复数字和余额字段。
      * 出現するたびに、数値フィールドと残高フィールドの両方が繰り返されます。
      * No table value is searched for or sorted by this program.
      * 该程序不会搜索或排序任何表值。
      * このプログラムではテーブル値の検索や並べ替えは行われません。
      * Lesson 13 uses table search to associate keys and records.
      * 第 13 课使用表搜索来关联键和记录。
      * レッスン 13 では、テーブル検索を使用してキーとレコードを関連付けます。
      * The order here is the declared occurrence order, from 1 to 4.
      * 这里的顺序是声明的出现顺序，从1到4。
      * ここでの順序は、宣言された出現順序 (1 から 4) です。
      * Keep the loaded entry count within the declared OCCURS bound.
      * 将加载的条目计数保持在声明的 OCCURS 范围内。
      * ロードされたエントリ数を、宣言された OCCURS 境界内に維持してください。
      * Unloaded entries must not be treated as valid account records.
      * 卸载的条目不得被视为有效的帐户记录。
      * アンロードされたエントリは、有効なアカウント レコードとして扱われてはなりません。
      * This is an in-memory traversal, not a file read operation.
      * 这是内存中的遍历，而不是文件读取操作。
      * これはメモリ内トラバーサルであり、ファイル読み取り操作ではありません。
      * GnuCOBOL supports table indexes in this fixed-format source.
      * GnuCOBOL 支持此固定格式源中的表索引。
      * GnuCOBOL は、この固定形式ソースのテーブル インデックスをサポートします。
      * STOP RUN ends this indexed table demonstration.
      * STOP RUN 结束该索引表演示。
      * STOP RUN は、このインデックス付きテーブルのデモを終了します。
