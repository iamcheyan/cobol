      * Lesson 24: CALL a separately compiled amount validator.
      * 第24课：CALL单独编译的金额验证程序。
      * レッスン24：別途コンパイルした金額検証プログラムをCALLします。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON24.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The amount uses implied cents in its numeric storage.
      * 金额的数值存储采用隐含分。
      * 金額の数値ストレージでは、セントを暗黙的に表します。
       01 WS-AMOUNT PIC 9(7)V99 VALUE ZERO.
      * The called program writes its decision into this caller field.
      * 被调用程序将判定结果写入此调用方字段。
      * 呼び出されたプログラムは、判定結果をこの呼び出し元のフィールドに書き込みます。
       01 WS-CHECK-RESULT PIC X(15) VALUE SPACES.
      * This edited field adds a decimal point only for DISPLAY.
      * 此编辑字段仅在DISPLAY时添加小数点。
      * この編集フィールドはDISPLAY時にだけ小数点を加えます。
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
      * Counters belong to this program and persist between calls.
      * 计数器属于此程序，并在多次调用间保留。
      * カウンターはこのプログラムに属し、呼び出しの間も保持されます。
       01 WS-CHECK-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ZERO-COUNT PIC 9(3) VALUE ZERO.
       01 WS-LIMIT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main stops only after each called program has returned.
      * 只有每个被调用程序都返回后，主程序才会停止。
      * 呼び出した各プログラムが戻った後に限り、メイン処理を終了します。
       0000-MAIN.
           DISPLAY "CALLER=START"
           PERFORM 1000-RUN-CHECK-CASES
           DISPLAY "CALLER=RESUMED"
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
      * Each case prepares a new value, then uses the same CALL.
      * 每个用例准备一个新值，然后使用相同的CALL。
      * 各ケースで新しい値を準備し、同じCALLを使います。
       1000-RUN-CHECK-CASES.
           PERFORM 1100-CHECK-ORDINARY-AMOUNT
           PERFORM 1200-CHECK-ZERO-AMOUNT
           PERFORM 1300-CHECK-LIMIT-AMOUNT
           PERFORM 1400-CHECK-OVER-LIMIT-AMOUNT
           PERFORM 1500-CHECK-SMALL-POSITIVE
           PERFORM 1600-CHECK-BELOW-LIMIT
           PERFORM 1700-CHECK-LARGEST-AMOUNT
           PERFORM 1800-CHECK-MIDRANGE-AMOUNT.
      * This ordinary amount is inside the accepted range.
      * 此普通金额在可接受范围内。
      * この通常の金額は許容範囲内です。
       1100-CHECK-ORDINARY-AMOUNT.
           MOVE 125.50 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * Zero is outside the business rule.
      * 零不符合业务规则。
      * ゼロは業務ルールの範囲外です。
       1200-CHECK-ZERO-AMOUNT.
           MOVE ZERO TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * The configured maximum is inclusive.
      * 配置的最大值包含在有效范围内。
      * 設定した最大値は許容範囲に含まれます。
       1300-CHECK-LIMIT-AMOUNT.
           MOVE 1000.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * One cent above the configured maximum is rejected.
      * 高于配置最大值一分的金额会被拒绝。
      * 設定した最大値を1セント超える金額は拒否されます。
       1400-CHECK-OVER-LIMIT-AMOUNT.
           MOVE 1000.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * The smallest positive amount can be accepted.
      * 最小的正金额可以被接受。
      * 最小の正の金額は受け入れ可能です。
       1500-CHECK-SMALL-POSITIVE.
           MOVE 0.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * This value is just below the configured maximum.
      * 此值略低于配置的最大值。
      * この値は設定した最大値をわずかに下回ります。
       1600-CHECK-BELOW-LIMIT.
           MOVE 999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * PIC capacity and the business validation limit differ.
      * PIC容量与业务验证上限不同。
      * PICの容量と業務上の検証上限は異なります。
       1700-CHECK-LARGEST-AMOUNT.
           MOVE 9999999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * A midrange amount checks the rule away from both boundaries.
      * 中间范围的金额用于验证远离两个边界时的规则。
      * 中間値の金額で、両方の境界から離れた場合のルールを確認します。
       1800-CHECK-MIDRANGE-AMOUNT.
           MOVE 500.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * CALL transfers control to the named program unit.
      * CALL将控制权转交给指定程序单元。
      * CALLは指定したプログラム単位に制御を渡します。
      * This literal matches PROGRAM-ID CHECK-AMOUNT in the callee.
      * 此字面量与被调用程序中的PROGRAM-ID CHECK-AMOUNT相匹配。
      * このリテラルは、呼び出し先のPROGRAM-ID CHECK-AMOUNTと一致します。
      * USING passes the amount first and result storage second.
      * USING先传递金额，再传递结果存储字段。
      * USINGでは、最初に金額、次に結果の格納領域を渡します。
      * Default BY REFERENCE lets the callee update WS-CHECK-RESULT.
      * 默认的BY REFERENCE允许被调用方更新WS-CHECK-RESULT。
      * デフォルトのBY REFERENCEにより、呼び出し先はWS-CHECK-RESULTを更新できます。
      * The caller reuses the same storage for every test amount.
      * 调用方为每个测试金额重复使用相同的存储字段。
      * 呼び出し元は各テスト金額に同じストレージを再利用します。
       2000-CALL-AMOUNT-CHECK.
           MOVE SPACES TO WS-CHECK-RESULT
           MOVE WS-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "CALL=BEGIN AMOUNT=" WS-EDITED-AMOUNT
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
           DISPLAY "CALL=RETURN STATUS="
               FUNCTION TRIM(WS-CHECK-RESULT TRAILING)
           PERFORM 2100-COUNT-CHECK-RESULT.
      * Execution resumes here after the subprogram executes GOBACK.
      * 子程序执行GOBACK后，程序从此处继续。
      * サブプログラムがGOBACKを実行すると、ここから処理を再開します。
       2100-COUNT-CHECK-RESULT.
           ADD 1 TO WS-CHECK-COUNT
           EVALUATE WS-CHECK-RESULT
               WHEN "VALID"
                   ADD 1 TO WS-VALID-COUNT
               WHEN "ZERO-AMOUNT"
                   ADD 1 TO WS-ZERO-COUNT
                   ADD 1 TO WS-REJECT-COUNT
               WHEN "LIMIT-EXCEEDED"
                   ADD 1 TO WS-LIMIT-COUNT
                   ADD 1 TO WS-REJECT-COUNT
               WHEN OTHER
                   ADD 1 TO WS-REJECT-COUNT
           END-EVALUATE.
      * The caller displays totals after all eight calls return.
      * 八次调用全部返回后，调用方显示总计。
      * 8回の呼び出しがすべて戻った後、呼び出し元が合計を表示します。
       3000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY CHECKED=" WS-CHECK-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECT-COUNT
           DISPLAY "REJECT ZERO=" WS-ZERO-COUNT
               " OVER_LIMIT=" WS-LIMIT-COUNT.
