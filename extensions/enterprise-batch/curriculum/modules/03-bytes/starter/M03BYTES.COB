      *> STARTER for module 03. Builds as-is, but is INCOMPLETE.
      *> While WS-EXERCISES-DONE is 'N' the runner ends RC12 and
      *> publishes nothing. Fill the TODO paragraphs, set it to 'Y',
      *> and re-run.
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
       01 WS-EXERCISES-DONE PIC X VALUE 'N'.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT WS-LESSON FROM ENVIRONMENT 'M03_LESSON'
           IF WS-EXERCISES-DONE NOT = 'Y'
               DISPLAY 'TODO,starter/M03BYTES.COB is not finished'
               MOVE 12 TO RETURN-CODE
               GOBACK
           END-IF
           EVALUATE WS-LESSON
               WHEN '1' PERFORM 1100-LESSON-1
               WHEN '2' PERFORM 1200-LESSON-2
               WHEN '3' PERFORM 1300-LESSON-3
               WHEN OTHER MOVE 12 TO RETURN-CODE
           END-EVALUATE
           GOBACK.
       1100-LESSON-1.
      *> TODO 03.1: declare DISPLAY / SIGN SEPARATE / COMP-3 / COMP
      *> fields, print LENGTH OF each and prove COMP big-endian by
      *> writing a known 0x01020304 value to abi.bin.
           DISPLAY 'LESSON,03.1'
           DISPLAY 'TODO,03.1 declarations'.
       1200-LESSON-2.
      *> TODO 03.2: store +12345.67 and -12345.67 in DISPLAY, SIGN
      *> LEADING SEPARATE, COMP-3 and an integer minor-unit COMP field,
      *> then emit their raw bytes as lowercase hex.
           DISPLAY 'LESSON,03.2'
           DISPLAY 'TODO,03.2 hexdump'.
       1300-LESSON-3.
      *> TODO 03.3: read 7-byte COMP-3 records from input.dat, validate
      *> every digit nibble 0-9 and the sign nibble C/D BEFORE any
      *> arithmetic, and report OK / REJECT with a reason.
           DISPLAY 'LESSON,03.3'
           DISPLAY 'TODO,03.3 packed parser'.
