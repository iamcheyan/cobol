      * 口座27バイト（10+8+9）。第17・20・22課と同幅。
      * 利用側：lesson.cob、account_report_23.cob。
      * 幅変更時は全利用側を再ビルドし、照合する。
       01 WS-ACCOUNT-RECORD.
          05 WS-ACCOUNT-NUMBER PIC X(10).
          05 WS-CUSTOMER-ID PIC X(8).
          05 WS-ACCOUNT-BALANCE PIC 9(7)V99.
