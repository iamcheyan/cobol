      * レッスン24：別途コンパイルした金額検証プログラムをCALLします。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON24.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 金額の数値ストレージでは、セントを暗黙的に表します。
       01 WS-AMOUNT PIC 9(7)V99 VALUE ZERO.
      * 呼び出されたプログラムは、判定結果をこの呼び出し元のフィールドに書き込みます。
       01 WS-CHECK-RESULT PIC X(15) VALUE SPACES.
      * この編集フィールドはDISPLAY時にだけ小数点を加えます。
       01 WS-EDITED-AMOUNT PIC 9(7).99 VALUE ZERO.
      * カウンターはこのプログラムに属し、呼び出しの間も保持されます。
       01 WS-CHECK-COUNT PIC 9(3) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ZERO-COUNT PIC 9(3) VALUE ZERO.
       01 WS-LIMIT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * 呼び出した各プログラムが戻った後に限り、メイン処理を終了します。
       0000-MAIN.
           DISPLAY "CALLER=START"
           PERFORM 1000-RUN-CHECK-CASES
           DISPLAY "CALLER=RESUMED"
           PERFORM 3000-DISPLAY-SUMMARY
           STOP RUN.
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
      * この通常の金額は許容範囲内です。
       1100-CHECK-ORDINARY-AMOUNT.
           MOVE 125.50 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * ゼロは業務ルールの範囲外です。
       1200-CHECK-ZERO-AMOUNT.
           MOVE ZERO TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 設定した最大値は許容範囲に含まれます。
       1300-CHECK-LIMIT-AMOUNT.
           MOVE 1000.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 設定した最大値を1セント超える金額は拒否されます。
       1400-CHECK-OVER-LIMIT-AMOUNT.
           MOVE 1000.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 最小の正の金額は受け入れ可能です。
       1500-CHECK-SMALL-POSITIVE.
           MOVE 0.01 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * この値は設定した最大値をわずかに下回ります。
       1600-CHECK-BELOW-LIMIT.
           MOVE 999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * PICの容量と業務上の検証上限は異なります。
       1700-CHECK-LARGEST-AMOUNT.
           MOVE 9999999.99 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * 中間値の金額で、両方の境界から離れた場合のルールを確認します。
       1800-CHECK-MIDRANGE-AMOUNT.
           MOVE 500.00 TO WS-AMOUNT
           PERFORM 2000-CALL-AMOUNT-CHECK.
      * CALLは指定したプログラム単位に制御を渡します。
      * このリテラルは、呼び出し先のPROGRAM-ID CHECK-AMOUNTと一致します。
      * USINGでは、最初に金額、次に結果の格納領域を渡します。
      * デフォルトのBY REFERENCEにより、呼び出し先はWS-CHECK-RESULTを更新できます。
      * 呼び出し元は各テスト金額に同じストレージを再利用します。
       2000-CALL-AMOUNT-CHECK.
           MOVE SPACES TO WS-CHECK-RESULT
           MOVE WS-AMOUNT TO WS-EDITED-AMOUNT
           DISPLAY "CALL=BEGIN AMOUNT=" WS-EDITED-AMOUNT
           CALL "CHECK-AMOUNT" USING WS-AMOUNT WS-CHECK-RESULT
           DISPLAY "CALL=RETURN STATUS="
               FUNCTION TRIM(WS-CHECK-RESULT TRAILING)
           PERFORM 2100-COUNT-CHECK-RESULT.
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
      * 8回の呼び出しがすべて戻った後、呼び出し元が合計を表示します。
       3000-DISPLAY-SUMMARY.
           DISPLAY "SUMMARY CHECKED=" WS-CHECK-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECT-COUNT
           DISPLAY "REJECT ZERO=" WS-ZERO-COUNT
               " OVER_LIMIT=" WS-LIMIT-COUNT.
