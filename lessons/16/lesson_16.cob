      * Lesson 16: write classified transaction results to two files.
      * 第16课：将分类交易结果写入两个文件。
      * レッスン 16: 機密扱いのトランザクション結果を 2 つのファイルに書き込みます。
      * OPEN OUTPUT replaces any previous contents of each output file.
      * OPEN OUTPUT 替换每个输出文件以前的任何内容。
      * OPEN OUTPUT は、各出力ファイルの以前の内容を置き換えます。
      * Each WRITE sends one complete line-sequential result record.
      * 每个 WRITE 发送一个完整的行顺序结果记录。
      * 各 WRITE は、1 つの完全な行順次結果レコードを送信します。
      * Accepted and rejected records go to separate destinations.
      * 接受和拒绝的记录将发送到不同的目的地。
      * 承認されたレコードと拒否されたレコードは別々の宛先に送られます。
      * The fixed result strings are exactly 35 characters long.
      * 固定结果字符串的长度正好是 35 个字符。
      * 固定結果文字列の長さはちょうど 35 文字です。
      * This sample focuses on output, using preclassified records.
      * 此示例侧重于使用预先分类的记录的输出。
      * このサンプルは、事前に分類されたレコードを使用した出力に焦点を当てています。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCEPTED-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCEPTED-FILE.
       01 FD-ACCEPTED-RECORD PIC X(35).
       FD REJECTED-FILE.
       01 FD-REJECTED-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
      * Open both outputs before writing any result records.
      * 在写入任何结果记录之前打开两个输出。
      * 結果レコードを書き込む前に、両方の出力を開いてください。
       0000-MAIN.
           OPEN OUTPUT ACCEPTED-FILE
           IF WS-ACCEPTED-STATUS NOT = "00"
               DISPLAY "OPEN=ACCEPTED FAILED STATUS="
                   WS-ACCEPTED-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCEPTED OK"
           OPEN OUTPUT REJECTED-FILE
           IF WS-REJECTED-STATUS NOT = "00"
               DISPLAY "OPEN=REJECTED FAILED STATUS="
                   WS-REJECTED-STATUS
               CLOSE ACCEPTED-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=REJECTED OK"
           PERFORM 1000-LOAD-RESULTS
           PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1
               UNTIL WS-RESULT-NUMBER > 4
                   OR WS-WRITE-ERROR = "Y"
               PERFORM 2000-WRITE-ONE-RESULT
           END-PERFORM
           PERFORM 9000-CLOSE-OUTPUTS
           IF WS-WRITE-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Load two accepted and two rejected fixed result records.
      * 加载两个已接受和两个已拒绝的固定结果记录。
      * 2 つの承認された固定結果レコードと 2 つの拒否された固定結果レコードをロードします。
       1000-LOAD-RESULTS.
           MOVE "A" TO WS-RESULT-DESTINATION(1)
           MOVE "TXN-000001|0001234567|D|000125.50|A"
               TO WS-RESULT-TEXT(1)
           MOVE "A" TO WS-RESULT-DESTINATION(2)
           MOVE "TXN-000002|0007654321|T|000040.00|A"
               TO WS-RESULT-TEXT(2)
           MOVE "R" TO WS-RESULT-DESTINATION(3)
           MOVE "TXN-000003|0002468101|X|000000.00|R"
               TO WS-RESULT-TEXT(3)
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4).
      * Route one preclassified record to its matching output file.
      * 将一个预分类记录路由到其匹配的输出文件。
      * 事前に分類された 1 つのレコードを、対応する出力ファイルにルーティングします。
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-ACCEPTED-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-ACCEPTED-STATUS = "00"
                       ADD 1 TO WS-ACCEPTED-COUNT
                       DISPLAY "WRITE=ACCEPTED"
                           " TXN=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "WRITE=ACCEPTED FAILED STATUS="
                           WS-ACCEPTED-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-REJECTED-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-REJECTED-STATUS = "00"
                       ADD 1 TO WS-REJECTED-COUNT
                       DISPLAY "WRITE=REJECTED"
                           " TXN=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "WRITE=REJECTED FAILED STATUS="
                           WS-REJECTED-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN OTHER
                   DISPLAY "WRITE=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
      * Close both output streams after the write loop.
      * 写循环后关闭两个输出流。
      * 書き込みループの後に両方の出力ストリームを閉じます。
       9000-CLOSE-OUTPUTS.
           CLOSE ACCEPTED-FILE
           IF WS-ACCEPTED-STATUS = "00"
               DISPLAY "CLOSE=ACCEPTED OK"
           ELSE
               DISPLAY "CLOSE=ACCEPTED FAILED STATUS="
                   WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE REJECTED-FILE
           IF WS-REJECTED-STATUS = "00"
               DISPLAY "CLOSE=REJECTED OK"
           ELSE
               DISPLAY "CLOSE=REJECTED FAILED STATUS="
                   WS-REJECTED-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY ACCEPTED=" WS-ACCEPTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT.
      * OPEN OUTPUT creates a file or replaces its old contents.
      * OPEN OUTPUT 创建文件或替换其旧内容。
      * OPEN OUTPUT は、ファイルを作成するか、その古い内容を置き換えます。
      * LINE SEQUENTIAL ends every written record with a newline.
      * LINE SEQUENTIAL 以换行符结束每个写入记录。
      * LINE SEQUENTIAL は、書き込まれたすべてのレコードを改行で終了します。
      * The FD record size and source result size are both 35 bytes.
      * FD记录大小和源结果大小都是35字节。
      * FD レコード サイズとソース結果サイズは両方とも 35 バイトです。
      * Each successful WRITE sets its file status to 00.
      * 每个成功的 WRITE 将其文件状态设置为 00。
      * WRITE が成功するたびに、ファイルのステータスが 00 に設定されます。
      * The two files have independent file status fields.
      * 这两个文件具有独立的文件状态字段。
      * 2 つのファイルには独立したファイル ステータス フィールドがあります。
      * The output table's A or R marker selects the destination.
      * 输出表的 A 或 R 标记决定目标文件。
      * 出力テーブルの A または R マーカーが宛先を選択します。
      * Result records are written in their original table order.
      * 结果记录按其原始表顺序写入。
      * 結果レコードは、元のテーブルの順序で書き込まれます。
      * Counts increase only after a successful WRITE.
      * 仅在成功写入后计数才会增加。
      * カウントは、書き込みが成功した後にのみ増加します。
      * A failed OPEN stops before the corresponding file is written.
      * 失败的 OPEN 将在相应文件写入之前停止。
      * 失敗した OPEN は、対応するファイルが書き込まれる前に停止します。
      * A failed WRITE sets an error flag and stops later writes.
      * 失败的写入会设置错误标志并停止以后的写入。
      * WRITE が失敗すると、エラー フラグが設定され、その後の書き込みが停止されます。
      * Both opened files are closed after the write loop.
      * 两个已打开的文件在写入循环结束后关闭。
      * 両方のファイルは、書き込みループの後に閉じられます。
      * The summary reports records successfully written per file.
      * 摘要报告每个文件成功写入的记录。
      * 要約レポートでは、ファイルごとに正常に書き込まれたレコードが記録されます。
      * Output paths are relative to the program's current directory.
      * 输出路径是相对于程序的当前目录的。
      * 出力パスは、プログラムの現在のディレクトリからの相対パスです。
      * Running in a temporary directory keeps generated files separate.
      * 在临时目录中运行使生成的文件保持独立。
      * 一時ディレクトリで実行すると、生成されたファイルは別々に保持されます。
      * OPEN OUTPUT is not append mode; old data is replaced.
      * OPEN OUTPUT 不是追加模式；旧数据被替换。
      * OPEN OUTPUT は追加モードではありません。古いデータは置き換えられます。
      * Use OPEN EXTEND when a later lesson needs append behavior.
      * 当后面的课程需要追加行为时，请使用 OPEN EXTEND。
      * 後のレッスンで追加動作が必要な場合は、OPEN EXTEND を使用します。
      * The example does not read the prior lesson's input file.
      * 该示例不会读取上一课的输入文件。
      * この例では、前のレッスンの入力ファイルを読み取りません。
      * Its rows are already classified to keep writing as the focus.
      * 它的行已经被分类，以保持书写为焦点。
      * その行は、焦点として書き込みを続けるためにすでに分類されています。
      * No account balance calculation is performed here.
      * 这里不进行账户余额计算。
      * ここでは口座残高の計算は行われません。
      * The lesson 22 project will combine reads, rules, and output.
      * 第 22 课项目将结合阅读、规则和输出。
      * レッスン 22 プロジェクトでは、読み取り、ルール、出力を組み合わせます。
      * A successful CLOSE flushes outstanding record buffers.
      * 成功的 CLOSE 会刷新未完成的记录缓冲区。
      * CLOSE が成功すると、未処理のレコード バッファがフラッシュされます。
      * STOP RUN ends the file writing demonstration.
      * STOP RUN 结束文件写入演示。
      * STOP RUN はファイル書き込みデモを終了します。
