       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * レベル番号で親子を決める。字下げは表示用。
      * 項目は宣言順に連続配置。区切りなし。
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
      * 外部固定長の受取領域。本レコードと同じ58B。
       01 WS-EXPORT-LINE PIC X(58).
       PROCEDURE DIVISION.
      * WS-STATUSは同名。参照時はOFで親を指定。
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
      * 金額項目の単独表示時のみ小数点が現れる。
      * グループ表示は格納バイト出力。小数点なし。
           DISPLAY "グループデータ=[" WS-TRANSACTION-RECORD "]"
      * 全体転送はバイト複写。数値変換なし。
      * 幅は受取項目のPICで決まる。両方58B。
           MOVE WS-TRANSACTION-RECORD TO WS-EXPORT-LINE
           DISPLAY "外部記録=[" WS-EXPORT-LINE "]"
           STOP RUN.
