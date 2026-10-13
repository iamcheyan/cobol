       IDENTIFICATION DIVISION.
       PROGRAM-ID. M06-INDEXED-HOLD-PROBE.
      *> Lesson 06.4 companion: hold an indexed file OPEN I-O until
      *> stdin closes, so a second process can be launched against the
      *> same file.  check.sh runs two copies at once and reads the
      *> OPEN status of each; both reporting 00 proves the default
      *> GnuCOBOL/BDB handler does NOT provide cross-process mutual
      *> exclusion, which is why the JOB layer (run.sh .lock) must.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IX-FILE ASSIGN TO DYNAMIC IX-PATH
               ORGANIZATION IS INDEXED ACCESS MODE IS DYNAMIC
               RECORD KEY IS IX-KEY FILE STATUS IS IX-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD IX-FILE.
       01 IX-RECORD.
          05 IX-KEY PIC X(4).
          05 IX-VALUE PIC X(4).
       WORKING-STORAGE SECTION.
       01 IX-PATH PIC X(4096).
       01 IX-STATUS PIC XX.
       01 HOLD-LINE PIC X(80).
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IX-PATH FROM ENVIRONMENT 'IX_PATH'
           OPEN I-O IX-FILE
           DISPLAY 'HOLD-OPEN=' IX-STATUS
           ACCEPT HOLD-LINE
           CLOSE IX-FILE
           DISPLAY 'HOLD-CLOSE=' IX-STATUS
           IF IX-STATUS NOT = '00' MOVE 12 TO RETURN-CODE END-IF
           GOBACK.
