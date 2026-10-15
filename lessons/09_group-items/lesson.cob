       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 层级号决定父子关系，缩进只为便于阅读。
      * 组项按声明顺序连续占字节，内部无分隔符。
       01 WS-TRANSACTION-RECORD.
          05 WS-CUSTOMER-INFO.
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
             10 WS-STATUS PIC X VALUE "A".
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
      * 外部定长记录的接收区，与本记录同为 58 字节。
       01 WS-EXPORT-LINE PIC X(58).
       PROCEDURE DIVISION.
      * 两个 WS-STATUS 同名，引用时必须用 OF 指定父组。
           DISPLAY "顧客ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "顧客名="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "口座番号="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
           DISPLAY "口座状態=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "取引ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "取引コード=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "取引金額="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "取引状態=" WS-STATUS OF WS-TXN-INFO
      * 金额字段单独显示时才出现小数点。
      * 组显示只输出存储字节，不插入小数点。
           DISPLAY "グループデータ=[" WS-TRANSACTION-RECORD "]"
      * 整组搬运是字节复制，不做数值换算。
      * 宽度由接收项的 PIC 决定；两项同为 58 字节。
           MOVE WS-TRANSACTION-RECORD TO WS-EXPORT-LINE
           DISPLAY "外部記録=[" WS-EXPORT-LINE "]"
           STOP RUN.
