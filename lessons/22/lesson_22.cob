      * Program identity and fixed-width batch reconciliation.
      * 批次对账程序：按固定宽度字段读取、排序、匹配并分类交易。
      * 固定幅フィールドで取引を読み、整列・照合・分類するバッチ処理。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH22.
      * File assignments use line-sequential files in the current
      * directory.
      * 文件控制将输入输出绑定到当前目录中的行顺序文件。
      * ファイル制御では入出力をカレントディレクトリの行順編成ファイルに割り当てる。
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-M-STATUS.
           SELECT ACCEPTED-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
      * Record contracts: transactions are 10+1+9 = 20 bytes; master
      * rows are 10+8+9 = 27.
      * 记录契约：交易为10+1+9=20字符；主档为10+8+9=27字符。
      * レコード契約：取引は10+1+9=20文字、主档は10+8+9=27文字。
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RAW PIC X(100).
       FD ACCOUNT-MASTER.
       01 FD-MASTER-RAW PIC X(100).
       FD ACCEPTED-FILE.
       01 FD-ACCEPTED-RECORD PIC X(28).
       FD REJECTED-FILE.
       01 FD-REJECTED-RECORD PIC X(30).
       SD SORT-WORK.
       01 SD-TRANSACTION-RECORD.
          05 SD-TRANSACTION-ACCOUNT PIC X(10).
          05 SD-TRANSACTION-TYPE PIC X.
          05 SD-TRANSACTION-AMOUNT PIC X(9).
      * Status/EOF/open flags guard I/O; counters track each batch
      * outcome.
      * 状态、EOF与打开标记控制I/O；计数器记录各类批次结果。
      * 状態・EOF・OPENフラグでI/Oを管理し、各結果をカウンタで集計する。
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-M-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-MASTER-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MASTER-OPEN PIC X VALUE "N".
       01 WS-ACCEPTED-OPEN PIC X VALUE "N".
       01 WS-REJECTED-OPEN PIC X VALUE "N".
       01 WS-INPUT-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-MASTER-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-MASTER-ACCOUNT PIC X(10) VALUE SPACES.
       01 WS-MASTER-CUSTOMER PIC X(8) VALUE SPACES.
       01 WS-MASTER-BALANCE PIC X(9) VALUE SPACES.
       01 WS-REJECT-REASON PIC X(10) VALUE SPACES.
       01 WS-ACCEPTED-RECORD PIC X(28) VALUE SPACES.
       01 WS-REJECTED-RECORD PIC X(30) VALUE SPACES.
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-SORTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-MASTER-ONLY-COUNT PIC 9(3) VALUE ZERO.
      * SORT owns the transaction lifecycle: load and RELEASE, then
      * ordered RETURN.
      * SORT管理交易生命周期：装载并RELEASE，随后按序RETURN。
      * SORTが取引処理を管理する。読込・RELEASE後、順序どおりRETURNする。
       PROCEDURE DIVISION.
      * The key is the ten-character account number; master input must
      * use the same ascending order.
      * 排序键为十字符账户号；主档输入也必须按相同规则升序排列。
      * キーは10文字の口座番号。主档も同じ規則で昇順に並んでいる必要がある。
      * After SORT, report control totals and return failure if any
      * guarded operation failed.
      * SORT结束后输出控制计数；任一受检操作失败时返回非零码。
      * SORT後に管理件数を出力し、監視対象の処理に失敗があれば非ゼロを返す。
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-TRANSACTION-ACCOUNT
               INPUT PROCEDURE 1000-LOAD-TRANSACTIONS
               OUTPUT PROCEDURE 2000-RECONCILE-TRANSACTIONS.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "SORT=FAILED STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY INPUT=" WS-INPUT-COUNT
               " SORTED=" WS-SORTED-COUNT
           DISPLAY "ACCEPTED=" WS-ACCEPTED-COUNT
           DISPLAY "REJECTED=" WS-REJECTED-COUNT
               " MASTER_ONLY=" WS-MASTER-ONLY-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Open and drain the unsorted transaction feed; always check CLOSE
      * status.
      * 打开并读完未排序交易文件；关闭时也检查文件状态。
      * 未整列取引ファイルを開いて読み切り、CLOSE状態も確認する。
       1000-LOAD-TRANSACTIONS.
           OPEN INPUT TRANSACTION-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "OPEN=TXN STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE TRANSACTION-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "CLOSE=TXN STATUS=" WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * Status 10 is normal EOF; other nonzero statuses stop the batch.
      * 状态10表示正常EOF；其他非零状态会中止批次。
      * 状態10は正常なEOF。それ以外の非ゼロ状態ではバッチを停止する。
       1100-READ-AND-RELEASE.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       PERFORM 1110-VALIDATE-TRANSACTION-WIDTH
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00" AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "READ=TXN STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * TRIM measures the physical line; only exactly 20 characters
      * satisfy the input contract.
      * TRIM用于测量实际行宽；只有恰好20字符才满足输入契约。
      * TRIMで実際の行幅を測り、20文字ちょうどの場合だけ契約を満たす。
      * Copy the 20-character layout into the SORT record, then RELEASE
      * it to the sort input procedure.
      * 将20字符布局复制到排序记录，再用RELEASE送入排序输入过程。
      * 20文字の配置をSORTレコードへ移し、RELEASEで整列入力へ渡す。
       1110-VALIDATE-TRANSACTION-WIDTH.
           COMPUTE WS-INPUT-LENGTH = FUNCTION LENGTH(
               FUNCTION TRIM(FD-TRANSACTION-RAW TRAILING))
           IF WS-INPUT-LENGTH NOT = 20
               DISPLAY "TRANSACTION=REJECTED REASON=BAD_WIDTH"
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               MOVE FD-TRANSACTION-RAW(1:20) TO SD-TRANSACTION-RECORD
               RELEASE SD-TRANSACTION-RECORD
               IF SORT-RETURN = ZERO
                   ADD 1 TO WS-INPUT-COUNT
               ELSE
                   DISPLAY "RELEASE=FAILED STATUS=" SORT-RETURN
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * Do not reconcile after a load error; close any resources that
      * were opened.
      * 装载出错后不执行对账；仍需关闭已成功打开的资源。
      * 読込エラー後は照合せず、正常に開いた資源は閉じる。
       2000-RECONCILE-TRANSACTIONS.
           IF WS-IO-ERROR = "N"
               PERFORM 2100-OPEN-OUTPUTS
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM 3000-READ-MASTER
               PERFORM UNTIL WS-SORT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 4000-RETURN-ONE-TRANSACTION
               END-PERFORM
           END-IF
           IF WS-IO-ERROR = "N"
               PERFORM UNTIL WS-MASTER-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 5000-REPORT-MASTER-ONLY
               END-PERFORM
           END-IF
           PERFORM 9000-CLOSE-OUTPUTS.
      * Master is read-only; OPEN OUTPUT truncates both result files for
      * this run.
      * 主档只读；OPEN OUTPUT会覆盖本次运行的两个结果文件。
      * 主档は読取専用。OPEN OUTPUTにより今回の結果ファイルを作り直す。
       2100-OPEN-OUTPUTS.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-M-STATUS = "00"
               MOVE "Y" TO WS-MASTER-OPEN
           ELSE
               DISPLAY "OPEN=MASTER STATUS=" WS-M-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           IF WS-IO-ERROR = "N"
               OPEN OUTPUT ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "OPEN=ACCEPTED STATUS=" WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF
           IF WS-IO-ERROR = "N"
               OPEN OUTPUT REJECTED-FILE
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "OPEN=REJECTED STATUS=" WS-REJECTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * RETURN yields transactions in key order; count only successful
      * records, with SORT EOF normal.
      * RETURN按键顺序取出交易；只统计成功记录，SORT EOF属正常结束。
      * RETURNはキー順に取引を返す。成功レコードのみ数え、SORT EOFは正常終了。
       4000-RETURN-ONE-TRANSACTION.
           RETURN SORT-WORK
               AT END
                   MOVE "Y" TO WS-SORT-EOF
               NOT AT END
                   IF SORT-RETURN = ZERO
                       ADD 1 TO WS-SORTED-COUNT
                       PERFORM 4100-MATCH-TRANSACTION
                   ELSE
                       DISPLAY "RETURN=FAILED STATUS=" SORT-RETURN
                       MOVE "Y" TO WS-IO-ERROR
                   END-IF
           END-RETURN.
      * Advance smaller master keys as MASTER_ONLY until keys meet or
      * master EOF.
      * 主档键较小时逐条计为MASTER_ONLY并前进，直到键相等或主档EOF。
      * 主档キーが小さい間はMASTER_ONLYとして進め、キー一致または主档EOFまで続ける。
      * A missing master takes NO_ACCOUNT precedence; matched rows are
      * validated before advancing master.
      * 无匹配主档时优先判为NO_ACCOUNT；匹配后先校验交易，再推进主档。
      * 主档不匹配ならNO_ACCOUNTを優先する。一致時は取引を検証してから主档を進める。
       4100-MATCH-TRANSACTION.
           PERFORM UNTIL WS-MASTER-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-MASTER-ACCOUNT < SD-TRANSACTION-ACCOUNT
                   PERFORM 5000-REPORT-MASTER-ONLY
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM
           IF WS-IO-ERROR = "N"
               IF WS-MASTER-EOF = "Y"
                   OR WS-MASTER-ACCOUNT NOT =
                       SD-TRANSACTION-ACCOUNT
                   MOVE "NO_ACCOUNT" TO WS-REJECT-REASON
                   PERFORM 6100-WRITE-REJECTED
               ELSE
                   PERFORM 6000-VALIDATE-MATCHED-TRANSACTION
                   IF WS-IO-ERROR = "N"
                       PERFORM 3000-READ-MASTER
                   END-IF
               END-IF
           END-IF.
      * Only matched transactions reach field checks: type D/C, then
      * numeric amount.
      * 只有匹配交易进入字段校验：类型须为D/C，金额须为数字。
      * 照合済み取引だけを検査する。種別はD/C、金額は数字であること。
       6000-VALIDATE-MATCHED-TRANSACTION.
           EVALUATE TRUE
               WHEN SD-TRANSACTION-TYPE NOT = "D"
                   AND SD-TRANSACTION-TYPE NOT = "C"
                   MOVE "BAD_TYPE__" TO WS-REJECT-REASON
                   PERFORM 6100-WRITE-REJECTED
               WHEN SD-TRANSACTION-AMOUNT IS NOT NUMERIC
                   MOVE "BAD_AMOUNT" TO WS-REJECT-REASON
                   PERFORM 6100-WRITE-REJECTED
               WHEN OTHER
                   PERFORM 6200-WRITE-ACCEPTED
           END-EVALUATE.
      * Rejected layout is account(10), reason(10), type(1), amount(9).
      * 拒绝记录布局：账户号(10)、原因(10)、类型(1)、金额(9)。
      * 拒否レコードの構成：口座番号(10)、理由(10)、種別(1)、金額(9)。
      * Reason values are fixed-width: NO_ACCOUNT, BAD_TYPE__,
      * BAD_AMOUNT.
      * 原因字段固定10字符：NO_ACCOUNT、BAD_TYPE__、BAD_AMOUNT。
      * 理由は10文字固定：NO_ACCOUNT、BAD_TYPE__、BAD_AMOUNT。
       6100-WRITE-REJECTED.
           MOVE SD-TRANSACTION-ACCOUNT TO WS-REJECTED-RECORD(1:10)
           MOVE WS-REJECT-REASON TO WS-REJECTED-RECORD(11:10)
           MOVE SD-TRANSACTION-TYPE TO WS-REJECTED-RECORD(21:1)
           MOVE SD-TRANSACTION-AMOUNT TO WS-REJECTED-RECORD(22:9)
           WRITE FD-REJECTED-RECORD FROM WS-REJECTED-RECORD
           IF WS-REJECTED-STATUS = "00"
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "REJECTED ACCOUNT=" SD-TRANSACTION-ACCOUNT
                   " REASON=" WS-REJECT-REASON
           ELSE
               DISPLAY "WRITE=REJECT STATUS=" WS-REJECTED-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Accepted layout is account(10), customer(8), type(1), amount(9).
      * 接受记录布局：账户号(10)、客户号(8)、类型(1)、金额(9)。
      * 受理レコードの構成：口座番号(10)、顧客番号(8)、種別(1)、金額(9)。
       6200-WRITE-ACCEPTED.
           MOVE SD-TRANSACTION-ACCOUNT TO WS-ACCEPTED-RECORD(1:10)
           MOVE WS-MASTER-CUSTOMER TO WS-ACCEPTED-RECORD(11:8)
           MOVE SD-TRANSACTION-TYPE TO WS-ACCEPTED-RECORD(19:1)
           MOVE SD-TRANSACTION-AMOUNT TO WS-ACCEPTED-RECORD(20:9)
           WRITE FD-ACCEPTED-RECORD FROM WS-ACCEPTED-RECORD
           IF WS-ACCEPTED-STATUS = "00"
               ADD 1 TO WS-ACCEPTED-COUNT
               DISPLAY "ACCEPTED ACCOUNT=" SD-TRANSACTION-ACCOUNT
           ELSE
               DISPLAY "WRITE=ACCEPT STATUS=" WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Read one row at a time; EOF 10 is expected, while other statuses
      * signal I/O failure.
      * 逐条读取主档；EOF状态10正常，其他状态表示I/O失败。
      * 主档を1件ずつ読む。EOF状態10は正常、それ以外はI/O失敗。
       3000-READ-MASTER.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-MASTER-EOF
               NOT AT END
                   IF WS-M-STATUS = "00"
                       PERFORM 3100-VALIDATE-MASTER
                   END-IF
           END-READ
           IF WS-M-STATUS NOT = "00" AND WS-M-STATUS NOT = "10"
               DISPLAY "READ=MASTER STATUS=" WS-M-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * Enforce the 27-character master contract and numeric
      * nine-character balance.
      * 检查主档必须为27字符，且九字符余额字段为数字。
      * 主档は27文字、9文字の残高欄は数字であることを確認する。
       3100-VALIDATE-MASTER.
           COMPUTE WS-MASTER-LENGTH = FUNCTION LENGTH(
               FUNCTION TRIM(FD-MASTER-RAW TRAILING))
           IF WS-MASTER-LENGTH NOT = 27
               DISPLAY "MASTER=FAILED REASON=BAD_WIDTH"
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               MOVE FD-MASTER-RAW(1:10) TO WS-MASTER-ACCOUNT
               MOVE FD-MASTER-RAW(11:8) TO WS-MASTER-CUSTOMER
               MOVE FD-MASTER-RAW(19:9) TO WS-MASTER-BALANCE
               IF WS-MASTER-BALANCE IS NOT NUMERIC
                   DISPLAY "MASTER=FAILED REASON=BAD_BALANCE"
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * A master key with no transaction is counted once, displayed,
      * then the next row is read.
      * 没有交易的主档账户计数并显示一次，然后读取下一行。
      * 取引のない主档口座を一度集計・表示し、次の行を読む。
       5000-REPORT-MASTER-ONLY.
           ADD 1 TO WS-MASTER-ONLY-COUNT
           DISPLAY "MASTER_ONLY ACCOUNT=" WS-MASTER-ACCOUNT
           PERFORM 3000-READ-MASTER.
      * Close only files marked open; CLOSE errors also make the batch
      * unsuccessful.
      * 只关闭标记为已打开的文件；CLOSE错误同样使批次失败。
      * OPEN済みのファイルだけを閉じる。CLOSEエラーもバッチ失敗とする。
       9000-CLOSE-OUTPUTS.
           IF WS-MASTER-OPEN = "Y"
               CLOSE ACCOUNT-MASTER
               IF WS-M-STATUS NOT = "00"
                   DISPLAY "CLOSE=MASTER STATUS=" WS-M-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-MASTER-OPEN
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-FILE
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "CLOSE=ACCEPTED STATUS=" WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-ACCEPTED-OPEN
           END-IF
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-FILE
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "CLOSE=REJECTED STATUS=" WS-REJECTED-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
               MOVE "N" TO WS-REJECTED-OPEN
           END-IF.
