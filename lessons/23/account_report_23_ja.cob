      * 2つ目のプログラムは、同じ口座レコード定義を
      * インポートします。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCOUNT-REPORT23.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "ACCOUNT-REC.CPY".
       01 WS-REPORT-BALANCE PIC 9(7).99 VALUE ZERO.
      * 共有COPYBOOKの項目を使い、独立した報告行を組
      * み立てます。
      * 口座番号と顧客IDを設定し、残高は金額フィー
      * ルドに格納します。
      * 表示用PICへ移して小数点を出力し、口座・顧客
      * ・残高を報告します。
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-LOAD-REPORT-ROW
           PERFORM 2000-DISPLAY-REPORT-ROW
           STOP RUN.
       1000-LOAD-REPORT-ROW.
           MOVE "A000000009" TO WS-ACCOUNT-NUMBER
           MOVE "C0001009" TO WS-CUSTOMER-ID
           MOVE 20.00 TO WS-ACCOUNT-BALANCE.
       2000-DISPLAY-REPORT-ROW.
           MOVE WS-ACCOUNT-BALANCE TO WS-REPORT-BALANCE
           DISPLAY "ACCOUNT-REPORT NUMBER=" WS-ACCOUNT-NUMBER
               " CUSTOMER=" WS-CUSTOMER-ID
               " BALANCE=" WS-REPORT-BALANCE.
