      * CUSTOMER v1：正準の固定IF、27B、ASCII。
      * 各レコード後にLFが続く。LFは27B幅に含めない。
      * 1-8 customer_id：8桁、先頭のゼロを保持。
      * 9-18 customer_name：10文字、左詰め、空白埋め。
      * 19-26 balance_demo:8桁・最小通貨単位・符号なし例
      * 27 status:1字。Aは有効・Dは休眠。それ以外は却下
      *
      * 27B目はレコードSTATUSであり・顧客区分ではない
      * module 11/12保守演習で扱う顧客区分は別項目で・
      * 独立版管理CAP-CUSTOMER-FEED形式に置く。詳細は
      * CAP-CUSTOMER-FEED-V1.CPY / CUSTOMER-DAY-V1.CPYおよび
      * docs/curriculum/BANK-SYSTEM.md section 2を参照。
      *
       01 CUSTOMER-V1-RECORD.
          05 CV1-CUSTOMER-ID    PIC X(8).
          05 CV1-CUSTOMER-NAME  PIC X(10).
          05 CV1-BALANCE-DEMO   PIC X(8).
          05 CV1-CUSTOMER-STATUS PIC X(1).
