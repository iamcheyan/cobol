      * Lesson 17: read raw fixed records and write a fixed layout.
      * 第17课：读取原始定长记录并按固定布局写出。
      * レッスン17：固定長レコードを読み取り、固定レイアウトで書き出します。
      * Sequential binary files have no line-ending record delimiters.
      * 顺序二进制文件的记录之间没有行结束分隔符。
      * 順次バイナリファイルでは、レコードを区切る行末文字はありません。
      * Each sample input record is exactly 27 display bytes.
      * 每条示例输入记录恰好占27个显示字符字节。
      * 各サンプル入力レコードは、表示文字でちょうど27バイトです。
      * Field positions are account 1-10, customer 11-18, balance 19-27.
      * 字段位置：账户1–10、客户11–18、余额19–27。
      * フィールド位置：口座1–10、顧客11–18、残高19–27。
      * Output positions are customer 1-8, account 9-18, balance 19-27.
      * 输出位置：客户1–8、账户9–18、余额19–27。
      * 出力位置：顧客1–8、口座9–18、残高19–27です。
      * Input and output fixtures are raw concatenated record bytes.
      * 输入和输出样例由连续拼接的原始记录字节组成。
      * 入力と出力のフィクスチャは、レコードのバイト列をそのまま連結したものです。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXED17.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "accounts.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT BALANCE-FILE
               ASSIGN TO "balances.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-BALANCE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD BALANCE-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-BALANCE-RECORD.
          05 FD-OUT-CUSTOMER-ID PIC X(8).
          05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
          05 FD-OUT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-BALANCE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * Open the raw master file and create the fixed-width output file.
      * 打开原始主文件并创建定宽输出文件。
      * 生のマスターファイルを開き、固定幅の出力ファイルを作成します。
       0000-MAIN.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "OPEN=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               CLOSE ACCOUNT-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=INPUT OK OPEN=OUTPUT OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 1000-READ-AND-WRITE
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Read one 27-byte record and write its reordered fields.
      * 读取一条27字节记录，并写出重新排列的字段。
      * 27バイトのレコードを1件読み取り、並べ替えたフィールドを書き出します。
       1000-READ-AND-WRITE.
           READ ACCOUNT-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   PERFORM 1100-WRITE-BALANCE-RECORD
           END-READ.
      * Move named fields into the output record's declared positions.
      * 将命名字段移至输出记录所声明的位置。
      * 名前付きフィールドを、出力レコードで定義した位置に移します。
       1100-WRITE-BALANCE-RECORD.
           MOVE FD-CUSTOMER-ID TO FD-OUT-CUSTOMER-ID
           MOVE FD-ACCOUNT-NUMBER TO FD-OUT-ACCOUNT-NUMBER
           MOVE FD-ACCOUNT-BALANCE TO FD-OUT-BALANCE
           WRITE FD-BALANCE-RECORD
           IF WS-BALANCE-STATUS = "00"
               ADD 1 TO WS-RECORD-COUNT
               DISPLAY "WROTE ACCOUNT=" FD-OUT-ACCOUNT-NUMBER
                   " CUSTOMER=" FD-OUT-CUSTOMER-ID
                   " BALANCE=" FD-OUT-BALANCE
           ELSE
               DISPLAY "WRITE=FAILED STATUS=" WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Close both files and report records successfully written.
      * 关闭两个文件并报告成功写入的记录数。
      * 両方のファイルを閉じ、正常に書き込めたレコード数を報告します。
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "CLOSE=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "CLOSE=OK RECORDS=" WS-RECORD-COUNT.
      * RECORD CONTAINS and the FD fields agree on 27 bytes.
      * RECORD CONTAINS子句与FD字段定义的长度都是27字节。
      * RECORD CONTAINSとFDフィールド定義は、どちらも27バイトです。
      * DISPLAY fields use text bytes and implied decimal positions.
      * DISPLAY字段使用文本字节，小数点位置由隐含小数位表示。
      * DISPLAYフィールドはテキストのバイトを使い、小数点位置は暗黙的に表します。
      * The V in PIC 9(7)V99 occupies no physical file byte.
      * PIC 9(7)V99中的V不占用实际文件字节。
      * PIC 9(7)V99のVは、ファイル上の実バイトを占めません。
      * Therefore the balance occupies nine display digit bytes.
      * 因此，余额占用九个显示数字字节。
      * したがって、残高は表示数字9桁分のバイトを占めます。
      * The input fixture is three 27-byte records, with no delimiters.
      * 输入样例由三条27字节记录组成，记录间没有分隔符。
      * 入力フィクスチャは27バイトのレコード3件で構成され、区切り文字はありません。
      * The second record begins exactly at byte offset 28.
      * 第二条记录恰好从字节偏移28处开始。
      * 2件目のレコードはバイトオフセット28から始まります。
      * The output record begins with customer ID instead of account ID.
      * 输出记录以客户ID开头，而不是账户ID。
      * 出力レコードは口座IDではなく、顧客IDから始まります。
      * Its next ten bytes hold the account number.
      * 接下来的十个字节存放账户号码。
      * 続く10バイトには口座番号が格納されます。
      * The last nine bytes hold the same numeric balance.
      * 最后九个字节存放相同的数值余额。
      * 最後の9バイトには同じ数値の残高が格納されます。
      * ORGANIZATION SEQUENTIAL means raw fixed-record byte placement.
      * ORGANIZATION SEQUENTIAL表示原始定长记录的字节布局。
      * ORGANIZATION SEQUENTIALは、生の固定長レコードをバイト単位で配置する形式です。
      * It is not the same physical format as LINE SEQUENTIAL text.
      * 它与LINE SEQUENTIAL文本的物理格式不同。
      * LINE SEQUENTIALテキストとは物理形式が異なります。
      * Do not insert newline characters between sequential records.
      * 不要在顺序记录之间插入换行符。
      * 順次レコードの間に改行文字を挿入しないでください。
      * Text editors add line endings and corrupt this fixture.
      * 文本编辑器会添加行结束符，从而破坏此样例。
      * テキストエディターは行末文字を追加するため、このフィクスチャが壊れます。
      * Each successful READ supplies one FD record to the program.
      * 每次READ成功都会向程序提供一条FD记录。
      * READが成功するたびに、FDレコードが1件プログラムに渡されます。
      * READ AT END stops the loop without creating an output record.
      * READ AT END会停止循环，且不会创建输出记录。
      * READ AT ENDはループを終了し、出力レコードは作成しません。
      * Each successful WRITE adds exactly one 27-byte output record.
      * 每次WRITE成功都会添加一条恰好27字节的输出记录。
      * WRITEが成功するたびに、ちょうど27バイトの出力レコードが1件追加されます。
      * Output file size is record count multiplied by 27 bytes.
      * 输出文件大小等于记录数乘以27字节。
      * 出力ファイルのサイズは、レコード数に27バイトを掛けた値です。
      * File status 00 indicates successful open, read, write, or close.
      * 文件状态00表示打开、读取、写入或关闭成功。
      * ファイルステータス00は、OPEN、READ、WRITE、CLOSEの成功を示します。
      * The program preserves account order from the input file.
      * 程序保留输入文件中的账户顺序。
      * プログラムは入力ファイル内の口座順を維持します。
      * No sort, search, or arithmetic changes the account balances.
      * 排序、查找和算术运算都不会更改账户余额。
      * ソート、検索、算術演算によって口座残高が変更されることはありません。
      * OPEN OUTPUT replaces any older balances.dat contents.
      * OPEN OUTPUT会替换balances.dat中已有的内容。
      * OPEN OUTPUTはbalances.datの既存内容を置き換えます。
      * Paths are relative to the process current working directory.
      * 路径相对于进程的当前工作目录。
      * パスはプロセスの現在の作業ディレクトリからの相対パスです。
      * Run in a temporary directory containing accounts.dat.
      * 请在包含accounts.dat的临时目录中运行。
      * accounts.datを置いた一時ディレクトリで実行してください。
      * The sample uses ASCII display characters and numeric digits.
      * 此示例使用ASCII显示字符和数字。
      * このサンプルではASCIIの表示文字と数字を使います。
      * Binary COMP data would need a separately specified layout.
      * 二进制COMP数据需要单独指定布局。
      * バイナリCOMPデータには、別途レイアウトの指定が必要です。
      * Input and output field order differs; total size remains equal.
      * 输入和输出的字段顺序不同，但总长度相同。
      * 入力と出力ではフィールド順が異なりますが、合計サイズは同じです。
      * Verify field offsets before exchanging a fixed-width data file.
      * 交换定宽数据文件前，请核对字段偏移。
      * 固定幅データファイルを受け渡す前に、フィールドのオフセットを確認してください。
      * A missing input file is reported before the output is opened.
      * 输入文件缺失时，会在打开输出文件前报告错误。
      * 入力ファイルが見つからない場合、出力ファイルを開く前にエラーを報告します。
      * A successful output close flushes the fixed records.
      * 成功关闭输出文件会刷新定长记录。
      * 出力ファイルを正常に閉じると、固定長レコードがフラッシュされます。
      * STOP RUN ends the fixed-record conversion example.
      * STOP RUN结束此定长记录转换示例。
      * STOP RUNは、この固定長レコード変換の例を終了します。
