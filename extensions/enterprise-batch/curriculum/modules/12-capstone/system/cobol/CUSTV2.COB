       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTV2.
      *> Module 12 capstone JOB002d:企業顧客フィードを検証・
      *> 企業向けv2レイアウト（32B）に正規化。
      *> 企業向けv1フィード（31B）もも読込可。
      *
      *> こフィードは独立版管理企業顧客形式であり・
      *> 27B正準CUSTOMER v1ではない。1-27Bには正準
      *> CUSTOMER v1をそのまま内包ため、27B目は
      *> レコードSTATUS(A/D)
      *> v1では28B目（A/B/C/D）、v2では28-29B目
      *> (A1～D1)に置く。区分をstatusBとして扱わない。
      *
      *> v1（31 B）：id(8) name(10) balance_demo(8) status(1)
      *>             classification(1) layout_version(3)="001"
      *> v2（32 B）：id(8) name(10) balance_demo(8) status(1)
      *>             classification(2) layout_version(3)="002"
      *> v1の区分A/B/C/Dはv2の"A1/B1/C1/D1"へ変換。
      *
      *> 宣言幅と幅が不一致なら、または
      *> idが数字以外の場合は構造異常RC8。業務却下は
      *> 継続してRC4と。正規化ストリームは常にv2形式
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-IN ASSIGN TO DYNAMIC I-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS I-STAT.
           SELECT OUT-V2 ASSIGN TO DYNAMIC O-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS O-STAT.
           SELECT REJ-OUT ASSIGN TO DYNAMIC J-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS J-STAT.
           SELECT CTL-OUT ASSIGN TO DYNAMIC K-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS K-STAT.
       DATA DIVISION.
       FILE SECTION.
       FD CUST-IN.
       01 I-LINE PIC X(400).
       FD OUT-V2.
       01 O-LINE PIC X(32).
       FD REJ-OUT.
       01 J-LINE PIC X(70).
       FD CTL-OUT.
       01 K-LINE PIC X(200).
       WORKING-STORAGE SECTION.
       01 I-PATH PIC X(4096).
       01 O-PATH PIC X(4096).
       01 J-PATH PIC X(4096).
       01 K-PATH PIC X(4096).
       01 WS-LAYOUT PIC X(2).
       01 I-STAT PIC XX.
       01 O-STAT PIC XX.
       01 J-STAT PIC XX.
       01 K-STAT PIC XX.
       01 WS-REC PIC X(400).
       01 WS-LEN PIC 9(4) COMP.
       01 WS-WANT PIC 9(4) COMP.
       01 WS-EOF PIC X VALUE 'N'.
       01 WS-STRUCT PIC X VALUE 'N'.
       01 WS-REASON PIC X(10).
       01 WS-STATUS PIC X(1).
       01 WS-CLASS1 PIC X(1).
       01 WS-CLASS2 PIC X(2).
       01 WS-V2.
          05 WS-ID PIC X(8).
          05 WS-NAME PIC X(10).
          05 WS-BAL PIC X(8).
          05 WS-STATUS-O PIC X(1).
          05 WS-CLASS PIC X(2).
          05 WS-VER PIC X(3).
       01 WS-REJ.
          05 WS-RJ-DATA PIC X(32).
          05 FILLER PIC X.
          05 WS-RJ-CODE PIC X(10).
       01 RECV-N PIC 9(9) COMP.
       01 ACC-N PIC 9(9) COMP.
       01 REJ-N PIC 9(9) COMP.
       01 REJ-ID PIC 9(9) COMP.
       01 REJ-NAME PIC 9(9) COMP.
       01 REJ-STATUS PIC 9(9) COMP.
       01 REJ-CLASS PIC 9(9) COMP.
       01 REJ-VERSION PIC 9(9) COMP.
       01 WS-NUM PIC 9(6).
       01 WS-NUMX PIC X(6).
       01 WS-PTR PIC 9(4) COMP.
       01 WS-UPGRADED PIC 9(9) COMP.
       PROCEDURE DIVISION.
           ACCEPT I-PATH FROM ENVIRONMENT 'CUSTV2_IN'
           ACCEPT O-PATH FROM ENVIRONMENT 'CUSTV2_OUT'
           ACCEPT J-PATH FROM ENVIRONMENT 'CUSTV2_REJECTED'
           ACCEPT K-PATH FROM ENVIRONMENT 'CUSTV2_CONTROL'
           ACCEPT WS-LAYOUT FROM ENVIRONMENT 'CUSTV2_LAYOUT'
           IF I-PATH = SPACES OR O-PATH = SPACES OR J-PATH = SPACES OR
              K-PATH = SPACES OR WS-LAYOUT = SPACES
               DISPLAY 'CUSTV2: missing environment' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           IF WS-LAYOUT = 'v1'
               MOVE 31 TO WS-WANT
           ELSE
               IF WS-LAYOUT = 'v2'
                   MOVE 32 TO WS-WANT
               ELSE
                   DISPLAY 'CUSTV2: bad layout ' WS-LAYOUT UPON STDERR
                   MOVE 8 TO RETURN-CODE
                   GOBACK
               END-IF
           END-IF
           OPEN INPUT CUST-IN
           IF I-STAT NOT = '00'
               DISPLAY 'CUSTV2: cannot open input ' I-STAT UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           OPEN OUTPUT OUT-V2
           OPEN OUTPUT REJ-OUT
           OPEN OUTPUT CTL-OUT
           IF O-STAT NOT = '00' OR J-STAT NOT = '00' OR
              K-STAT NOT = '00'
               DISPLAY 'CUSTV2: cannot open output' UPON STDERR
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           PERFORM UNTIL WS-EOF = 'Y' OR WS-STRUCT = 'Y'
               READ CUST-IN
                   AT END MOVE 'Y' TO WS-EOF
                   NOT AT END
                       MOVE I-LINE TO WS-REC
                       ADD 1 TO RECV-N
                       PERFORM 2000-PROCESS
               END-READ
           END-PERFORM
           IF WS-STRUCT = 'N'
               PERFORM 3000-CONTROL
           END-IF
           CLOSE CUST-IN OUT-V2 REJ-OUT CTL-OUT
           IF WS-STRUCT = 'Y'
               DISPLAY 'CUSTV2: structural error, failed' UPON STDERR
               MOVE 8 TO RETURN-CODE
               GOBACK
           END-IF
           DISPLAY 'CUSTV2 received=' RECV-N ' accepted=' ACC-N
                   ' rejected=' REJ-N
           IF REJ-N > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF
           GOBACK.
       2000-PROCESS.
           COMPUTE WS-LEN = FUNCTION LENGTH(FUNCTION TRIM(WS-REC))
           IF WS-LEN NOT = WS-WANT
               DISPLAY 'CUSTV2: width ' WS-LEN ' != layout ' WS-LAYOUT
                 UPON STDERR
               MOVE 'Y' TO WS-STRUCT
               EXIT PARAGRAPH
           END-IF
           IF WS-REC(1:8) IS NOT NUMERIC
               DISPLAY 'CUSTV2: non-numeric customer id' UPON STDERR
               MOVE 'Y' TO WS-STRUCT
               EXIT PARAGRAPH
           END-IF
           MOVE SPACES TO WS-REASON
           IF WS-REC(1:8) = '00000000'
               MOVE 'BADID' TO WS-REASON
           ELSE
               IF WS-REC(9:10) = SPACES
                   MOVE 'BADNAME' TO WS-REASON
               ELSE
                   MOVE WS-REC(27:1) TO WS-STATUS
                   IF WS-STATUS NOT = 'A' AND WS-STATUS NOT = 'D'
                       MOVE 'BADSTATUS' TO WS-REASON
                   ELSE
                       PERFORM 2100-CLASSIFY
                   END-IF
               END-IF
           END-IF
           IF WS-REASON = SPACES
               MOVE WS-REC(1:8) TO WS-ID
               MOVE WS-REC(9:10) TO WS-NAME
               MOVE WS-REC(19:8) TO WS-BAL
               MOVE WS-STATUS TO WS-STATUS-O
               MOVE WS-CLASS2 TO WS-CLASS
               MOVE '002' TO WS-VER
               MOVE WS-V2 TO O-LINE
               WRITE O-LINE
               ADD 1 TO ACC-N
           ELSE
               MOVE WS-REC(1:32) TO WS-RJ-DATA
               MOVE WS-REASON TO WS-RJ-CODE
               MOVE WS-REJ TO J-LINE
               WRITE J-LINE
               ADD 1 TO REJ-N
               EVALUATE WS-REASON
                   WHEN 'BADID'
                       ADD 1 TO REJ-ID
                   WHEN 'BADNAME'
                       ADD 1 TO REJ-NAME
                   WHEN 'BADSTATUS'
                       ADD 1 TO REJ-STATUS
                   WHEN 'BADCLASS'
                       ADD 1 TO REJ-CLASS
                   WHEN 'BADVERSION'
                       ADD 1 TO REJ-VERSION
                   WHEN OTHER
                       CONTINUE
               END-EVALUATE
           END-IF
           .
       2100-CLASSIFY.
           IF WS-LAYOUT = 'v1'
               MOVE WS-REC(28:1) TO WS-CLASS1
               IF WS-CLASS1 = 'A' OR WS-CLASS1 = 'B' OR
                  WS-CLASS1 = 'C' OR WS-CLASS1 = 'D'
                   IF WS-REC(29:3) = '001'
                       STRING WS-CLASS1 '1' DELIMITED BY SIZE
                           INTO WS-CLASS2
                       ADD 1 TO WS-UPGRADED
                   ELSE
                       MOVE 'BADVERSION' TO WS-REASON
                   END-IF
               ELSE
                   MOVE 'BADCLASS' TO WS-REASON
               END-IF
           ELSE
               MOVE WS-REC(28:2) TO WS-CLASS2
               IF (WS-CLASS2(1:1) NOT = 'A' AND
                  WS-CLASS2(1:1) NOT = 'B' AND
                  WS-CLASS2(1:1) NOT = 'C' AND
                  WS-CLASS2(1:1) NOT = 'D') OR
                  WS-CLASS2(2:1) < '0' OR
                  WS-CLASS2(2:1) > '9'
                   MOVE 'BADCLASS' TO WS-REASON
               ELSE
                   IF WS-REC(30:3) NOT = '002'
                       MOVE 'BADVERSION' TO WS-REASON
                   END-IF
               END-IF
           END-IF
           .
       3000-CONTROL.
           MOVE SPACES TO K-LINE
           MOVE 1 TO WS-PTR
           STRING 'CONTROL|RECEIVED=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE RECV-N TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|ACCEPTED=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE ACC-N TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|REJECTED=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE REJ-N TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|UPGRADED=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE WS-UPGRADED TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           WRITE K-LINE
           MOVE SPACES TO K-LINE
           MOVE 1 TO WS-PTR
           STRING 'REJ|BADID=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE REJ-ID TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|BADNAME=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE REJ-NAME TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|BADSTATUS=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE REJ-STATUS TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|BADCLASS=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE REJ-CLASS TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           STRING '|BADVERSION=' DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           MOVE REJ-VERSION TO WS-NUM
           MOVE WS-NUM TO WS-NUMX
           STRING WS-NUMX DELIMITED BY SIZE
               INTO K-LINE WITH POINTER WS-PTR
           WRITE K-LINE
           .
