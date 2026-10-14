      * Lesson 20: match two sorted account files by account number.
      * 第20课：按账户号码匹配两个已排序的账户文件。
      * レッスン20：ソート済みの2つの口座ファイルを口座番号で照合します。
      * Master rows are 27 characters; transaction rows are 20.
      * 主记录为27个字符；交易记录为20个字符。
      * マスターレコードは27文字、取引レコードは20文字です。
      * Each input is sorted ascending by its ten-character key.
      * 每个输入文件都按十字符键升序排列。
      * 各入力は10文字のキーで昇順にソートされています。
      * The merge classifies matches and records present on one side.
      * 归并过程将记录分类为匹配或仅存在于一侧。
      * マージ処理で、照合一致と片側だけに存在するレコードを分類します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH20.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT DAILY-TRANSACTIONS
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-MASTER.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD DAILY-TRANSACTIONS.
       01 FD-TRANSACTION-RECORD.
          05 FD-TRANSACTION-ACCOUNT PIC X(10).
          05 FD-TRANSACTION-TYPE PIC X.
          05 FD-TRANSACTION-AMOUNT PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Open both sorted inputs before positioning either stream.
      * 定位任一流之前先打开两个已排序的输入文件。
      * どちらかのストリームを位置付ける前に、両方のソート済み入力を開きます。
       0000-MAIN.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-MASTER
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM 1000-READ-ACCOUNT
           PERFORM 2000-READ-TRANSACTION
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 3000-MATCH-CURRENT-RECORDS
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Compare current keys and advance the lower or equal stream.
      * 比较当前键，并推进键值较小或相等的流。
      * 現在のキーを比較し、小さい方または一致した両方のストリームを進めます。
       3000-MATCH-CURRENT-RECORDS.
           EVALUATE TRUE
               WHEN WS-ACCOUNT-EOF = "Y"
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN WS-TRANSACTION-EOF = "Y"
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER < FD-TRANSACTION-ACCOUNT
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER > FD-TRANSACTION-ACCOUNT
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN OTHER
                   PERFORM 4200-REPORT-MATCH
                   PERFORM 1000-READ-ACCOUNT
                   IF WS-IO-ERROR = "N"
                       PERFORM 2000-READ-TRANSACTION
                   END-IF
           END-EVALUATE.
      * Read the next master row or mark only this stream at EOF.
      * 读取下一条主记录，或仅将此流标记为EOF。
      * 次のマスターレコードを読むか、このストリームだけをEOFとして記録します。
       1000-READ-ACCOUNT.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Read the next transaction row or mark only this stream at EOF.
      * 读取下一条交易记录，或仅将此流标记为EOF。
      * 次の取引レコードを読むか、このストリームだけをEOFとして記録します。
       2000-READ-TRANSACTION.
           READ DAILY-TRANSACTIONS
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * The master key sorts before the current transaction key.
      * 主键排序位置早于当前交易键。
      * マスターキーは現在の取引キーより前に並びます。
       4000-REPORT-ACCOUNT-ONLY.
           ADD 1 TO WS-ACCOUNT-ONLY-COUNT
           DISPLAY "ACCOUNT_ONLY ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE.
      * The transaction key sorts before the current master key.
      * 交易键排序位置早于当前主键。
      * 取引キーは現在のマスターキーより前に並びます。
       4100-REPORT-TRANSACTION-ONLY.
           ADD 1 TO WS-TRANSACTION-ONLY-COUNT
           DISPLAY "TRANSACTION_ONLY ACCOUNT="
               FD-TRANSACTION-ACCOUNT
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * Equal keys identify one account and its daily transaction.
      * 相等的键标识一个账户及其每日交易。
      * 一致するキーは、1つの口座とその日次取引を示します。
       4200-REPORT-MATCH.
           ADD 1 TO WS-MATCH-COUNT
           DISPLAY "MATCH ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * Close both inputs and report all three classification counts.
      * 关闭两个输入文件并报告三类记录的数量。
      * 両方の入力を閉じ、3種類の分類件数を報告します。
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "CLOSE=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY MATCHED=" WS-MATCH-COUNT
               " ACCOUNT_ONLY=" WS-ACCOUNT-ONLY-COUNT
               " TRANSACTION_ONLY=" WS-TRANSACTION-ONLY-COUNT.
      * Both fixture files are sorted in ascending account-key order.
      * 两个样例文件都按账户键升序排列。
      * 両方のフィクスチャファイルは口座キーの昇順にソートされています。
      * The master key is the ten-character account number.
      * 主键是十字符账户号码。
      * マスターキーは10文字の口座番号です。
      * The transaction key is the same ten-character account number.
      * 交易键也是相同的十字符账户号码。
      * 取引キーも同じ10文字の口座番号です。
      * A smaller master key means no transaction key matches it.
      * 主键较小时，表示没有交易键与之匹配。
      * マスターキーの方が小さい場合、一致する取引キーはありません。
      * A smaller transaction key means no master key matches it.
      * 交易键较小时，表示没有主键与之匹配。
      * 取引キーの方が小さい場合、一致するマスターキーはありません。
      * Equal keys classify one matched pair of records.
      * 相等的键会将一对记录分类为匹配。
      * キーが一致すると、レコードの組を照合一致として分類します。
      * After a match, both input streams advance once.
      * 匹配后，两个输入流各推进一次。
      * 一致した後、両方の入力ストリームを1回ずつ進めます。
      * After a one-sided row, only that side advances.
      * 遇到仅存在于一侧的记录后，只推进该侧。
      * 片側だけのレコードの後は、その側だけを進めます。
      * When one side reaches EOF, remaining rows are orphans.
      * 一侧到达EOF后，另一侧剩余记录均为孤立记录。
      * 片側がEOFに達した時点で、もう一方に残るレコードは孤立レコードです。
      * Each stream has its own status and EOF state.
      * 每个流都有独立的状态和EOF状态。
      * 各ストリームは独自のステータスとEOF状態を持ちます。
      * Status 10 is normal EOF; other read errors stop the merge.
      * 状态10表示正常EOF；其他读取错误会停止归并。
      * ステータス10は正常なEOFです。それ以外の読み込みエラーではマージを停止します。
      * AT END handles EOF for the READ it follows.
      * AT END处理其后READ语句的EOF。
      * AT ENDは、その直前のREADにおけるEOFを処理します。
      * FILE STATUS is checked to distinguish other read failures.
      * 检查FILE STATUS以区分其他读取失败。
      * FILE STATUSを確認して、その他の読み込み失敗を判別します。
      * The account balance and transaction amount use implied cents.
      * 账户余额和交易金额都使用隐含分表示。
      * 口座残高と取引金額は、暗黙のセント単位を使います。
      * This example reports values but calculates no new balance.
      * 此示例报告数值，但不计算新余额。
      * この例では値を報告しますが、新しい残高は計算しません。
      * Duplicate keys are outside this lesson's one-row-per-key rule.
      * 重复键不在本课每个键对应一行的规则范围内。
      * 重複キーは、このレッスンの「1キーにつき1行」という規則の対象外です。
      * Unsorted input invalidates the forward comparison algorithm.
      * 输入未排序会使顺序比较算法失效。
      * 入力がソートされていないと、前方向の比較アルゴリズムは成立しません。
      * Sort both files by the same account-key collation first.
      * 请先按相同的账户键排序规则对两个文件排序。
      * まず両方のファイルを同じ口座キー照合順序でソートしてください。
      * The key fields have equal length and are compared as text.
      * 键字段长度相同，并按文本比较。
      * キーのフィールド長は等しく、テキストとして比較します。
      * Leading zeroes are significant parts of these account keys.
      * 前导零是这些账户键的重要组成部分。
      * 先頭のゼロは、これらの口座キーで意味を持ちます。
      * Master and transaction record layouts are fixed-width text rows.
      * 主记录和交易记录布局都是定宽文本行。
      * マスターと取引のレコードレイアウトは固定幅のテキスト行です。
      * Each physical line contains one record with no delimiter fields.
      * 每个物理行包含一条记录，字段之间没有分隔符。
      * 各物理行にはレコードが1件含まれ、フィールド間の区切り文字はありません。
      * The FD record lengths match the fixture row lengths.
      * FD记录长度与样例行长度相同。
      * FDレコード長はフィクスチャの行長と一致します。
      * Both files are required and must open successfully.
      * 两个文件都是必需的，且必须成功打开。
      * 両方のファイルが必須であり、正常に開ける必要があります。
      * If the second OPEN fails, the first input is closed.
      * 如果第二个OPEN失败，则关闭第一个输入文件。
      * 2つ目のOPENに失敗した場合、最初の入力を閉じます。
      * A successful READ advances only the file named in that READ.
      * READ成功时只推进该READ所指定的文件。
      * READが成功すると、そのREADで指定したファイルだけが進みます。
      * The merge uses constant working storage regardless of row count.
      * 无论行数多少，归并过程使用的工作存储量都固定。
      * 行数にかかわらず、マージ処理の作業領域は一定です。
      * No OCCURS table stores the complete input files in memory.
      * 不会用OCCURS表将整个输入文件存入内存。
      * 入力ファイル全体をメモリに保存するOCCURSテーブルは使いません。
      * This is a sequential merge, not a nested search of both files.
      * 这是顺序归并，不是对两个文件进行嵌套搜索。
      * これは順次マージであり、両ファイルを入れ子にして検索する方法ではありません。
      * Its run time grows with the total number of input records.
      * 运行时间随输入记录总数增长。
      * 実行時間は入力レコードの総数に応じて増加します。
      * The output labels distinguish match and both orphan directions.
      * 输出标签区分匹配以及两种方向的孤立记录。
      * 出力ラベルで照合一致と、両方向の孤立レコードを区別します。
      * Each input contributes at most one row to a matched pair.
      * 每个输入至多为匹配对贡献一行。
      * 照合一致の組に対して、各入力は最大1行を提供します。
      * EOF is tested before referencing a current key for comparison.
      * 比较前先检查EOF，再引用当前键。
      * 比較で現在のキーを参照する前にEOFを確認します。
      * Empty files produce zero rows on their respective side.
      * 空文件对应的一侧产生零条记录。
      * 空ファイル側のレコード数は0件です。
      * The summary counts classifications, not read attempts.
      * 摘要统计分类结果，而非读取尝试次数。
      * サマリーは読み込み試行回数ではなく、分類件数を集計します。
      * The program does not write or alter either input fixture.
      * 程序不会写入或更改任一样例输入文件。
      * プログラムはどちらの入力フィクスチャも書き込みも変更もしません。
      * Later lessons add sorting and complete batch output files.
      * 后续课程将增加排序和完整的批处理输出文件。
      * 以降のレッスンでは、ソートと完全なバッチ出力ファイルを追加します。
      * Run here so both ASSIGN paths find their fixtures.
      * 请在此处运行，以便两个ASSIGN路径都能找到样例文件。
      * 両方のASSIGNパスからフィクスチャを見つけられるよう、ここで実行してください。
      * The program returns a nonzero status after an I/O failure.
      * 发生I/O错误后，程序会返回非零状态。
      * I/Oエラーの後、プログラムはゼロ以外のステータスを返します。
      * The sample contains matches, a master-only row, and orphans.
      * 样例包含匹配记录、仅主文件记录和孤立记录。
      * サンプルには照合一致、マスター側だけの行、孤立レコードが含まれます。
      * One transaction-only row sorts between two master keys.
      * 一条仅交易文件存在的记录排序在两个主键之间。
      * 取引側だけの1行は、2つのマスターキーの間に並びます。
      * Another transaction-only row remains after master EOF.
      * 另一条仅交易文件存在的记录在主文件EOF后仍然剩余。
      * もう1つの取引側だけの行は、マスターがEOFになった後も残ります。
      * The fixtures exercise both key directions and EOF handling.
      * 样例涵盖两个键的大小方向以及EOF处理。
      * フィクスチャでは、両方向のキー比較とEOF処理を確認できます。
      * STOP RUN returns the batch status code to the operating system.
      * STOP RUN将批处理状态码返回给操作系统。
      * STOP RUNはバッチのステータスコードをオペレーティングシステムに返します。
