      * 合法取引コード D/W/T 由接口契约定义；本课把它当作输入前提，不在程序内校验取值。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
       PROCEDURE DIVISION.
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE.
           DISPLAY "取引コード=" WS-TRANSACTION-CODE.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   DISPLAY "分類=DEPOSIT"
                   DISPLAY "処理=ADD_TO_ACCOUNT"
               WHEN "W"
                   DISPLAY "分類=WITHDRAWAL"
                   DISPLAY "処理=SUBTRACT_FROM_ACCOUNT"
               WHEN "T"
                   DISPLAY "分類=TRANSFER"
                   DISPLAY "処理=PROCESS_BOTH_ACCOUNTS"
      * 契约外取值统一归入待人工核对；本课只输出分类标签，不做任何过账。
               WHEN OTHER
                   DISPLAY "分類=UNKNOWN"
                   DISPLAY "処理=REJECT_FOR_REVIEW"
           END-EVALUATE
           STOP RUN.
