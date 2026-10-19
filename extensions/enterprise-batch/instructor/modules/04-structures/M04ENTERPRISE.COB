      *> M04ENTERPRISE: module 04 lesson 04.3 フィールド検索。
      *> module 07 正規 enterprise record（175 fields）対象（読
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M04ENTERPRISE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-ENT ASSIGN TO 'input.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD IN-ENT.
       01 ENT-REC.
          COPY 'ENTERPRISE-CUSTOMER-V1.CPY'.
       WORKING-STORAGE SECTION.
       01 WS-STATUS PIC XX.
       01 WS-N PIC 9(4) VALUE 0.
       01 WS-EXPECT-LEN PIC 9(4) VALUE 0.
       01 WS-BAD PIC X VALUE 'N'.
       01 WS-SURNAME PIC X(32).
       01 WS-CLASS PIC X(2).
       01 WS-SYNC PIC X(2).
       01 WS-RISK PIC S9(9).
       01 WS-ID PIC X(10).
       PROCEDURE DIVISION.
       1000-MAIN.
           DISPLAY 'LESSON,04.3'
           MOVE LENGTH OF ENT-REC TO WS-EXPECT-LEN
           DISPLAY 'LAYOUT,ENTERPRISE-CUSTOMER-V1,' WS-EXPECT-LEN
           OPEN INPUT IN-ENT
           IF WS-STATUS NOT = '00'
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF
           PERFORM UNTIL WS-STATUS = '10'
               READ IN-ENT
                   AT END CONTINUE
                   NOT AT END
                       PERFORM 1200-VALIDATE
                       IF WS-BAD = 'Y'
                           CLOSE IN-ENT
                           MOVE 8 TO RETURN-CODE
                           GOBACK
                       END-IF
                       ADD 1 TO WS-N
                       PERFORM 1300-REPORT
               END-READ
           END-PERFORM
           CLOSE IN-ENT
           DISPLAY 'RECORDS,' WS-N
           MOVE 0 TO RETURN-CODE
           GOBACK.
       1200-VALIDATE.
           MOVE 'N' TO WS-BAD
           IF LAYOUT-VERSION NOT = '001'
               MOVE 'Y' TO WS-BAD
           END-IF
           IF BINARY-ABI-CODE NOT = 'GCOB32BE'
               MOVE 'Y' TO WS-BAD
           END-IF
           IF CUSTOMER-ID(1:10) IS NOT NUMERIC
               MOVE 'Y' TO WS-BAD
           END-IF.
       1300-REPORT.
           MOVE CUSTOMER-ID TO WS-ID
           MOVE LEGAL-SURNAME TO WS-SURNAME
           MOVE CUSTOMER-CLASSIFICATION TO WS-CLASS
           MOVE SYNC-STATE TO WS-SYNC
           MOVE RISK-SCORE TO WS-RISK
           DISPLAY 'REC,' WS-N ',ID,' WS-ID
           DISPLAY '  STATUS,' RECORD-STATUS
           DISPLAY '  SURNAME,' FUNCTION TRIM(WS-SURNAME)
           DISPLAY '  CLASS,' FUNCTION TRIM(WS-CLASS)
           DISPLAY '  RISK,' WS-RISK
           DISPLAY '  SYNC,' FUNCTION TRIM(WS-SYNC).
