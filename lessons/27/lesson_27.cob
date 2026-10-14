      * プログラム識別情報と外部ファイル。
      * ログを先に開き、各ファイルの状態を確認します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOG27.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT BATCH-LOG
               ASSIGN TO "batch.log"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-LOG-STATUS.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT ACCEPTED-OUTPUT
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCEPTED-STATUS.
           SELECT REJECTED-OUTPUT
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REJECTED-STATUS.
      * ファイルレコードはログ、入力、正常・拒否出力の形式です。
      * 作業領域では状態フラグ、業務項目、
      * イベント、操作状態、バッチ件数を分けて管理します。
       DATA DIVISION.
       FILE SECTION.
       FD BATCH-LOG.
       01 FD-BATCH-LOG-RECORD PIC X(100).
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(20).
       FD ACCEPTED-OUTPUT.
       01 FD-ACCEPTED-RECORD PIC X(12).
       FD REJECTED-OUTPUT.
       01 FD-REJECTED-RECORD PIC X(19).
       WORKING-STORAGE SECTION.
       01 WS-LOG-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
       01 WS-LOG-OPEN PIC X VALUE "N".
       01 WS-LOG-FAILED PIC X VALUE "N".
       01 WS-INPUT-OPEN PIC X VALUE "N".
       01 WS-ACCEPTED-OPEN PIC X VALUE "N".
       01 WS-REJECTED-OPEN PIC X VALUE "N".
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-SYSTEM-ERROR PIC X VALUE "N".
       01 WS-RECORD-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT PIC X(6) VALUE SPACES.
       01 WS-AMOUNT PIC X(5) VALUE SPACES.
       01 WS-REJECT-REASON PIC X(12) VALUE SPACES.
       01 WS-ACCEPTED-WORK PIC X(12) VALUE SPACES.
       01 WS-REJECTED-WORK PIC X(19) VALUE SPACES.
       01 WS-LOG-MESSAGE PIC X(100) VALUE SPACES.
       01 WS-ERROR-OP PIC X(24) VALUE SPACES.
       01 WS-ERROR-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
      * 主処理：ログを確立し、安全な場合だけ処理します。
      * 業務ファイルを閉じ、終了イベントとログを記録します。
      * 障害時は非ゼロの戻りコードを設定します。
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 9000-OPEN-LOG
           IF WS-SYSTEM-ERROR = "N"
               MOVE "EVENT=BATCH_START ID=TRAINING-001"
                   TO WS-LOG-MESSAGE
               PERFORM 9100-WRITE-LOG
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               PERFORM 1000-OPEN-DATA-FILES
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               PERFORM 2000-PROCESS-INPUT
           END-IF
           PERFORM 8000-CLOSE-DATA-FILES
           IF WS-LOG-OPEN = "Y" AND WS-LOG-FAILED = "N"
               PERFORM 9200-LOG-BATCH-END
               CLOSE BATCH-LOG
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "ERROR=CLOSE_LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-LOG-OPEN
           END-IF
           DISPLAY "SUMMARY INPUT=" WS-INPUT-COUNT
               " ACCEPTED=" WS-ACCEPTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT
           DISPLAY "SYSTEM-ERROR=" WS-SYSTEM-ERROR
           IF WS-SYSTEM-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * ログを最初に開きます。失敗時はバッチを開始しません。
       9000-OPEN-LOG.
           OPEN OUTPUT BATCH-LOG
           IF WS-LOG-STATUS = "00"
               MOVE "Y" TO WS-LOG-OPEN
           ELSE
               DISPLAY "ERROR=OPEN_LOG STATUS=" WS-LOG-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 業務ファイルを順に開き、状態00の後に開済みにします。
      * 失敗はシステム障害となり、処理を止めます。
       1000-OPEN-DATA-FILES.
           OPEN INPUT TRANSACTION-INPUT
           IF WS-INPUT-STATUS = "00"
               MOVE "Y" TO WS-INPUT-OPEN
           ELSE
               MOVE "OPEN_INPUT" TO WS-ERROR-OP
               MOVE WS-INPUT-STATUS TO WS-ERROR-STATUS
               PERFORM 9300-REPORT-SYSTEM-ERROR
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   MOVE "OPEN_ACCEPTED" TO WS-ERROR-OP
                   MOVE WS-ACCEPTED-STATUS TO WS-ERROR-STATUS
                   PERFORM 9300-REPORT-SYSTEM-ERROR
               END-IF
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT REJECTED-OUTPUT
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   MOVE "OPEN_REJECTED" TO WS-ERROR-OP
                   MOVE WS-REJECTED-STATUS TO WS-ERROR-STATUS
                   PERFORM 9300-REPORT-SYSTEM-ERROR
               END-IF
           END-IF.
      * EOFまたはシステム障害で入力処理を終了します。
       2000-PROCESS-INPUT.
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-SYSTEM-ERROR = "Y"
               PERFORM 2100-READ-ONE-RECORD
           END-PERFORM.
      * 正常読込ごとに番号を付け、口座キーを取得します。
      * 検証前に記録し、EOFと読込障害を区別します。
       2100-READ-ONE-RECORD.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       ADD 1 TO WS-INPUT-COUNT
                       MOVE FD-TRANSACTION-RECORD(1:6)
                           TO WS-ACCOUNT
                       PERFORM 2200-LOG-RECORD-READ
                       IF WS-SYSTEM-ERROR = "N"
                           PERFORM 3000-VALIDATE-RECORD
                       END-IF
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               MOVE "READ_INPUT" TO WS-ERROR-OP
               MOVE WS-INPUT-STATUS TO WS-ERROR-STATUS
               PERFORM 9300-REPORT-SYSTEM-ERROR
           END-IF.
      * 読込イベントに番号と口座を含め、組立前に初期化します。
       2200-LOG-RECORD-READ.
           MOVE SPACES TO WS-LOG-MESSAGE
           STRING "EVENT=RECORD_READ NO=" DELIMITED BY SIZE
               WS-INPUT-COUNT DELIMITED BY SIZE
               " ACCOUNT=" DELIMITED BY SIZE
               WS-ACCOUNT DELIMITED BY SIZE
               INTO WS-LOG-MESSAGE
           END-STRING
           PERFORM 9100-WRITE-LOG.
      * 桁数、区切り、金額の数字性、ゼロ以外を検証します。
      * 違反は業務拒否であり、システム障害ではありません。
       3000-VALIDATE-RECORD.
           MOVE SPACES TO WS-REJECT-REASON
           COMPUTE WS-RECORD-LENGTH = FUNCTION LENGTH(
               FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING))
           IF WS-RECORD-LENGTH NOT = 12
               MOVE "BAD_WIDTH" TO WS-REJECT-REASON
           ELSE
               IF FD-TRANSACTION-RECORD(7:1) NOT = "|"
                   MOVE "BAD_FORMAT" TO WS-REJECT-REASON
               ELSE
                   MOVE FD-TRANSACTION-RECORD(8:5)
                       TO WS-AMOUNT
                   IF WS-AMOUNT IS NOT NUMERIC
                       MOVE "BAD_AMOUNT" TO WS-REJECT-REASON
                   ELSE
                       IF WS-AMOUNT = "00000"
                           MOVE "ZERO_AMOUNT" TO WS-REJECT-REASON
                       END-IF
                   END-IF
               END-IF
           END-IF
           IF WS-REJECT-REASON = SPACES
               PERFORM 4000-WRITE-ACCEPTED
           ELSE
               PERFORM 5000-WRITE-REJECTED
           END-IF.
      * 正常データを書き、状態00の後に件数とイベントを記録します。
       4000-WRITE-ACCEPTED.
           MOVE FD-TRANSACTION-RECORD(1:12)
               TO WS-ACCEPTED-WORK
           WRITE FD-ACCEPTED-RECORD FROM WS-ACCEPTED-WORK
           IF WS-ACCEPTED-STATUS = "00"
               ADD 1 TO WS-ACCEPTED-COUNT
               DISPLAY "ACCEPTED ACCOUNT=" WS-ACCOUNT
               PERFORM 4100-LOG-ACCEPTED
           ELSE
               MOVE "WRITE_ACCEPTED" TO WS-ERROR-OP
               MOVE WS-ACCEPTED-STATUS TO WS-ERROR-STATUS
               PERFORM 9300-REPORT-SYSTEM-ERROR
           END-IF.
      * 出力WRITE成功後に受付イベントを記録します。
       4100-LOG-ACCEPTED.
           MOVE SPACES TO WS-LOG-MESSAGE
           STRING "EVENT=RECORD_ACCEPTED NO=" DELIMITED BY SIZE
               WS-INPUT-COUNT DELIMITED BY SIZE
               " ACCOUNT=" DELIMITED BY SIZE
               WS-ACCOUNT DELIMITED BY SIZE
               INTO WS-LOG-MESSAGE
           END-STRING
           PERFORM 9100-WRITE-LOG.
      * 拒否ファイルに口座と拒否理由を書きます。
      * 出力WRITE失敗はシステム障害です。
       5000-WRITE-REJECTED.
           MOVE SPACES TO WS-REJECTED-WORK
           MOVE WS-ACCOUNT TO WS-REJECTED-WORK(1:6)
           MOVE "|" TO WS-REJECTED-WORK(7:1)
           MOVE WS-REJECT-REASON TO WS-REJECTED-WORK(8:12)
           WRITE FD-REJECTED-RECORD FROM WS-REJECTED-WORK
           IF WS-REJECTED-STATUS = "00"
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "REJECTED ACCOUNT=" WS-ACCOUNT
                   " REASON="
                   FUNCTION TRIM(WS-REJECT-REASON TRAILING)
               PERFORM 5100-LOG-REJECTED
           ELSE
               MOVE "WRITE_REJECTED" TO WS-ERROR-OP
               MOVE WS-REJECTED-STATUS TO WS-ERROR-STATUS
               PERFORM 9300-REPORT-SYSTEM-ERROR
           END-IF.
      * 行番号、口座、業務拒否理由を記録します。
       5100-LOG-REJECTED.
           MOVE SPACES TO WS-LOG-MESSAGE
           STRING "EVENT=BUSINESS_REJECT NO=" DELIMITED BY SIZE
               WS-INPUT-COUNT DELIMITED BY SIZE
               " ACCOUNT=" DELIMITED BY SIZE
               WS-ACCOUNT DELIMITED BY SIZE
               " REASON=" DELIMITED BY SIZE
               WS-REJECT-REASON DELIMITED BY SPACE
               INTO WS-LOG-MESSAGE
           END-STRING
           PERFORM 9100-WRITE-LOG.
      * ログWRITE状態を毎回確認します。失敗後は処理と追記を停止します。
      * ログ自身の書込障害は記録できません。
       9100-WRITE-LOG.
           IF WS-LOG-FAILED = "N"
               MOVE WS-LOG-MESSAGE TO FD-BATCH-LOG-RECORD
               WRITE FD-BATCH-LOG-RECORD
               IF WS-LOG-STATUS NOT = "00"
                   DISPLAY "ERROR=WRITE_LOG STATUS=" WS-LOG-STATUS
                   MOVE "Y" TO WS-LOG-FAILED
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF.
      * 操作と状態を報告し、可能ならログにも記録します。
       9300-REPORT-SYSTEM-ERROR.
           MOVE "Y" TO WS-SYSTEM-ERROR
           DISPLAY "ERROR="
               FUNCTION TRIM(WS-ERROR-OP TRAILING)
               " STATUS=" WS-ERROR-STATUS
           IF WS-LOG-OPEN = "Y" AND WS-LOG-FAILED = "N"
               MOVE SPACES TO WS-LOG-MESSAGE
               STRING "EVENT=SYSTEM_ERROR OP=" DELIMITED BY SIZE
                   WS-ERROR-OP DELIMITED BY SPACE
                   " STATUS=" DELIMITED BY SIZE
                   WS-ERROR-STATUS DELIMITED BY SIZE
                   INTO WS-LOG-MESSAGE
               END-STRING
               PERFORM 9100-WRITE-LOG
           END-IF.
      * 開いた業務ファイルだけを閉じ、状態を確認します。
      * ログ使用中に終了障害を記録します。
       8000-CLOSE-DATA-FILES.
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-OUTPUT
               IF WS-REJECTED-STATUS NOT = "00"
                   MOVE "CLOSE_REJECTED" TO WS-ERROR-OP
                   MOVE WS-REJECTED-STATUS TO WS-ERROR-STATUS
                   PERFORM 9300-REPORT-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-REJECTED-OPEN
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS NOT = "00"
                   MOVE "CLOSE_ACCEPTED" TO WS-ERROR-OP
                   MOVE WS-ACCEPTED-STATUS TO WS-ERROR-STATUS
                   PERFORM 9300-REPORT-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-ACCEPTED-OPEN
           END-IF
           IF WS-INPUT-OPEN = "Y"
               CLOSE TRANSACTION-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   MOVE "CLOSE_INPUT" TO WS-ERROR-OP
                   MOVE WS-INPUT-STATUS TO WS-ERROR-STATUS
                   PERFORM 9300-REPORT-SYSTEM-ERROR
               END-IF
           END-IF.
      * 業務ファイル終了後に件数とエラーを記録してログを閉じます。
      * ログ終了障害は画面にのみ報告できます。
       9200-LOG-BATCH-END.
           MOVE SPACES TO WS-LOG-MESSAGE
           STRING "EVENT=BATCH_END INPUT=" DELIMITED BY SIZE
               WS-INPUT-COUNT DELIMITED BY SIZE
               " ACCEPTED=" DELIMITED BY SIZE
               WS-ACCEPTED-COUNT DELIMITED BY SIZE
               " REJECTED=" DELIMITED BY SIZE
               WS-REJECTED-COUNT DELIMITED BY SIZE
               " SYSTEM_ERROR=" DELIMITED BY SIZE
               WS-SYSTEM-ERROR DELIMITED BY SIZE
               INTO WS-LOG-MESSAGE
           END-STRING
           PERFORM 9100-WRITE-LOG.
