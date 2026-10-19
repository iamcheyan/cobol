       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTV2-STARTER.
      *> JOB002d雛形：区分を1桁から2桁へ拡張。
      *> v1経路は実装済み。31B入力をv2へ正規化。
      *> v2経路は未実装。受講者の課題：
      *> 1. 32BのCAP-CUSTOMER-FEED v2を受け付ける。
      *> bytes 28-29はA1..D1。byte 27はrecord status A/D。
      *> 2. 区分を検証、BADCLASS/BADVERSIONを却下。
      *> 3. v2正規化ストリームと制御行を出力。
      *> v2入力は実装までRC12で失敗させ、公開しない。
      *> 顧客フィードは独立したenterprise形式。
      *> 27BのCUSTOMER v1（byte 27=status）は不変。
      *>
      *>
      *>
      *>
      *>
      *>
      *>
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-IN ASSIGN TO DYNAMIC I-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS I-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD CUST-IN.
       01 I-LINE PIC X(400).
       WORKING-STORAGE SECTION.
       01 I-PATH PIC X(4096).
       01 O-PATH PIC X(4096).
       01 J-PATH PIC X(4096).
       01 K-PATH PIC X(4096).
       01 I-STAT PIC XX.
       01 WS-REC PIC X(400).
       01 WS-LEN PIC 9(4) COMP.
       PROCEDURE DIVISION.
           ACCEPT I-PATH FROM ENVIRONMENT 'CUSTV2_IN'
           ACCEPT O-PATH FROM ENVIRONMENT 'CUSTV2_OUT'
           ACCEPT J-PATH FROM ENVIRONMENT 'CUSTV2_REJECTED'
           ACCEPT K-PATH FROM ENVIRONMENT 'CUSTV2_CONTROL'
           IF I-PATH = SPACES
               DISPLAY 'CUSTV2 starter: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN INPUT CUST-IN
           IF I-STAT NOT = '00'
               DISPLAY 'CUSTV2 starter: cannot open input' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           READ CUST-IN
               AT END CONTINUE
               NOT AT END
                   MOVE I-LINE TO WS-REC
                   COMPUTE WS-LEN =
                       FUNCTION LENGTH(FUNCTION TRIM(WS-REC))
                   IF WS-LEN = 32
                       DISPLAY 'CUSTV2 starter: v2 feed not implemented'
                         UPON STDERR
                       CLOSE CUST-IN
                       MOVE 12 TO RETURN-CODE
                       GOBACK
                   END-IF
           END-READ
           CLOSE CUST-IN
           DISPLAY 'CUSTV2 starter: TODO not implemented' UPON STDERR
           MOVE 12 TO RETURN-CODE
           GOBACK.
