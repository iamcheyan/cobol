       IDENTIFICATION DIVISION.
       PROGRAM-ID. BROKEN-PERFORM.
      *01.2の意図的なビルドエラー例。PERFORM先の
      *5000-SETTLE-PARAGRAPHは未定義で、cobcは
      *未定義段落を報告。診断から該当行を特定し・
      *誤った名前を修正または変更。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COUNT PIC 9(4) VALUE 0.
       PROCEDURE DIVISION.
       1000-MAIN.
           PERFORM 5000-SETTLE-PARAGRAPH
           DISPLAY 'COUNT=' WS-COUNT
           GOBACK.
       2000-COUNT-ONE.
           ADD 1 TO WS-COUNT.
