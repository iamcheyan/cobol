      * Report caller-owned account values and transaction totals.
      * 中文：报告调用方持有的账户值和交易汇总。
      * 日本語：呼び出し側が所有する口座値と取引集計を報告する。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REPORT-ACCOUNT28.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EDITED-BALANCE PIC 9(7).99 VALUE ZERO.
       LINKAGE SECTION.
       COPY "ACCOUNT-REC.CPY".
       COPY "BATCH-COUNTS.CPY".
       PROCEDURE DIVISION USING BY REFERENCE
           WS-ACCOUNT-RECORD WS-BATCH-COUNTS.
       0000-REPORT-ACCOUNT.
           MOVE WS-ACCOUNT-BALANCE TO WS-EDITED-BALANCE
           DISPLAY "ACCOUNT=" WS-ACCOUNT-NUMBER
               " CUSTOMER=" WS-CUSTOMER-ID
               " BALANCE=" WS-EDITED-BALANCE
           DISPLAY "SUMMARY POSTED=" WS-POSTED-COUNT
               " REJECTED=" WS-REJECTED-COUNT
           GOBACK.
