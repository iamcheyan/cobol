      * Lesson 19: read a master file and a daily transaction file.
      * 第19课：读取主文件和每日交易文件。
      * レッスン19：マスターファイルと日次取引ファイルを読み込みます。
      * Each input owns its own file status, EOF flag, and count.
      * 每个输入文件都有自己的文件状态、EOF标志和计数。
      * 各入力ファイルは、それぞれ独自のファイル状態、EOFフラグ、件数を持ちます。
      * The two streams may contain different numbers of records.
      * 两个流中的记录数可能不同。
      * 2つのストリームのレコード件数は異なる場合があります。
      * This lesson reads text records; it does not match account keys.
      * 本课读取文本记录，不匹配账户键。
      * このレッスンではテキストレコードを読み込みます。口座キーの照合は行いません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MULTI19.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-INPUT
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-INPUT.
       01 FD-ACCOUNT-RECORD PIC X(100).
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-ACCOUNT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Both inputs must open before the batch reads either stream.
      * 批处理读取任一流之前，两个输入文件都必须成功打开。
      * バッチがどちらかのストリームを読む前に、両方の入力を開く必要があります。
       0000-MAIN.
           OPEN INPUT ACCOUNT-INPUT
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT TRANSACTION-INPUT
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-INPUT
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-ACCOUNT-EOF = "N"
                   PERFORM 1000-READ-ACCOUNT
               END-IF
               IF WS-TRANSACTION-EOF = "N"
                   AND WS-IO-ERROR = "N"
                   PERFORM 2000-READ-TRANSACTION
               END-IF
           END-PERFORM
           CLOSE ACCOUNT-INPUT
           CLOSE TRANSACTION-INPUT
           IF WS-ACCOUNT-STATUS = "00"
               AND WS-TRANSACTION-STATUS = "00"
               DISPLAY "CLOSE=OK ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TRANSACTIONS=" WS-TRANSACTION-COUNT
           ELSE
               DISPLAY "CLOSE=FAILED ACCOUNT=" WS-ACCOUNT-STATUS
                   " TRANSACTION=" WS-TRANSACTION-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Read only while the account stream has not reached EOF.
      * 仅在账户流尚未到达EOF时读取。
      * 口座ストリームがEOFに達していない間だけ読み込みます。
       1000-READ-ACCOUNT.
           READ ACCOUNT-INPUT
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   IF WS-ACCOUNT-STATUS = "00"
                       ADD 1 TO WS-ACCOUNT-COUNT
                       DISPLAY "ACCOUNT="
                           FUNCTION TRIM(
                               FD-ACCOUNT-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Read only while the transaction stream has not reached EOF.
      * 仅在交易流尚未到达EOF时读取。
      * 取引ストリームがEOFに達していない間だけ読み込みます。
       2000-READ-TRANSACTION.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   IF WS-TRANSACTION-STATUS = "00"
                       ADD 1 TO WS-TRANSACTION-COUNT
                       DISPLAY "TRANSACTION="
                           FUNCTION TRIM(
                               FD-TRANSACTION-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * OPEN INPUT assigns a separate status to each file.
      * OPEN INPUT为每个文件分配独立的状态。
      * OPEN INPUTでは、各ファイルに個別のステータスを割り当てます。
      * The first input must open before the second is attempted.
      * 必须先打开第一个输入文件，才能尝试打开第二个。
      * 2つ目を試す前に、最初の入力ファイルを開く必要があります。
      * If the second OPEN fails, the first file is closed.
      * 如果第二个OPEN失败，则关闭第一个文件。
      * 2つ目のOPENに失敗した場合、最初のファイルを閉じます。
      * No READ occurs until both required inputs have opened.
      * 两个必需输入文件都打开之前，不执行READ。
      * 必要な入力ファイルが両方開くまで、READは実行されません。
      * Each FD describes a text line up to 100 characters.
      * 每个FD定义一条最多100字符的文本行。
      * 各FDは最大100文字のテキスト行を定義します。
      * Each SELECT uses LINE SEQUENTIAL organization.
      * 每个SELECT都使用LINE SEQUENTIAL组织方式。
      * 各SELECTはLINE SEQUENTIAL編成を使用します。
      * Each physical line becomes one logical input record.
      * 每个物理行都成为一条逻辑输入记录。
      * 物理行1行が論理入力レコード1件になります。
      * A short line is padded in its FD record area.
      * 较短的行会在FD记录区域中填充空格。
      * 短い行はFDレコード領域でパディングされます。
      * TRIM omits that right-side padding from the display.
      * TRIM会在显示时去掉右侧填充空格。
      * TRIMは表示時に右側のパディングを取り除きます。
      * The program does not split or validate the displayed fields.
      * 程序不会拆分或验证显示的字段。
      * プログラムは表示したフィールドを分割も検証もしません。
      * The master and transaction records have different layouts.
      * 主记录和交易记录的布局不同。
      * マスターと取引のレコードレイアウトは異なります。
      * Their layouts are visible in the two fixture files.
      * 两个样例文件中可以看到各自的布局。
      * それぞれのレイアウトは2つのフィクスチャファイルで確認できます。
      * One loop pass attempts at most one read per active stream.
      * 每次循环对每个活动流最多尝试读取一次。
      * ループ1回につき、稼働中の各ストリームを最大1回読み込みます。
      * The account file may reach EOF before the transaction file.
      * 账户文件可能先于交易文件到达EOF。
      * 口座ファイルが取引ファイルより先にEOFに達する場合があります。
      * The transaction file may reach EOF before the account file.
      * 交易文件可能先于账户文件到达EOF。
      * 取引ファイルが口座ファイルより先にEOFに達する場合があります。
      * An EOF flag belongs only to the file that reached status 10.
      * EOF标志只属于状态为10的那个文件。
      * EOFフラグはステータス10になったファイルだけに属します。
      * A successful READ increments only that file's record count.
      * READ成功时只增加该文件的记录计数。
      * READが成功すると、そのファイルのレコード件数だけを増やします。
      * The EOF attempt does not increment either record count.
      * 触发EOF的读取尝试不会增加任何记录计数。
      * EOFになった読み込み試行では、どちらの件数も増えません。
      * A file at EOF is skipped on every later loop pass.
      * 文件到达EOF后，后续每轮循环都会跳过它。
      * EOFに達したファイルは、その後のループでは毎回スキップします。
      * Processing ends when both EOF flags are set.
      * 两个EOF标志都设置后，处理结束。
      * 両方のEOFフラグが立つと処理を終了します。
      * The loop also stops after a non-EOF read error.
      * 发生非EOF读取错误后，循环也会停止。
      * EOF以外の読み込みエラーが発生した場合も、ループを停止します。
      * AT END handles status 10 for its own READ statement.
      * AT END处理其所属READ语句的状态10。
      * AT ENDは、そのREAD文におけるステータス10を処理します。
      * NOT AT END handles a successful READ with status 00.
      * NOT AT END处理状态为00的成功READ。
      * NOT AT ENDは、ステータス00のREAD成功を処理します。
      * Other nonzero statuses are reported as input errors.
      * 其他非零状态会作为输入错误报告。
      * その他のゼロ以外のステータスは入力エラーとして報告します。
      * An I/O error is different from normal end of file.
      * I/O错误不同于正常文件结束。
      * I/Oエラーは通常のファイル終端とは異なります。
      * Both files are closed after normal completion or read error.
      * 正常完成或读取出错后都会关闭两个文件。
      * 正常終了時または読み込みエラー時に、両方のファイルを閉じます。
      * A close error is reported independently of the read counts.
      * 关闭错误会独立于读取计数报告。
      * クローズエラーは読み込み件数とは別に報告します。
      * The return code is nonzero for open, read, or close failures.
      * 打开、读取或关闭失败时，返回码为非零。
      * OPEN、READ、CLOSEの失敗時は、リターンコードがゼロ以外になります。
      * An empty file reaches its own EOF on the first READ attempt.
      * 空文件在第一次READ尝试时就会到达EOF。
      * 空ファイルは最初のREAD試行でEOFに達します。
      * One empty file does not suppress reads from the other file.
      * 一个文件为空不会阻止读取另一个文件。
      * 一方が空でも、もう一方のファイルの読み込みは止まりません。
      * The fixture contains three account master records.
      * 样例包含三条账户主记录。
      * フィクスチャには口座マスターレコードが3件あります。
      * The fixture contains four daily transaction records.
      * 样例包含四条每日交易记录。
      * フィクスチャには日次取引レコードが4件あります。
      * The files deliberately have different record counts.
      * 这些文件特意使用不同的记录数。
      * これらのファイルは意図的にレコード件数を変えています。
      * The displayed output alternates while both files are active.
      * 两个文件都处于活动状态时，显示输出交替进行。
      * 両方のファイルが稼働中は、表示出力が交互に行われます。
      * After account EOF, transaction records continue to be read.
      * 账户文件到达EOF后，仍继续读取交易记录。
      * 口座ファイルがEOFになった後も、取引レコードの読み込みを続けます。
      * After transaction EOF, account records continue to be read.
      * 交易文件到达EOF后，仍继续读取账户记录。
      * 取引ファイルがEOFになった後も、口座レコードの読み込みを続けます。
      * No account-to-transaction matching is done in this lesson.
      * 本课不进行账户与交易的匹配。
      * このレッスンでは口座と取引の照合を行いません。
      * The following lesson will match records by a sorted key.
      * 下一课将按排序后的键匹配记录。
      * 次のレッスンでは、ソート済みキーでレコードを照合します。
      * Production jobs should log file names and batch identifiers.
      * 生产作业应记录文件名和批次标识符。
      * 本番ジョブではファイル名とバッチ識別子をログに記録してください。
      * This example keeps output short for classroom inspection.
      * 此示例保持简短输出，便于课堂检查。
      * この例では、授業で確認しやすいよう出力を短くしています。
      * File status is checked after each READ and each CLOSE.
      * 每次READ和CLOSE后都会检查文件状态。
      * READとCLOSEのたびにファイルステータスを確認します。
      * The file status begins with 00 after a successful OPEN.
      * OPEN成功后，文件状态为00。
      * OPENが成功すると、ファイルステータスは00になります。
      * File status 10 denotes normal sequential end of file.
      * 文件状态10表示顺序读取正常到达文件末尾。
      * ファイルステータス10は、順次読み込みの正常なファイル終端を示します。
      * OPEN failure prevents the batch from entering the read loop.
      * OPEN失败会阻止批处理进入读取循环。
      * OPENに失敗すると、バッチは読み込みループに入りません。
      * STOP RUN returns the accumulated RETURN-CODE to the shell.
      * STOP RUN会将累计的RETURN-CODE返回给shell。
      * STOP RUNは、累積したRETURN-CODEをシェルに返します。
      * Run from the lesson directory to locate both fixtures.
      * 请从课程目录运行，以便找到两个样例文件。
      * 両方のフィクスチャを見つけられるよう、レッスンのディレクトリから実行してください。
      * Copy both inputs beside the executable for isolated testing.
      * 将两个输入文件复制到可执行文件旁，以便独立测试。
      * 個別にテストするには、両方の入力を実行ファイルと同じ場所にコピーしてください。
      * No output file is created or modified by this program.
      * 此程序不会创建或修改输出文件。
      * このプログラムは出力ファイルを作成も変更もしません。
      * Lesson 19 introduces independent sequential input streams.
      * 第19课介绍独立的顺序输入流。
      * レッスン19では、独立した順次入力ストリームを紹介します。
      * Lesson 20 will build on these files for ordered matching.
      * 第20课将在这些文件基础上进行有序匹配。
      * レッスン20では、これらのファイルを使って順序付き照合を行います。
      * An EOF flag is never shared between the two input files.
      * 两个输入文件不会共用EOF标志。
      * 2つの入力ファイルでEOFフラグを共有することはありません。
      * Record counts are displayed as three-digit numeric fields.
      * 记录数以三位数字字段显示。
      * レコード件数は3桁の数値フィールドで表示します。
      * The sample files contain fewer than one thousand records.
      * 样例文件包含的记录少于一千条。
      * サンプルファイルのレコード数は1000件未満です。
      * End-of-file is a normal input state, not an I/O failure.
      * 文件结束是正常输入状态，不是I/O错误。
      * ファイル終端は正常な入力状態であり、I/Oエラーではありません。
      * The account stream retains its current position independently.
      * 账户流独立保留自己的当前位置。
      * 口座ストリームは現在位置を独立して保持します。
      * The transaction stream has its own current position.
      * 交易流有自己的当前位置。
      * 取引ストリームには独自の現在位置があります。
      * Each successful READ advances only the selected file.
      * 每次READ成功只推进所选文件。
      * READが成功するたびに、選択したファイルだけが進みます。
      * A failed second OPEN releases the already opened first file.
      * 第二次OPEN失败时会释放已打开的第一个文件。
      * 2つ目のOPENに失敗した場合、すでに開いた最初のファイルを解放します。
      * Empty-input behavior is part of the exercise scenarios.
      * 空输入的行为也是练习场景的一部分。
      * 空入力時の動作も演習シナリオの一部です。
      * The fixtures use printable ASCII characters for readability.
      * 样例使用可打印ASCII字符以便阅读。
      * フィクスチャは読みやすいよう、印字可能なASCII文字を使います。
      * Parsing and account matching are out of scope here.
      * 本课不涉及解析和账户匹配。
      * ここでは解析と口座照合を扱いません。
      * The summary confirms the number read from each input file.
      * 摘要确认从每个输入文件读取的数量。
      * サマリーで各入力ファイルから読み取った件数を確認できます。
      * Close both files before printing the final summary.
      * 打印最终摘要前先关闭两个文件。
      * 最終サマリーを表示する前に、両方のファイルを閉じます。
      * The line-sequential runtime handles physical line endings.
      * 行顺序运行时负责处理物理行结束符。
      * 行順次ランタイムが物理行末を処理します。
      * No newline bytes are copied into the COBOL record fields.
      * 换行字节不会复制到COBOL记录字段中。
      * 改行バイトがCOBOLレコードのフィールドにコピーされることはありません。
      * This demonstration uses two inputs; the same pattern extends.
      * 此示例使用两个输入；同一模式也可扩展。
      * この例では入力を2つ使いますが、同じパターンを拡張できます。
      * For more inputs, give every file its own status and EOF state.
      * 输入更多文件时，每个文件都应有自己的状态和EOF标志。
      * 入力が増える場合は、各ファイルに独自のステータスとEOF状態を持たせてください。
      * Do not stop all streams when only one reaches end of file.
      * 只有一个流到达文件末尾时，不要停止所有流。
      * 1つのストリームだけがファイル終端に達したとき、すべてのストリームを停止しないでください。
      * A complete batch must define a policy for every input failure.
      * 完整的批处理必须为每种输入失败情况定义处理策略。
      * 完全なバッチでは、すべての入力エラーに対する方針を定める必要があります。
      * This lesson uses immediate stop after the first READ error.
      * 本课采用首次READ错误后立即停止的策略。
      * このレッスンでは、最初のREADエラー後に直ちに停止します。
      * The program never reopens or rewinds either input stream.
      * 程序不会重新打开或倒回任一输入流。
      * プログラムはどちらの入力ストリームも開き直しませんし、巻き戻しません。
      * Sequential READ consumes records in their original file order.
      * 顺序READ按记录在文件中的原始顺序读取。
      * 順次READは、ファイル内の元の順序でレコードを読み込みます。
      * Both input files are required and are not OPTIONAL.
      * 两个输入文件都是必需的，且未声明为OPTIONAL。
      * 両方の入力ファイルが必須であり、OPTIONALではありません。
      * These records are read-only and remain unchanged.
      * 这些记录以只读方式处理，不会被更改。
      * これらのレコードは読み取り専用で、変更されません。
