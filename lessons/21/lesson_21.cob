      * Lesson 21: sort an unsorted account file with procedures.
      * 第21课：使用过程对未排序的账户文件排序。
      * レッスン21：手続きで未ソートの口座ファイルをソートします。
      * The input procedure RELEASEs records to the sort work file.
      * 输入过程将记录RELEASE到排序工作文件。
      * 入力手続きはレコードをソート作業ファイルにRELEASEします。
      * The output procedure RETURNs rows in ascending key order.
      * 输出过程按键升序RETURN记录。
      * 出力手続きはキーの昇順でレコードをRETURNします。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SORT21.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT UNSORTED-INPUT
               ASSIGN TO "accounts-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
       DATA DIVISION.
       FILE SECTION.
       FD UNSORTED-INPUT.
       01 FD-INPUT-RECORD PIC X(27).
       SD SORT-WORK.
       01 SD-SORT-RECORD.
          05 SD-ACCOUNT-NUMBER PIC X(10).
          05 SD-CUSTOMER-ID PIC X(8).
          05 SD-ACCOUNT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-OUTPUT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * SORT controls the input, sort, and output stages.
      * SORT控制输入、排序和输出阶段。
      * SORTが入力、ソート、出力の各段階を制御します。
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-ACCOUNT-NUMBER
               INPUT PROCEDURE 1000-LOAD-INPUT
               OUTPUT PROCEDURE 2000-RETURN-SORTED.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "SORT=FAILED STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY INPUT=" WS-INPUT-COUNT
               " OUTPUT=" WS-OUTPUT-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Read input rows and release each valid record to SORT.
      * 读取输入行，并将每条有效记录RELEASE给SORT。
      * 入力行を読み込み、有効な各レコードをSORTにRELEASEします。
       1000-LOAD-INPUT.
           OPEN INPUT UNSORTED-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE UNSORTED-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "CLOSE=INPUT FAILED STATUS="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * Load one row; AT END ends only the input procedure loop.
      * 加载一行；AT END只结束输入过程的循环。
      * 1行を読み込みます。AT ENDで終了するのは入力手続きのループだけです。
       1100-READ-AND-RELEASE.
           READ UNSORTED-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       MOVE FD-INPUT-RECORD TO SD-SORT-RECORD
                       RELEASE SD-SORT-RECORD
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-INPUT-COUNT
                       ELSE
                           DISPLAY "RELEASE=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "READ=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Return sorted rows until SORT reports its output EOF.
      * 逐条RETURN排序后的记录，直到SORT报告输出EOF。
      * SORTが出力EOFを報告するまで、ソート済みレコードをRETURNします。
       2000-RETURN-SORTED.
           PERFORM UNTIL WS-SORT-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               RETURN SORT-WORK
                   AT END
                       MOVE "Y" TO WS-SORT-EOF
                   NOT AT END
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-OUTPUT-COUNT
                           DISPLAY "SORTED ACCOUNT="
                               SD-ACCOUNT-NUMBER
                               " CUSTOMER=" SD-CUSTOMER-ID
                               " BALANCE=" SD-ACCOUNT-BALANCE
                       ELSE
                           DISPLAY "RETURN=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
               END-RETURN
           END-PERFORM.
      * The input file is intentionally not in key order.
      * 输入文件特意没有按键排序。
      * 入力ファイルは意図的にキー順ではありません。
      * Its record width is 27 characters, matching Lesson 17.
      * 记录宽度为27个字符，与第17课相同。
      * レコード幅は27文字で、レッスン17と同じです。
      * Account number occupies positions 1 through 10.
      * 账户号码占据第1至第10位。
      * 口座番号は1～10桁を占めます。
      * Customer id occupies positions 11 through 18.
      * 客户ID占据第11至第18位。
      * 顧客IDは11～18桁を占めます。
      * Balance occupies positions 19 through 27.
      * 余额占据第19至第27位。
      * 残高は19～27桁を占めます。
      * The sort work record uses the same field layout.
      * 排序工作记录使用相同的字段布局。
      * ソート作業レコードも同じフィールドレイアウトを使います。
      * SORT-WORK is described with SD, not FD.
      * SORT-WORK使用SD而不是FD定义。
      * SORT-WORKはFDではなくSDで記述します。
      * SORT owns the work file; the program does not OPEN it.
      * 工作文件由SORT管理；程序不会OPEN它。
      * 作業ファイルはSORTが管理し、プログラムはOPENしません。
      * The input procedure is run as part of SORT's input stage.
      * 输入过程作为SORT输入阶段的一部分运行。
      * 入力手続きはSORTの入力段階の一部として実行されます。
      * RELEASE adds the current SD record to the sort work file.
      * RELEASE将当前SD记录添加到排序工作文件。
      * RELEASEは現在のSDレコードをソート作業ファイルに追加します。
      * The input procedure reads until the source file reaches EOF.
      * 输入过程会持续读取，直到源文件到达EOF。
      * 入力手続きはソースファイルがEOFに達するまで読み込みます。
      * FILE STATUS distinguishes EOF from other input failures.
      * FILE STATUS用于区分EOF和其他输入错误。
      * FILE STATUSでEOFとその他の入力エラーを区別します。
      * The source file is closed before the sort output procedure.
      * 排序输出过程开始前会关闭源文件。
      * ソート出力手続きの前にソースファイルを閉じます。
      * The sort stage orders records by the declared key.
      * 排序阶段按声明的键排列记录。
      * ソート段階では、宣言したキーでレコードを並べます。
      * The account key is fixed-width text with leading zeroes.
      * 账户键是带前导零的定宽文本。
      * 口座キーは先頭ゼロを含む固定幅テキストです。
      * No duplicate keys occur in this fixture.
      * 此样例中没有重复键。
      * このフィクスチャに重複キーはありません。
      * The output procedure is run after sorting is complete.
      * 排序完成后运行输出过程。
      * ソート完了後に出力手続きを実行します。
      * RETURN retrieves one sorted row at a time.
      * RETURN每次取回一条已排序记录。
      * RETURNはソート済みレコードを1件ずつ取得します。
      * RETURN AT END terminates the output procedure loop.
      * RETURN AT END会结束输出过程循环。
      * RETURN AT ENDで出力手続きのループを終了します。
      * The output procedure displays rows in ascending key order.
      * 输出过程按键升序显示记录。
      * 出力手続きはキーの昇順でレコードを表示します。
      * Input and output counts should be equal after successful SORT.
      * SORT成功后，输入和输出计数应相等。
      * SORTが成功すれば、入力件数と出力件数は等しくなるはずです。
      * Empty input produces zero RELEASE and zero RETURN records.
      * 空输入产生零次RELEASE和零条RETURN记录。
      * 入力が空の場合、RELEASEは0回、RETURNレコードも0件です。
      * The input count increments only after successful RELEASE.
      * 只有RELEASE成功后才增加输入计数。
      * RELEASEの成功後に限り、入力件数を増やします。
      * The output count increments only after successful RETURN.
      * 只有RETURN成功后才增加输出计数。
      * RETURNの成功後に限り、出力件数を増やします。
      * A source OPEN, READ, or CLOSE error sets the failure flag.
      * 源文件OPEN、READ或CLOSE出错时会设置失败标志。
      * ソースのOPEN、READ、CLOSEでエラーが起きると失敗フラグを設定します。
      * A nonzero SORT-RETURN reports RELEASE, RETURN, or SORT failure.
      * 非零SORT-RETURN表示RELEASE、RETURN或SORT失败。
      * SORT-RETURNがゼロ以外の場合、RELEASE、RETURN、またはSORTの失敗を示します。
      * The process returns status 1 after a detected I/O failure.
      * 检测到I/O错误后，进程返回状态1。
      * I/Oエラーを検出すると、プロセスはステータス1を返します。
      * This program displays sorted rows and creates no output file.
      * 此程序显示排序后的记录，不创建输出文件。
      * このプログラムはソート済みレコードを表示し、出力ファイルは作成しません。
      * The sort work area can exceed a small in-memory table.
      * 排序工作区域可以大于小型内存表。
      * ソート作業領域は、小規模なメモリ内テーブルを超えるサイズにできます。
      * GnuCOBOL may use temporary storage for large sorts.
      * GnuCOBOL可能会为大型排序使用临时存储。
      * GnuCOBOLは、大規模なソートで一時ストレージを使う場合があります。
      * The fixture uses printable characters and one physical row.
      * 样例使用可打印字符和单个物理行。
      * フィクスチャは印字可能文字を使い、物理行は1行です。
      * Each row has no delimiter between its three fixed-width fields.
      * 每行三个定宽字段之间没有分隔符。
      * 各行の3つの固定幅フィールドの間に区切り文字はありません。
      * The line ending is not part of the 27-character FD record.
      * 行结束符不属于27字符的FD记录。
      * 行末文字は27文字のFDレコードに含まれません。
      * Run from this directory so ASSIGN finds the input fixture.
      * 请从此目录运行，以便ASSIGN能找到输入样例。
      * ASSIGNで入力フィクスチャを見つけられるよう、このディレクトリから実行してください。
      * Sorting does not validate account or customer identifiers.
      * 排序不会验证账户或客户标识符。
      * ソート処理は口座や顧客の識別子を検証しません。
      * Sorting does not change the input file's original order.
      * 排序不会更改输入文件的原始顺序。
      * ソートによって入力ファイルの元の順序が変わることはありません。
      * The program does not depend on input key order.
      * 程序不依赖输入键的顺序。
      * プログラムは入力キーの順序に依存しません。
      * The sort result is ascending by account number only.
      * 排序结果仅按账户号码升序排列。
      * ソート結果は口座番号だけを基準に昇順になります。
      * A later batch can feed this ordered stream into file matching.
      * 后续批处理可以将此有序流用于文件匹配。
      * 後続のバッチで、この順序付きストリームをファイル照合に渡せます。
      * Lesson 20 consumes ordered account keys for sequential matching.
      * 第20课使用有序账户键进行顺序匹配。
      * レッスン20では、順序付き口座キーを使って逐次照合します。
      * The input procedure must terminate like a performed procedure.
      * 输入过程必须像被PERFORM的过程一样正常结束。
      * 入力手続きはPERFORMされた手続きと同様に終了する必要があります。
      * The output procedure must terminate after its final RETURN.
      * 输出过程必须在最后一次RETURN后结束。
      * 出力手続きは最後のRETURN後に終了する必要があります。
      * SORT invokes both named procedures in their respective stages.
      * SORT会在各自阶段调用这两个命名过程。
      * SORTは各段階で、それぞれの名前付き手続きを呼び出します。
      * RELEASE is legal in the SORT input procedure.
      * 在SORT输入过程中可以使用RELEASE。
      * SORTの入力手続きではRELEASEを使用できます。
      * RETURN is legal in the SORT output procedure.
      * 在SORT输出过程中可以使用RETURN。
      * SORTの出力手続きではRETURNを使用できます。
      * SORT-RETURN is checked after each sort-work operation.
      * 每次排序工作操作后都会检查SORT-RETURN。
      * ソート作業の各操作後にSORT-RETURNを確認します。
      * The final summary makes dropped or duplicated rows visible.
      * 最终摘要会显示是否有记录丢失或重复。
      * 最終サマリーでレコードの欠落や重複を確認できます。
      * All counters are three-digit fields for this small exercise.
      * 此小型练习中的计数器都是三位数字字段。
      * この小規模な演習では、すべてのカウンターが3桁フィールドです。
      * The expected input contains four distinct account keys.
      * 预期输入包含四个不同的账户键。
      * 想定入力には異なる口座キーが4つ含まれます。
      * Their output sequence is independent of their input sequence.
      * 输出顺序与输入顺序无关。
      * 出力順は入力順に左右されません。
      * STOP RUN returns the final RETURN-CODE to the shell.
      * STOP RUN会将最终RETURN-CODE返回给shell。
      * STOP RUNは最終RETURN-CODEをシェルに返します。
