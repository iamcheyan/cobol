      * Lesson 15: read daily transaction text one line at a time.
      * 第 15 课：一次一行阅读日常交易文本。
      * レッスン 15: 毎日の取引テキストを一度に 1 行ずつ読んでください。
      * LINE SEQUENTIAL stores one text record on each physical line.
      * LINE SEQUENTIAL 在每一物理行上存储一个文本记录。
      * LINE SEQUENTIAL は、各物理行に 1 つのテキスト レコードを保存します。
      * READ retrieves the next record until the AT END clause runs.
      * READ 检索下一条记录，直到 AT END 子句运行。
      * READ は、AT END 句が実行されるまで次のレコードを取得します。
      * Short lines are padded in the FD record area.
      * FD记录区域中填充短行。
      * FD 記録領域には短い行が埋め込まれます。
      * TRIM removes that padding only for the display operation.
      * TRIM 仅为显示操作删除该填充。
      * TRIM は、表示操作の場合にのみそのパディングを削除します。
      * This program reads records as text and does not parse fields.
      * 该程序将记录作为文本读取，并且不解析字段。
      * このプログラムはレコードをテキストとして読み取り、フィールドを解析しません。
      * Run here so ASSIGN finds the input fixture.
      * 在此处运行以便 ASSIGN 找到输入装置。
      * ここを実行すると、ASSIGN が入力フィクスチャを見つけます。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * Open failure is reported before any read is attempted.
      * 在尝试任何读取之前会报告打开失败。
      * オープンの失敗は、読み取りが試行される前に報告されます。
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "OPEN=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               PERFORM 1000-READ-ONE-RECORD
           END-PERFORM
           DISPLAY "EOF=YES RECORDS=" WS-RECORD-COUNT
           CLOSE TRANSACTION-FILE
           IF WS-FILE-STATUS = "00"
               DISPLAY "CLOSE=OK"
           ELSE
               DISPLAY "CLOSE=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * READ obtains one physical line or signals end of file.
      * READ 获取一根物理行或表示文件结束。
      * READ は 1 つの物理行を取得するか、ファイルの終わりを通知します。
       1000-READ-ONE-RECORD.
           READ TRANSACTION-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
                   DISPLAY "RECORD="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
      * OPEN INPUT prepares an existing file for reading.
      * OPEN INPUT 准备现有文件以供读取。
      * OPEN INPUT は、既存のファイルを読み取り用に準備します。
      * A successful OPEN reports file status 00.
      * 成功打开报告文件状态 00。
      * OPEN が成功すると、ファイルのステータス 00 が報告されます。
      * A missing required file causes OPEN to return a nonzero status.
      * 缺少所需文件会导致 OPEN 返回非零状态。
      * 必要なファイルが見つからない場合、OPEN はゼロ以外のステータスを返します。
      * The program returns status 1 if its input cannot be opened.
      * 如果无法打开其输入，程序将返回状态 1。
      * 入力をオープンできない場合、プログラムはステータス 1 を返します。
      * The FD describes one line-sequential text record.
      * FD 描述了一行顺序的文本记录。
      * FD には 1 つの行順テキストレコードが記述されます。
      * Line sequential records end at each physical newline.
      * 行顺序记录在每个物理换行符处结束。
      * 行順次レコードは各物理改行で終了します。
      * The input records are shorter than the 100-character FD area.
      * 输入记录比 100 个字符的 FD 区域短。
      * 入力レコードは 100 文字の FD エリアよりも短いです。
      * GnuCOBOL pads shorter line-sequential records with spaces.
      * GnuCOBOL 用空格填充较短的行顺序记录。
      * GnuCOBOL は、短い行順次レコードにスペースを埋め込みます。
      * FUNCTION TRIM removes only right-side padding for display.
      * FUNCTION TRIM 仅删除右侧的显示填充。
      * FUNCTION TRIM は、表示の右側のパディングのみを削除します。
      * The stored file record itself remains unchanged by TRIM.
      * TRIM 不会改变存储的文件记录本身。
      * 保存されたファイル レコード自体は TRIM によって変更されません。
      * READ without a random key retrieves the next sequential record.
      * 没有随机密钥的 READ 将检索下一个连续记录。
      * ランダム キーを使用しない READ は、次の連続レコードを取得します。
      * READ AT END signals that no next record is available.
      * READ AT END 表示没有下一条记录可用。
      * READ AT END は、次のレコードが利用できないことを示します。
      * The EOF branch sets a flag and does not increment the count.
      * EOF 分支设置一个标志并且不增加计数。
      * EOF 分岐はフラグを設定しますが、カウントは増加しません。
      * The loop ends after the first READ that reaches end of file.
      * 循环在第一次 READ 到达文件末尾后结束。
      * ループは、最初の READ がファイルの終わりに達した後に終了します。
      * A final newline does not create an extra empty data record.
      * 最后的换行符不会创建额外的空数据记录。
      * 最後の改行によって余分な空のデータ レコードが作成されることはありません。
      * The record counter increases once for each successful READ.
      * 每次成功读取，记录计数器都会增加一次。
      * レコード カウンタは、読み取りが成功するたびに 1 回増加します。
      * The program displays the original text of each input record.
      * 程序显示每个输入记录的原始文本。
      * プログラムは、各入力レコードの元のテキストを表示します。
      * It does not split the pipe-delimited fields in this lesson.
      * 在本课中，它不会拆分以竖线分隔的字段。
      * このレッスンでは、パイプで区切られたフィールドは分割されません。
      * File status after a successful READ is 00.
      * 成功读取后文件状态为 00。
      * READ が成功した後のファイルのステータスは 00 です。
      * File status after end of file is 10 until the file is closed.
      * 文件结束后的文件状态为 10，直到文件关闭。
      * ファイル終了後のファイルステータスは、ファイルが閉じるまで 10 です。
      * CLOSE returns status 00 when it succeeds.
      * CLOSE 成功时返回状态 00。
      * CLOSE は成功するとステータス 00 を返します。
      * The file must exist because this SELECT is not OPTIONAL.
      * 该文件必须存在，因为此 SELECT 不是可选的。
      * この SELECT は OPTIONAL ではないため、ファイルは存在する必要があります。
      * The input path is relative to the current directory.
      * 输入路径是相对于当前目录的。
      * 入力パスは現在のディレクトリからの相対パスです。
      * Start the program from the lesson directory to use its fixture.
      * 从课程目录启动程序以使用其固定装置。
      * フィクスチャを使用するには、レッスン ディレクトリからプログラムを起動します。
      * This program performs no writes and changes no input data.
      * 该程序不执行写入操作，也不更改输入数据。
      * このプログラムは書き込みを実行せず、入力データを変更しません。
      * The next lesson will write accepted and rejected output records.
      * 下一课将编写接受和拒绝的输出记录。
      * 次のレッスンでは、承認された出力レコードと拒否された出力レコードを書き込みます。
      * Lesson 18 will parse delimiter-separated fields.
      * 第 18 课将解析分隔符分隔的字段。
      * レッスン 18 では、区切り文字で区切られたフィールドを解析します。
      * The fixture contains four daily account transaction records.
      * 该装置包含四个每日帐户交易记录。
      * このフィクスチャには、4 つの毎日の口座取引記録が含まれています。
      * Records differ in length to demonstrate line handling.
      * 记录的长度不同以展示线路处理。
      * 行処理を示すために、レコードの長さが異なります。
      * Each read uses the same FD record area.
      * 每次读取都使用相同的FD记录区域。
      * 各読み取りでは同じ FD レコード領域が使用されます。
      * Only READ AT END marks this input stream as complete.
      * 只有 READ AT END 将此输入流标记为完成。
      * READ AT END のみがこの入力ストリームを完了としてマークします。
      * A file read error is distinct from an ordinary end-of-file.
      * 文件读取错误与普通的文件结束错误不同。
      * ファイル読み取りエラーは、通常のファイルの終わりとは異なります。
      * File status should be examined when diagnosing I/O failures.
      * 诊断 I/O 故障时应检查文件状态。
      * I/O 障害を診断するときは、ファイルのステータスを調べる必要があります。
      * Close the file after the read loop, even when it is empty.
      * 读取循环后关闭文件，即使它是空的。
      * ファイルが空の場合でも、読み取りループの後にファイルを閉じます。
      * The output count confirms all available records were visited.
      * 输出计数确认所有可用记录均已被访问。
      * 出力カウントは、利用可能なすべてのレコードがアクセスされたことを確認します。
      * The empty file would report EOF with a zero record count.
      * 空文件将报告 EOF，记录计数为零。
      * 空のファイルはレコード数がゼロの EOF を報告します。
      * No table search or account balance update occurs in this lesson.
      * 本课程中不会进行表搜索或帐户余额更新。
      * このレッスンでは、テーブル検索や口座残高の更新は行われません。
      * STOP RUN ends the sequential input demonstration.
      * STOP RUN 结束顺序输入演示。
      * STOP RUN はシーケンシャル入力デモを終了します。
      * The fixture uses pipe characters to separate visible fields.
      * 该装置使用管道字符来分隔可见字段。
      * フィクスチャはパイプ文字を使用して表示フィールドを区切ります。
      * In this lesson each entire line remains one character record.
      * 在本课中，每一整行都保留一个字符记录。
      * このレッスンでは、各行全体が 1 つの文字レコードのままになります。
      * Date and transaction identifiers are displayed without checks.
      * 日期和交易标识符的显示不带检查。
      * 日付とトランザクション識別子はチェックなしで表示されます。
      * Transaction codes and amounts are not converted to COBOL fields.
      * 交易代码和金额不会转换为 COBOL 字段。
      * トランザクション コードと金額は COBOL フィールドに変換されません。
      * A later lesson will parse fields from delimited columns.
      * 稍后的课程将解析分隔列中的字段。
      * 後のレッスンでは、区切り文字で区切られた列からフィールドを解析します。
      * Line sequential files use newline delimiters between records.
      * 行顺序文件在记录之间使用换行符分隔符。
      * 行順ファイルでは、レコード間に改行区切り文字が使用されます。
      * A text editor can create this input fixture directly.
      * 文本编辑器可以直接创建此输入装置。
      * テキスト エディタは、この入力フィクスチャを直接作成できます。
      * Empty input reaches AT END on the first READ attempt.
      * 第一次 READ 尝试时，空输入到达 AT END。
      * 空の入力は、最初の READ 試行で AT END に達します。
      * A successful read increments the count exactly once.
      * 成功读取只会将计数增加一次。
      * 読み取りが成功すると、カウントが 1 回だけインクリメントされます。
      * The FD record width must accommodate the longest input line.
      * FD 记录宽度必须容纳最长的输入行。
      * FD レコード幅は、最長の入力行を収容できる必要があります。
