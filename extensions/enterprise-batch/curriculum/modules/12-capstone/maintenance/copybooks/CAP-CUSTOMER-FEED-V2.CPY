      * CAP-CUSTOMER-FEED v2：保守課題の成果物。
      * 対象は顧客区分を1桁から2桁へ拡張する変更。
      * 32B、ASCII、LF終端。
      * 独立版管理enterprise顧客レイアウト。
      * CUSTOMER v1は27B。byte 27はrecord status。
      * CUSTOMER-CLASSIFICATIONはPIC X(1)からPIC X(2)へ拡張。
      * LAYOUT-VERSIONは001から002へ更新。
      * 1-8 customer_id：8桁、先頭ゼロを保持。
      * 9-18 customer_name：10文字、空白埋め。
      * 19-26 balance_demo：8桁、最小通貨単位。
      * 27 record_status：A=有効、D=休眠。
      * 28-29 classification：A1/B1/C1/D1。
      * 30-32 layout_version "002"。
      * v1を上書きせず・新しいファイルへ出力
       01 CAP-CUSTOMER-FEED-V2-RECORD.
          05 EC2-CUSTOMER-ID            PIC X(8).
          05 EC2-CUSTOMER-NAME          PIC X(10).
          05 EC2-BALANCE-DEMO           PIC X(8).
          05 EC2-RECORD-STATUS          PIC X(1).
          05 EC2-CUSTOMER-CLASSIFICATION PIC X(2).
          05 EC2-LAYOUT-VERSION         PIC X(3).
