      * 第26課：業務データの不正とファイル障害を区別します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ERROR26.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
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
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(20).
       FD ACCEPTED-OUTPUT.
       01 FD-ACCEPTED-RECORD PIC X(12).
       FD REJECTED-OUTPUT.
       01 FD-REJECTED-RECORD PIC X(19).
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-ACCEPTED-STATUS PIC XX VALUE SPACES.
       01 WS-REJECTED-STATUS PIC XX VALUE SPACES.
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
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 業務行の拒否では続行し、システムI/O障害がある場合だけ失敗を返します。
       0000-MAIN.
           PERFORM 1000-OPEN-FILES
           IF WS-SYSTEM-ERROR = "N"
               PERFORM 2000-PROCESS-INPUT
           END-IF
           PERFORM 8000-CLOSE-FILES
           DISPLAY "集計 入力=" WS-INPUT-COUNT
               " 受理=" WS-ACCEPTED-COUNT
               " 拒否=" WS-REJECTED-COUNT
           DISPLAY "システムエラー=" WS-SYSTEM-ERROR
           IF WS-SYSTEM-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * どちらかの出力ファイルを作成する前に入力フ
      * ァイルを開く。
       1000-OPEN-FILES.
           OPEN INPUT TRANSACTION-INPUT
           IF WS-INPUT-STATUS = "00"
               MOVE "Y" TO WS-INPUT-OPEN
           ELSE
               DISPLAY "エラー=入力OPEN 状態=" WS-INPUT-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS = "00"
                   MOVE "Y" TO WS-ACCEPTED-OPEN
               ELSE
                   DISPLAY "エラー=受理出力オープン 状態="
                       WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF
           IF WS-SYSTEM-ERROR = "N"
               OPEN OUTPUT REJECTED-OUTPUT
               IF WS-REJECTED-STATUS = "00"
                   MOVE "Y" TO WS-REJECTED-OPEN
               ELSE
                   DISPLAY "エラー=拒否出力オープン 状態="
                       WS-REJECTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
           END-IF.
      * AT END は EOFを処理し、それ以外の状態はシステ
      * ムエラーとする。
       2000-PROCESS-INPUT.
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-SYSTEM-ERROR = "Y"
               PERFORM 2100-READ-ONE-RECORD
           END-PERFORM.
       2100-READ-ONE-RECORD.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       ADD 1 TO WS-INPUT-COUNT
                       PERFORM 3000-VALIDATE-RECORD
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "エラー=入力読取 状態="
                   WS-INPUT-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 業務検証で行を拒否しても、後続レコードの処理は続けます。
       3000-VALIDATE-RECORD.
           MOVE SPACES TO WS-REJECT-REASON
           MOVE FD-TRANSACTION-RECORD(1:6) TO WS-ACCOUNT
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
      * 有効行数は出力WRITEが成功した後にだけ加算します。
       4000-WRITE-ACCEPTED.
           MOVE FD-TRANSACTION-RECORD(1:12)
               TO WS-ACCEPTED-WORK
           WRITE FD-ACCEPTED-RECORD FROM WS-ACCEPTED-WORK
           IF WS-ACCEPTED-STATUS = "00"
               ADD 1 TO WS-ACCEPTED-COUNT
               DISPLAY "受理口座=" WS-ACCOUNT
           ELSE
               DISPLAY "エラー=受理出力書込 状態="
                   WS-ACCEPTED-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * 形式不正の行は理由とともに記録し、後続行の処理を続けます。
       5000-WRITE-REJECTED.
           MOVE SPACES TO WS-REJECTED-WORK
           MOVE WS-ACCOUNT TO WS-REJECTED-WORK(1:6)
           MOVE "|" TO WS-REJECTED-WORK(7:1)
           MOVE WS-REJECT-REASON TO WS-REJECTED-WORK(8:12)
           WRITE FD-REJECTED-RECORD FROM WS-REJECTED-WORK
           IF WS-REJECTED-STATUS = "00"
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "拒否口座=" WS-ACCOUNT
                   " REASON="
                   FUNCTION TRIM(WS-REJECT-REASON TRAILING)
           ELSE
               DISPLAY "エラー=拒否出力書込 状態="
                   WS-REJECTED-STATUS
               MOVE "Y" TO WS-SYSTEM-ERROR
           END-IF.
      * OPENに成功したすべてのファイルを閉じ、それ
      * ぞれの状態を確認する。
       8000-CLOSE-FILES.
           IF WS-REJECTED-OPEN = "Y"
               CLOSE REJECTED-OUTPUT
               IF WS-REJECTED-STATUS NOT = "00"
                   DISPLAY "エラー=拒否出力クローズ 状態="
                       WS-REJECTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-REJECTED-OPEN
           END-IF
           IF WS-ACCEPTED-OPEN = "Y"
               CLOSE ACCEPTED-OUTPUT
               IF WS-ACCEPTED-STATUS NOT = "00"
                   DISPLAY "エラー=受理出力クローズ 状態="
                       WS-ACCEPTED-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-ACCEPTED-OPEN
           END-IF
           IF WS-INPUT-OPEN = "Y"
               CLOSE TRANSACTION-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "エラー=入力クローズ 状態="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-SYSTEM-ERROR
               END-IF
               MOVE "N" TO WS-INPUT-OPEN
           END-IF.
