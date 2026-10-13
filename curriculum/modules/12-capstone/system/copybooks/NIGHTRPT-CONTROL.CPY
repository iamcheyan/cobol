      * NIGHTRPT JOB007 report record grammar (human report, 120 bytes).
      *   CUSTOMER-DAY REPORT business_date=<YYYYMMDD>
      *   layout=<v1|v2> customers=<n>
      *   CUST|<id>|<class>|ACCOUNTS=<n>|TOTAL=<signed>
      *   CONTROL|ACCOUNTS=<n>|ACCOUNT_TOTAL=<s>|CUSTOMER_TOTAL=<s>
      * ACCOUNT_TOTAL must equal CUSTOMER_TOTAL (conservation gate).
      * <class> is the enterprise classification (A1/B1/C1/D1), not
      * the canonical CUSTOMER v1 status byte.
       01 NIGHTRPT-REPORT-RECORD.
          05 NRP-TAG              PIC X(7).
          05 NRP-ACCOUNT-COUNT    PIC 9(9).
          05 NRP-ACCOUNT-TOTAL    PIC S9(15).
          05 NRP-CUSTOMER-TOTAL   PIC S9(15).
