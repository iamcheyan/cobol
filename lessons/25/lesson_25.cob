      * Lesson 25: compare USING data directions and argument modes.
      * 中文：第25课：比较 USING 数据方向和参数传递模式。
      * 日本語：第25課：USING のデータ方向と引数の受け渡し方法を比較する。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON25.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * One shared contract is copied into caller and callee programs.
      * 中文：一份共享契约会复制到调用方和被调用方程序中。
      * 日本語：共有契約を呼び出し側と呼び出される側のプログラムにコピーする。
      * It keeps signedness and binary storage size consistent.
      * 中文：它能保持有符号属性和二进制存储大小一致。
      * 日本語：符号属性とバイナリ記憶域のサイズを統一する。
       COPY "AMOUNT-INTERFACE.CPY".
      * All three source programs compile from this declaration.
      * 中文：三个源程序都根据此声明编译。
      * 日本語：3つのソースプログラムはすべてこの宣言を使ってコンパイルする。
      * Expected caller storage after each call returns.
      * 中文：每次调用返回后调用方存储区中的预期值。
      * 日本語：各呼び出しから戻った後の呼び出し側記憶域の期待値。
       01 WS-EXPECTED USAGE BINARY-LONG VALUE ZERO.
      * Actual caller storage is copied before comparison.
      * 中文：比较前会复制调用方存储区的实际值。
      * 日本語：比較前に呼び出し側記憶域の実際値をコピーする。
       01 WS-ACTUAL USAGE BINARY-LONG VALUE ZERO.
      * This edited field adds leading zeroes for readable output.
      * 中文：此编辑字段会添加前导零，以便清晰显示。
      * 日本語：この編集項目は読みやすくするため先行ゼロを付ける。
       01 WS-EDITED-ACTUAL PIC 9(9) VALUE ZERO.
       01 WS-MODE PIC X(15) VALUE SPACES.
      * These counters belong to the caller between program calls.
      * 中文：这些计数器在程序调用之间由调用方持有。
      * 日本語：これらのカウンターはプログラム呼び出しの間、呼び出し側が保持する。
       01 WS-PASS-COUNT PIC 9(3) VALUE ZERO.
       01 WS-FAIL-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REFERENCE-COUNT PIC 9(3) VALUE ZERO.
       01 WS-CONTENT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALUE-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main stops only after all three subprogram calls return.
      * 中文：只有三个子程序调用全部返回后，主程序才会停止。
      * 日本語：3つのサブプログラム呼び出しがすべて戻ってから、メインを終了する。
       0000-MAIN.
           PERFORM 1000-RUN-MODE-CASES
           PERFORM 9000-DISPLAY-SUMMARY
           IF WS-FAIL-COUNT NOT = ZERO
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * Run one check for each argument-passing mode.
      * 中文：对每种参数传递模式分别执行一次检查。
      * 日本語：各引数受け渡し方法について1回ずつ確認する。
       1000-RUN-MODE-CASES.
           PERFORM 1100-TEST-REFERENCE
           PERFORM 1200-TEST-CONTENT
           PERFORM 1300-TEST-VALUE.
      * BY REFERENCE shares caller storage with ADD-ONE.
      * 中文：BY REFERENCE 让 ADD-ONE 与调用方共享存储区。
      * 日本語：BY REFERENCE は呼び出し側の記憶域を ADD-ONE と共有する。
      * The subprogram's linkage item names the same interface item.
      * 中文：子程序的链接项指向同一个接口项。
      * 日本語：サブプログラムのリンケージ項目は同じインターフェース項目を指す。
       1100-TEST-REFERENCE.
      * Expected 11 is the result of adding one to the initial 10.
      * 中文：预期值 11 是在初始值 10 上加 1 的结果。
      * 日本語：期待値 11 は初期値 10 に 1 を加えた結果。
           MOVE 10 TO AMOUNT-ARGUMENT
           MOVE 11 TO WS-EXPECTED
           MOVE "BY REFERENCE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY REFERENCE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY CONTENT gives ADD-ONE a temporary copy to change.
      * 中文：BY CONTENT 为 ADD-ONE 提供可修改的临时副本。
      * 日本語：BY CONTENT は ADD-ONE に変更可能な一時コピーを渡す。
      * The increment in that temporary cannot change caller storage.
      * 中文：临时副本中的递增不会改变调用方存储区。
      * 日本語：一時コピー内の加算は呼び出し側の記憶域を変更しない。
       1200-TEST-CONTENT.
           MOVE 20 TO AMOUNT-ARGUMENT
           MOVE 20 TO WS-EXPECTED
           MOVE "BY CONTENT" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "ADD-ONE" USING BY CONTENT AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BY VALUE passes a full-word integer to REPORT-BINARY.
      * 中文：BY VALUE 将全字长整数传递给 REPORT-BINARY。
      * 日本語：BY VALUE は全語長整数を REPORT-BINARY に渡す。
      * The callee reads the value without a caller storage address.
      * 中文：被调用方读取该值时无需调用方存储地址。
      * 日本語：呼び出される側は呼び出し側の記憶域アドレスなしで値を読み取る。
       1300-TEST-VALUE.
           MOVE 30 TO AMOUNT-ARGUMENT
           MOVE 30 TO WS-EXPECTED
           MOVE "BY VALUE" TO WS-MODE
           PERFORM 8000-DISPLAY-BEFORE
           CALL "REPORT-BINARY" USING BY VALUE AMOUNT-ARGUMENT
           PERFORM 8100-CHECK-ACTUAL.
      * BINARY-LONG provides the full-word type used by BY VALUE here.
      * 中文：此处 BY VALUE 使用的全字长类型由 BINARY-LONG 提供。
      * 日本語：ここで BY VALUE が使う全語長型は BINARY-LONG で定義する。
      * The caller sets expected storage before making each call.
      * 中文：调用方在每次调用前设置预期存储值。
      * 日本語：呼び出し側は各呼び出しの前に期待値を設定する。
       8000-DISPLAY-BEFORE.
           MOVE AMOUNT-ARGUMENT TO WS-EDITED-ACTUAL
           DISPLAY "CALLER=BEFORE MODE="
               FUNCTION TRIM(WS-MODE TRAILING)
               " VALUE=" WS-EDITED-ACTUAL.
      * Check the caller-visible value after the subprogram returns.
      * 中文：子程序返回后检查调用方可见的值。
      * 日本語：サブプログラムから戻った後、呼び出し側から見える値を確認する。
      * A separate actual field keeps the caller item unmodified.
      * 中文：单独的实际值字段可保持调用方数据项不变。
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
      * The final process status reflects caller-side verification.
      * 中文：最终进程状态反映调用方的验证结果。
      * 日本語：最終プロセスステータスは呼び出し側の検証結果を反映する。
      * A mismatch is reported as a failed process status.
      * 中文：值不匹配时会报告失败的进程状态。
      * 日本語：不一致の場合はプロセスの失敗ステータスとして報告する。
      * Per-mode totals identify which calling convention passed.
      * 中文：各模式的汇总可指出哪种调用约定通过了检查。
      * 日本語：方法ごとの集計で、どの呼び出し規約が成功したかを示す。
       9000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY PASS=" WS-PASS-COUNT
               " FAIL=" WS-FAIL-COUNT
           DISPLAY "MODE REFERENCE=" WS-REFERENCE-COUNT
               " CONTENT=" WS-CONTENT-COUNT " VALUE=" WS-VALUE-COUNT.
