      *NIGHTRPT JOB007の人間向けレポート、120B。
      *CUSTOMER-DAY REPORT business_date=<YYYYMMDD>
      *layout=<v1|v2> customers=<n>
      *CUST|<id>|<class>|ACCOUNTS=<n>|TOTAL=<signed>
      *CONTROL|ACCOUNTS=<n>|ACCOUNT_TOTAL=<s>|CUSTOMER_TOTAL=<s>
      *ACCOUNT_TOTALとCUSTOMER_TOTALの一致を収支確認。
      *<class>はenterprise区分A1/B1/C1/D1。
      *標準CUSTOMER v1のstatus byteではない。
       01 NIGHTRPT-REPORT-RECORD.
          05 NRP-TAG              PIC X(7).
          05 NRP-ACCOUNT-COUNT    PIC 9(9).
          05 NRP-ACCOUNT-TOTAL    PIC S9(15).
          05 NRP-CUSTOMER-TOTAL   PIC S9(15).
