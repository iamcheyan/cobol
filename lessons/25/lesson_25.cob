      * 第25課：USINGのデータ方向と引数の受け渡し方法を比較する。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON25.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 共有契約を呼び出し側と呼び出される側のプロ
      * グラムにコピーする。
      * 符号属性とバイナリ記憶域のサイズを一致させます。
       COPY "AMOUNT-INTERFACE.CPY".
      * 3つのソースプログラムはすべてこの宣言を使
      * ってコンパイルする。
      * 各呼び出し後に呼び出し側の記憶域へ期待する値です。
       01 WS-EXPECTED USAGE BINARY-LONG VALUE ZERO.
      * 比較前に呼び出し側記憶域の実際値を別項目へコピーします。
       01 WS-ACTUAL USAGE BINARY-LONG VALUE ZERO.
      * 編集項目は先行ゼロを付け、値を読みやすく表示します。
       01 WS-EDITED-ACTUAL PIC 9(9) VALUE ZERO.
       01 WS-MODE PIC X(15) VALUE SPACES.
      * これらのカウンターはプログラム呼び出しの間
      * 、呼び出し側が保持する。
       01 WS-PASS-COUNT PIC 9(3) VALUE ZERO.
       01 WS-FAIL-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REFERENCE-COUNT PIC 9(3) VALUE ZERO.
       01 WS-CONTENT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALUE-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 3つのサブプログラム呼び出しが戻った後、メインを終了します。
       0000-MAIN.
           PERFORM 1000-RUN-MODE-CASES
           PERFORM 9000-DISPLAY-SUMMARY
           IF WS-FAIL-COUNT NOT = ZERO
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 各引数受け渡し方法について1回ずつ確認する。
       1000-RUN-MODE-CASES.
           PERFORM 1100-TEST-REFERENCE
           PERFORM 1200-TEST-CONTENT
           PERFORM 1300-TEST-VALUE.
      * BY REFERENCEは呼び出し側の記憶域をADD-ONEと共有します。
      * リンケージ項目は呼び出し側と同じ記憶域を参照します。
       1100-TEST-REFERENCE.
      * 期待値 11 は初期値 10 に 1 を加えた結果。
           MOVE 10 TO AMOUNT-ARGUMENT
           MOVE 11 TO WS-EXPECTED
           MOVE "BY REFERENCE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY CONTENTはADD-ONEに一時コピーを渡します。
      * 加算で一時コピーは変わりますが、呼び出し側の値は変わりません。
       1200-TEST-CONTENT.
           MOVE 20 TO AMOUNT-ARGUMENT
           MOVE 20 TO WS-EXPECTED
           MOVE "BY CONTENT" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY VALUE は全語長整数を REPORT-BINARY に渡す。
      * 呼び出される側は呼び出し側の記憶域アドレス
      * なしで値を読み取る。
       1300-TEST-VALUE.
           MOVE 30 TO AMOUNT-ARGUMENT
           MOVE 30 TO WS-EXPECTED
           MOVE "BY VALUE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "REPORT-BINARY" USING BY VALUE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY VALUEの全語長引数にはBINARY-LONGを使います。
      * 呼び出し側は各呼び出しの前に期待値を設定します。
       8000-DISPLAY-BEFORE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-ACTUAL
           DISPLAY "CALLER=BEFORE MODE="
               FUNCTION TRIM(WS-MODE TRAILING)
               " VALUE=" WS-EDITED-ACTUAL.
      * サブプログラムから戻った後、呼び出し側から
      * 見える値を確認する。
      * 実際値用の別項目を使い、呼び出し側の項目を
      * 変更せずに保つ。
       8100-CHECK-ACTUAL.
           MOVE AMOUNT-ARGUMENT TO WS-ACTUAL
           MOVE WS-ACTUAL TO WS-EDITED-ACTUAL
           IF WS-ACTUAL = WS-EXPECTED
               ADD 1 TO WS-PASS-COUNT
               EVALUATE WS-MODE
                   WHEN "BY REFERENCE"
                       ADD 1 TO WS-REFERENCE-COUNT
                   WHEN "BY CONTENT"
                       ADD 1 TO WS-CONTENT-COUNT
                   WHEN "BY VALUE"
                       ADD 1 TO WS-VALUE-COUNT
               END-EVALUATE
               DISPLAY "CALLER=AFTER MODE="
                   FUNCTION TRIM(WS-MODE TRAILING)
                   " VALUE=" WS-EDITED-ACTUAL " CHECK=PASS"
           ELSE
               ADD 1 TO WS-FAIL-COUNT
               DISPLAY "CALLER=AFTER MODE="
                   FUNCTION TRIM(WS-MODE TRAILING)
                   " VALUE=" WS-EDITED-ACTUAL " CHECK=FAIL"
           END-IF.
      * 最終プロセスステータスは呼び出し側の検証結果を反映します。
      * 不一致があれば、プロセスは失敗ステータスを返します。
      * 方法ごとの集計で、呼び出し規約ごとの成否を確認します。
       9000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY PASS=" WS-PASS-COUNT
               " FAIL=" WS-FAIL-COUNT
           DISPLAY "MODE REFERENCE=" WS-REFERENCE-COUNT
               " CONTENT=" WS-CONTENT-COUNT " VALUE=" WS-VALUE-COUNT.
