       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
      * LAST-SAMPLE は、ループの包括的な上限を制御します。
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
                       DISPLAY "例=UNMAPPED"
               END-EVALUATE
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
      * 実際に UNTIL テストに合格した反復回数を表示します。
           DISPLAY "処理件数=" WS-PROCESSED-COUNT
      * 制限が 3 を超えると、マップされていないサンプル ブランチも適用されます。
           STOP RUN.
