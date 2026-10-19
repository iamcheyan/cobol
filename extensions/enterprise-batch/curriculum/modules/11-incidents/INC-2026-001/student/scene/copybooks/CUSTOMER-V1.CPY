      *CUSTOMER v1：固定形式、27B、layout 001。
      *1-8 customer_id：8桁、先頭ゼロを保持、一意。
      *9-18 customer_name：10文字、左詰め、空白埋め。
      *19-26 balance_demo：8桁、符号なしサンプル金額。
      *27 status：A=有効、D=休眠。それ以外は却下。
      *byte 27はレコードstatus。顧客区分には使わない。
      *module 11.5は独立したenterprise区分を拡張。
      *対象：maintenance/copybooks/ENTERPRISE-CLASS-V1.CPY。
      *区分をstatus byteへ移さない。BANK-SYSTEM.md参照。
      *
      *
       01 CUSTOMER-RECORD.
          05 CUSTOMER-ID PIC X(8).
          05 CUSTOMER-NAME PIC X(10).
          05 CUSTOMER-BALANCE-DEMO PIC X(8).
          05 CUSTOMER-STATUS PIC X(1).
