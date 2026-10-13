      *> M03BYTES: module 03 reference. Lesson via M03_LESSON=1|2|3.
      *> Lesson 1 declaration logic vs ABI; 2 raw bytes; 3 packed parse.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. M03BYTES.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ABI-FILE ASSIGN TO 'abi.bin'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ABI-STATUS.
           SELECT AMT-FILE ASSIGN TO 'amounts.bin'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-AMT-STATUS.
           SELECT IN-FILE ASSIGN TO 'input.dat'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-IN-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ABI-FILE.
       01 ABI-OUT PIC X(8).
       FD AMT-FILE.
       01 AMT-OUT PIC X(59).
       FD IN-FILE.
       01 IN-REC PIC X(7).
       WORKING-STORAGE SECTION.
       01 WS-ABI-STATUS PIC XX.
       01 WS-AMT-STATUS PIC XX.
       01 WS-IN-STATUS PIC XX.
       01 WS-LESSON PIC X(1).
       01 WS-LEN PIC 9(2).
       01 WS-NAME PIC X(24).
       01 WS-HEXBUF PIC X(64).
       01 WS-HEXLEN PIC 9(2).
       01 WS-HEXOUT PIC X(128).
       01 WS-HEXDIG PIC X(16) VALUE '0123456789abcdef'.
       01 WS-BYTE PIC 9(3).
       01 WS-HI PIC 9(3).
       01 WS-LO PIC 9(3).
       01 WS-NIB PIC 9(3).
       01 WS-J PIC 9(3).
       01 WS-K PIC 9(3).
       01 WS-AMOUNTS.
          05 AMT-DISPLAY PIC S9(5)V99 VALUE +12345.67.
          05 AMT-SIGN-SEP PIC S9(5)V99 SIGN LEADING SEPARATE
             VALUE +12345.67.
          05 AMT-DISPLAY-NEG PIC S9(5)V99 VALUE -12345.67.
          05 AMT-SIGN-SEP-NEG PIC S9(5)V99 SIGN LEADING SEPARATE
             VALUE -12345.67.
          05 AMT-PACKED PIC S9(5)V99 COMP-3 VALUE +12345.67.
          05 AMT-PACKED-NEG PIC S9(5)V99 COMP-3 VALUE -12345.67.
          05 AMT-PACKED-BIG PIC S9(11)V99 COMP-3 VALUE +12345.67.
          05 AMT-BINARY-4 PIC S9(4) COMP VALUE +1234.
          05 AMT-BINARY-9 PIC S9(9) COMP VALUE +1234567.
          05 AMT-BINARY-18 PIC S9(18) COMP VALUE +123456789012345.
       01 WS-AMOUNTS-X REDEFINES WS-AMOUNTS.
          05 AMT-DISPLAY-X PIC X(7).
          05 AMT-SIGN-SEP-X PIC X(8).
          05 AMT-DISPLAY-NEG-X PIC X(7).
          05 AMT-SIGN-SEP-NEG-X PIC X(8).
          05 AMT-PACKED-X PIC X(4).
          05 AMT-PACKED-NEG-X PIC X(4).
          05 AMT-PACKED-BIG-X PIC X(7).
          05 AMT-BINARY-4-X PIC X(2).
          05 AMT-BINARY-9-X PIC X(4).
          05 AMT-BINARY-18-X PIC X(8).
       01 WS-ABI.
          05 ABI-COMP PIC S9(9) COMP VALUE 16909060.
          05 ABI-COMP5 PIC S9(9) COMP-5 VALUE 16909060.
       01 WS-ABI-X REDEFINES WS-ABI.
          05 ABI-COMP-X PIC X(4).
          05 ABI-COMP5-X PIC X(4).
       01 WS-WRK.
          05 WRK-REC PIC X(7).
          05 WRK-BYTE REDEFINES WRK-REC.
             10 WRK-BYTE-ITEM PIC X OCCURS 7 TIMES.
       01 WS-SEQ PIC 9(4).
       01 WS-TOTAL PIC 9(4) VALUE 0.
       01 WS-ACCEPTED PIC 9(4) VALUE 0.
       01 WS-REJECTED PIC 9(4) VALUE 0.
       01 WS-NDIGIT PIC 9(2).
       01 WS-DIGITS PIC X(13).
       01 WS-SIGN PIC X(1).
       01 WS-VERDICT PIC X(6).
       01 WS-REASON PIC X(16).
       01 WS-VALUE PIC X(15).
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT WS-LESSON FROM ENVIRONMENT 'M03_LESSON'
           EVALUATE WS-LESSON
               WHEN '1' PERFORM 1100-LESSON-1
               WHEN '2' PERFORM 1200-LESSON-2
               WHEN '3' PERFORM 1300-LESSON-3
               WHEN OTHER
                   DISPLAY 'ERROR,' WS-LESSON
                   MOVE 12 TO RETURN-CODE
           END-EVALUATE
           GOBACK.
       1100-LESSON-1.
           DISPLAY 'LESSON,03.1'
           DISPLAY 'ABI,LINUX-X86-64,GCOB32BE,DEFAULT-DIALECT'
           MOVE LENGTH OF AMT-DISPLAY TO WS-LEN
           DISPLAY 'DECL,AMT-DISPLAY,DISPLAY,07,' WS-LEN ',1B/digit'
           MOVE LENGTH OF AMT-SIGN-SEP TO WS-LEN
           DISPLAY 'DECL,AMT-SIGN-SEP,SIGN-LEADING-SEPARATE,07,'
             WS-LEN ',digits+1'
           MOVE LENGTH OF AMT-PACKED TO WS-LEN
           DISPLAY 'DECL,AMT-PACKED,COMP-3,07,' WS-LEN
             ',ceil((7+1)/2)'
           MOVE LENGTH OF AMT-PACKED-BIG TO WS-LEN
           DISPLAY 'DECL,AMT-PACKED-BIG,COMP-3,13,' WS-LEN
             ',ceil((13+1)/2)'
           MOVE LENGTH OF AMT-BINARY-4 TO WS-LEN
           DISPLAY 'DECL,AMT-BINARY-4,COMP,04,' WS-LEN ',range-fit'
           MOVE LENGTH OF AMT-BINARY-9 TO WS-LEN
           DISPLAY 'DECL,AMT-BINARY-9,COMP,09,' WS-LEN ',range-fit'
           MOVE LENGTH OF AMT-BINARY-18 TO WS-LEN
           DISPLAY 'DECL,AMT-BINARY-18,COMP,18,' WS-LEN ',range-fit'
           MOVE ABI-COMP-X TO WS-HEXBUF
           MOVE 4 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'ABI,COMP,01020304,' WS-HEXOUT(1:8)
           MOVE ABI-COMP5-X TO WS-HEXBUF
           MOVE 4 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'ABI,COMP-5,NATIVE,' WS-HEXOUT(1:8)
           IF ABI-COMP-X = X'01020304'
               DISPLAY 'ABI,COMP-BIG-ENDIAN,YES'
           ELSE
               DISPLAY 'ABI,COMP-BIG-ENDIAN,NO'
           END-IF
           IF ABI-COMP5-X = X'04030201'
               DISPLAY 'ABI,COMP5-LITTLE-ENDIAN,YES'
           ELSE
               DISPLAY 'ABI,COMP5-LITTLE-ENDIAN,NO'
           END-IF
           MOVE WS-ABI TO ABI-OUT
           OPEN OUTPUT ABI-FILE
           IF WS-ABI-STATUS NOT = '00'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           WRITE ABI-OUT
           CLOSE ABI-FILE.
       1200-LESSON-2.
           DISPLAY 'LESSON,03.2'
           DISPLAY 'AMOUNT,12345.67'
           MOVE AMT-DISPLAY-X TO WS-HEXBUF
           MOVE 7 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-DISPLAY,' WS-HEXOUT(1:14)
           MOVE AMT-SIGN-SEP-X TO WS-HEXBUF
           MOVE 8 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-SIGN-SEP,' WS-HEXOUT(1:16)
           MOVE AMT-DISPLAY-NEG-X TO WS-HEXBUF
           MOVE 7 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-DISPLAY-NEG,' WS-HEXOUT(1:14)
           MOVE AMT-SIGN-SEP-NEG-X TO WS-HEXBUF
           MOVE 8 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-SIGN-SEP-NEG,' WS-HEXOUT(1:16)
           MOVE AMT-PACKED-X TO WS-HEXBUF
           MOVE 4 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-PACKED-POS,' WS-HEXOUT(1:8)
           MOVE AMT-PACKED-NEG-X TO WS-HEXBUF
           MOVE 4 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-PACKED-NEG,' WS-HEXOUT(1:8)
           MOVE AMT-PACKED-BIG-X TO WS-HEXBUF
           MOVE 7 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-PACKED-BIG,' WS-HEXOUT(1:14)
           MOVE AMT-BINARY-4-X TO WS-HEXBUF
           MOVE 2 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-BINARY-4,' WS-HEXOUT(1:4)
           MOVE AMT-BINARY-9-X TO WS-HEXBUF
           MOVE 4 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-COMP-MINOR,' WS-HEXOUT(1:8)
           MOVE AMT-BINARY-18-X TO WS-HEXBUF
           MOVE 8 TO WS-HEXLEN
           PERFORM 2100-HEX
           DISPLAY 'HEX,AMT-BINARY-18,' WS-HEXOUT(1:16)
           MOVE LENGTH OF WS-AMOUNTS TO WS-LEN
           DISPLAY 'TOTAL,' WS-LEN
           MOVE WS-AMOUNTS TO AMT-OUT
           OPEN OUTPUT AMT-FILE
           IF WS-AMT-STATUS NOT = '00'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           WRITE AMT-OUT
           CLOSE AMT-FILE.
       1300-LESSON-3.
           DISPLAY 'LESSON,03.3'
           OPEN INPUT IN-FILE
           IF WS-IN-STATUS NOT = '00'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           MOVE 0 TO WS-TOTAL
           MOVE 0 TO WS-ACCEPTED
           MOVE 0 TO WS-REJECTED
           MOVE 0 TO WS-SEQ
           PERFORM UNTIL WS-IN-STATUS = '10'
               READ IN-FILE
                   AT END CONTINUE
                   NOT AT END
                       ADD 1 TO WS-TOTAL
                       ADD 1 TO WS-SEQ
                       MOVE IN-REC TO WRK-REC
                       PERFORM 2300-VALIDATE
               END-READ
           END-PERFORM
           CLOSE IN-FILE
           DISPLAY 'SUMMARY,TOTAL,' WS-TOTAL
           DISPLAY 'SUMMARY,ACCEPTED,' WS-ACCEPTED
           DISPLAY 'SUMMARY,REJECTED,' WS-REJECTED
           IF WS-REJECTED > 0
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       2300-VALIDATE.
           MOVE 'OK' TO WS-VERDICT
           MOVE SPACES TO WS-REASON
           MOVE SPACES TO WS-DIGITS
           MOVE SPACES TO WS-SIGN
           MOVE 0 TO WS-NDIGIT
           PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > 7
               COMPUTE WS-BYTE =
                   FUNCTION ORD(WRK-BYTE-ITEM(WS-K)) - 1
               DIVIDE WS-BYTE BY 16 GIVING WS-HI REMAINDER WS-LO
               IF WS-K < 7
                   MOVE WS-HI TO WS-NIB
                   PERFORM 2310-DIGIT
                   MOVE WS-LO TO WS-NIB
                   PERFORM 2310-DIGIT
               ELSE
                   MOVE WS-HI TO WS-NIB
                   PERFORM 2310-DIGIT
                   MOVE WS-LO TO WS-NIB
                   PERFORM 2320-SIGN
               END-IF
           END-PERFORM
           MOVE WRK-REC TO WS-HEXBUF
           MOVE 7 TO WS-HEXLEN
           PERFORM 2100-HEX
           IF WS-VERDICT = 'OK'
               ADD 1 TO WS-ACCEPTED
               MOVE SPACES TO WS-VALUE
               STRING WS-SIGN DELIMITED BY SIZE
                   WS-DIGITS(1:11) DELIMITED BY SIZE
                   '.' DELIMITED BY SIZE
                   WS-DIGITS(12:2) DELIMITED BY SIZE
                   INTO WS-VALUE
               END-STRING
               DISPLAY 'REC,' WS-SEQ ',' WS-HEXOUT(1:14)
                   ',OK,' WS-VALUE ','
           ELSE
               ADD 1 TO WS-REJECTED
               DISPLAY 'REC,' WS-SEQ ',' WS-HEXOUT(1:14)
                   ',REJECT,[INVALID],' FUNCTION TRIM(WS-REASON)
           END-IF.
       2310-DIGIT.
           IF WS-NIB > 9
               MOVE 'REJECT' TO WS-VERDICT
               IF WS-REASON = SPACES
                   MOVE 'DIGIT-NOT-0-9' TO WS-REASON
               END-IF
           ELSE
               ADD 1 TO WS-NDIGIT
               IF WS-NDIGIT <= 13
                   MOVE WS-HEXDIG(WS-NIB + 1:1)
                       TO WS-DIGITS(WS-NDIGIT:1)
               END-IF
           END-IF.
       2320-SIGN.
           IF WS-NIB = 12
               MOVE '+' TO WS-SIGN
           ELSE
               IF WS-NIB = 13
                   MOVE '-' TO WS-SIGN
               ELSE
                   MOVE 'REJECT' TO WS-VERDICT
                   MOVE 'BAD-SIGN-NIBBLE' TO WS-REASON
               END-IF
           END-IF.
       2100-HEX.
           MOVE SPACES TO WS-HEXOUT
           MOVE 1 TO WS-J
           PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > WS-HEXLEN
               COMPUTE WS-BYTE =
                   FUNCTION ORD(WS-HEXBUF(WS-K:1)) - 1
               DIVIDE WS-BYTE BY 16 GIVING WS-HI REMAINDER WS-LO
               MOVE WS-HEXDIG(WS-HI + 1:1) TO WS-HEXOUT(WS-J:1)
               ADD 1 TO WS-J
               MOVE WS-HEXDIG(WS-LO + 1:1) TO WS-HEXOUT(WS-J:1)
               ADD 1 TO WS-J
           END-PERFORM.
