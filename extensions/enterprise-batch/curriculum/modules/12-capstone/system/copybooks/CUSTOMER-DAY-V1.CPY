      * CUSTOMER-DAY v1：JOB007出力、30B、LF終端。
      * 営業日ごとに顧客1件につき1行。
      * 1-8 customer_id：8桁。
      * 9-10 classification：A1/B1/C1/D1。v1のA/B/C/DはA1..。
      * 11-16 account_count：6桁。
      * 17 total_sign：+または-。
      * 18-30 total_balance：13桁、最小通貨単位。
      * 区分はCAP-CUSTOMER-FEEDから取得。
      * CUSTOMER v1のstatus byte 27は区分に使わない。
      *
       01 CUSTOMER-DAY-V1-RECORD.
          05 CD1-CUSTOMER-ID     PIC X(8).
          05 CD1-CLASSIFICATION  PIC X(2).
          05 CD1-ACCOUNT-COUNT   PIC X(6).
          05 CD1-TOTAL-SIGN      PIC X(1).
          05 CD1-TOTAL-BALANCE   PIC X(13).
