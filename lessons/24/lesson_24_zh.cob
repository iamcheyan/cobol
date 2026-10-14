      * 第24课：CALL单独编译的金额验证程序。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON24.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 金额的数值存储采用隐含分。
       01 WS-AMOUNT PIC 9(7)V99 VALUE ZERO.
      * 被调用程序将判定结果写入此调用方字段。
       01 WS-CHECK-RESULT PIC X(15) VALUE SPACES.
      * 此编辑字段仅在DISPLAY时添加小数点。
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
      * 计数器属于此程序，并在多次调用间保留。
       01 WS-CHECK-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ZERO-COUNT PIC 9(3) VALUE ZERO.
       01 WS-LIMIT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 只有每个被调用程序都返回后，主程序才会停止。
       0000-MAIN.
           DISPLAY "CALLER=START"
           PERFORM 1000-RUN-CHECK-CASES
           DISPLAY "CALLER=RESUMED"
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
      * 每个用例准备一个新值，然后使用相同的CALL。
       1000-RUN-CHECK-CASES.
           PERFORM 1100-CHECK-ORDINARY-AMOUNT
           PERFORM 1200-CHECK-ZERO-AMOUNT
           PERFORM 1300-CHECK-LIMIT-AMOUNT
           PERFORM 1400-CHECK-OVER-LIMIT-AMOUNT
           PERFORM 1500-CHECK-SMALL-POSITIVE
           PERFORM 1600-CHECK-BELOW-LIMIT
           PERFORM 1700-CHECK-LARGEST-AMOUNT
           PERFORM 1800-CHECK-MIDRANGE-AMOUNT.
      * 此普通金额在可接受范围内。
       1100-CHECK-ORDINARY-AMOUNT.
           MOVE 125.50 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 零不符合业务规则。
       1200-CHECK-ZERO-AMOUNT.
           MOVE ZERO TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 配置的最大值包含在有效范围内。
       1300-CHECK-LIMIT-AMOUNT.
           MOVE 1000.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 高于配置最大值一分的金额会被拒绝。
       1400-CHECK-OVER-LIMIT-AMOUNT.
           MOVE 1000.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 最小的正金额可以被接受。
       1500-CHECK-SMALL-POSITIVE.
           MOVE 0.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 此值略低于配置的最大值。
       1600-CHECK-BELOW-LIMIT.
           MOVE 999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * PIC容量与业务验证上限不同。
       1700-CHECK-LARGEST-AMOUNT.
           MOVE 9999999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 中间范围的金额用于验证远离两个边界时的规则。
       1800-CHECK-MIDRANGE-AMOUNT.
           MOVE 500.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * CALL将控制权转交给指定程序单元。
      * 此字面量与被调用程序中的PROGRAM-ID CHECK-AMOUNT相匹配。
      * USING先传递金额，再传递结果存储字段。
      * 默认的BY REFERENCE允许被调用方更新WS-CHECK-RESULT。
      * 调用方为每个测试金额重复使用相同的存储字段。
       2000-CALL-AMOUNT-CHECK.
           MOVE SPACES TO WS-CHECK-RESULT
           MOVE WS-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "CALL=BEGIN AMOUNT=" WS-EDITED-AMOUNT
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
           DISPLAY "CALL=RETURN STATUS="
               FUNCTION TRIM(WS-CHECK-RESULT TRAILING)
           PERFORM 2100-COUNT-CHECK-RESULT.
      * 子程序执行GOBACK后，程序从此处继续。
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
      * 八次调用全部返回后，调用方显示总计。
       3000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY CHECKED=" WS-CHECK-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECT-COUNT
           DISPLAY "REJECT ZERO=" WS-ZERO-COUNT
               " OVER_LIMIT=" WS-LIMIT-COUNT.
