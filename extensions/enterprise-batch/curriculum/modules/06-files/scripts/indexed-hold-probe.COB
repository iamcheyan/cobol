       IDENTIFICATION DIVISION.
       PROGRAM-ID. M06-INDEXED-HOLD-PROBE.
      *> 06.4 補助実験：入力終了まで索引を保持。
      *> OPEN I-O で保持し、別プロセスからも開く。
      *> check.sh は2つを同時起動し、
      *> 各 OPEN の状態を確認。両方が00なら、標準の
      *> GnuCOBOL/BDB はプロセス間排他を行わず、
      *> JOB 層で run.sh の .lock が必要。
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
