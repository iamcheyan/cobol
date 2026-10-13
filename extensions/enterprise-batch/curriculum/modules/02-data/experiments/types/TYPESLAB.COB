       IDENTIFICATION DIVISION.
       PROGRAM-ID. TYPESLAB.
      *> Module 02 type experiment over a real fixed-width input file:
      *> PIC A vs PIC X, level 78 constant, level 77 item, level 88
      *> condition name, VALUE and a 01/05 group. It is a teaching
      *> experiment only; it is not the CUSTOMER load implementation.
      *> Key fact: moving a digit-bearing alphanumeric into PIC A does
      *> NOT reject it - the program must validate with IS ALPHABETIC.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TYPE-FILE ASSIGN TO DYNAMIC TYPE-PATH
             ORGANIZATION IS LINE SEQUENTIAL
             FILE STATUS IS TYPE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TYPE-FILE.
       01 TYPE-REC PIC X(5).
       WORKING-STORAGE SECTION.
       78 WS-LIMIT VALUE 25.
       77 WS-COUNT PIC 9(5) VALUE 0.
       01 TYPE-PATH PIC X(512).
       01 TYPE-STATUS PIC XX.
       01 WS-EOF PIC X VALUE "N".
       01 WS-DATA.
          05 WS-RAW PIC X(5).
          05 WS-ALPHA PIC A(5).
       01 WS-CLASS PIC X.
          88 CLS-ALPHA VALUE "A".
          88 CLS-MIXED VALUE "M".
       PROCEDURE DIVISION.
       MAIN-PARA.
           ACCEPT TYPE-PATH FROM ENVIRONMENT "TYPESLAB_INPUT"
           OPEN INPUT TYPE-FILE
           IF TYPE-STATUS NOT = "00"
             MOVE 12 TO RETURN-CODE
             STOP RUN
           END-IF
           DISPLAY "TYPESLAB|V1"
           DISPLAY "LIMIT|" WS-LIMIT "|"
           PERFORM UNTIL WS-EOF = "Y"
             READ TYPE-FILE
             EVALUATE TYPE-STATUS
               WHEN "10"
                 MOVE "Y" TO WS-EOF
               WHEN "00"
                 ADD 1 TO WS-COUNT
                 MOVE TYPE-REC TO WS-RAW
                 MOVE TYPE-REC TO WS-ALPHA
                 IF WS-RAW IS ALPHABETIC
                   SET CLS-ALPHA TO TRUE
                 ELSE
                   SET CLS-MIXED TO TRUE
                 END-IF
                 DISPLAY WS-COUNT "|" WS-RAW "|" WS-ALPHA "|"
                   WS-CLASS "|"
               WHEN OTHER
                 MOVE 12 TO RETURN-CODE
                 STOP RUN
             END-EVALUATE
           END-PERFORM
           DISPLAY "COUNT|" WS-COUNT "|"
           CLOSE TYPE-FILE
           STOP RUN.
