       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 上限の値も処理対象です。
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
           DISPLAY "最終サンプル番号=" WS-LAST-SAMPLE
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               EVALUATE WS-SAMPLE-INDEX
                   WHEN 1
                       DISPLAY "例=001 符号=D 額=125.50"
                   WHEN 2
                       DISPLAY "例=002 符号=W 額=040.10"
                   WHEN 3
                       DISPLAY "例=003 符号=T 額=075.00"
                   WHEN OTHER
      * 上限が例数超過ならここへ。存在確認なし。
                       DISPLAY "例=UNMAPPED"
               END-EVALUATE
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
           DISPLAY "処理件数=" WS-PROCESSED-COUNT
           STOP RUN.
