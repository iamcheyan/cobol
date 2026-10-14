      * 日本語：第25課：USING のデータ方向と引数の受け渡し方法を比較する。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON25.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 日本語：共有契約を呼び出し側と呼び出される側のプログラムにコピーする。
      * 日本語：符号属性とバイナリ記憶域のサイズを統一する。
       COPY "AMOUNT-INTERFACE.CPY".
      * 日本語：3つのソースプログラムはすべてこの宣言を使ってコンパイルする。
      * 日本語：各呼び出しから戻った後の呼び出し側記憶域の期待値。
       01 WS-EXPECTED USAGE BINARY-LONG VALUE ZERO.
      * 日本語：比較前に呼び出し側記憶域の実際値をコピーする。
       01 WS-ACTUAL USAGE BINARY-LONG VALUE ZERO.
      * 日本語：この編集項目は読みやすくするため先行ゼロを付ける。
       01 WS-EDITED-ACTUAL PIC 9(9) VALUE ZERO.
       01 WS-MODE PIC X(15) VALUE SPACES.
      * 日本語：これらのカウンターはプログラム呼び出しの間、呼び出し側が保持する。
       01 WS-PASS-COUNT PIC 9(3) VALUE ZERO.
       01 WS-FAIL-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REFERENCE-COUNT PIC 9(3) VALUE ZERO.
       01 WS-CONTENT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALUE-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 日本語：3つのサブプログラム呼び出しがすべて戻ってから、メインを終了する。
       0000-MAIN.
           PERFORM 1000-RUN-MODE-CASES
           PERFORM 9000-DISPLAY-SUMMARY
           IF WS-FAIL-COUNT NOT = ZERO
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 日本語：各引数受け渡し方法について1回ずつ確認する。
       1000-RUN-MODE-CASES.
           PERFORM 1100-TEST-REFERENCE
           PERFORM 1200-TEST-CONTENT
           PERFORM 1300-TEST-VALUE.
      * 日本語：BY REFERENCE は呼び出し側の記憶域を ADD-ONE と共有する。
      * 日本語：サブプログラムのリンケージ項目は同じインターフェース項目を指す。
       1100-TEST-REFERENCE.
      * 日本語：期待値 11 は初期値 10 に 1 を加えた結果。
           MOVE 10 TO AMOUNT-ARGUMENT
           MOVE 11 TO WS-EXPECTED
           MOVE "BY REFERENCE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * 日本語：BY CONTENT は ADD-ONE に変更可能な一時コピーを渡す。
      * 日本語：一時コピー内の加算は呼び出し側の記憶域を変更しない。
       1200-TEST-CONTENT.
           MOVE 20 TO AMOUNT-ARGUMENT
           MOVE 20 TO WS-EXPECTED
           MOVE "BY CONTENT" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * 日本語：BY VALUE は全語長整数を REPORT-BINARY に渡す。
      * 日本語：呼び出される側は呼び出し側の記憶域アドレスなしで値を読み取る。
       1300-TEST-VALUE.
           MOVE 30 TO AMOUNT-ARGUMENT
           MOVE 30 TO WS-EXPECTED
           MOVE "BY VALUE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "REPORT-BINARY" USING BY VALUE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * 日本語：ここで BY VALUE が使う全語長型は BINARY-LONG で定義する。
      * 日本語：呼び出し側は各呼び出しの前に期待値を設定する。
       8000-DISPLAY-BEFORE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-ACTUAL
           DISPLAY "CALLER=BEFORE MODE="
               FUNCTION TRIM(WS-MODE TRAILING)
               " VALUE=" WS-EDITED-ACTUAL.
      * 日本語：サブプログラムから戻った後、呼び出し側から見える値を確認する。
      * 日本語：実際値用の別項目を使い、呼び出し側の項目を変更せずに保つ。
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
      * 日本語：最終プロセスステータスは呼び出し側の検証結果を反映する。
      * 日本語：不一致の場合はプロセスの失敗ステータスとして報告する。
      * 日本語：方法ごとの集計で、どの呼び出し規約が成功したかを示す。
       9000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY PASS=" WS-PASS-COUNT
               " FAIL=" WS-FAIL-COUNT
           DISPLAY "MODE REFERENCE=" WS-REFERENCE-COUNT
               " CONTENT=" WS-CONTENT-COUNT " VALUE=" WS-VALUE-COUNT.
