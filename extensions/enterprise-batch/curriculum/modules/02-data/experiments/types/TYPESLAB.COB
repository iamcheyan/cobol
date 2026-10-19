       IDENTIFICATION DIVISION.
       PROGRAM-ID. TYPESLAB.
      *固定入力ファイルを使うM02の型実験：
      *PIC AとPIC
      *条件名、VALUE、01/05グループ。学習用の
      *実験であり、CUSTOMERロードの実装ではない。
      *要点：数字を含む英数字をPIC Aへ移しても
      *拒否されない。IS ALPHABETICで検証必要がある。
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
