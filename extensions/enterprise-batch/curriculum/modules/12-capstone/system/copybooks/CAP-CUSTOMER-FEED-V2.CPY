      * CAP-CUSTOMER-FEED v2：独立版管理企業顧客
      * レイアウト（版002）、32B、ASCII、LF終端。
      * v1から変更は区分を2文字に拡張点(A→A1・B→B1・
      * C→C1、D→D1）で、28-29Bに置く。
      * layout_versionは"002"。区分より前の項目位置は
      * 他は維持
      * レコード全体は32Bとなる。
      * 1-8 customer_id：8桁、先頭のゼロを保持。
      * 9-18 customer_name：10文字、空白埋め。
      * 19-26 balance_demo：8桁、最小通貨単位。
      * 27 record_status：1文字、Aは有効、Dは休眠。
      * 28-29 classification：2文字、A1/B1/C1/D1の下位区分。
      * 30-32 layout_version："002"。
      * 27BのCUSTOMER v1（27B目はstatus）は変更せず
      * 1-27Bに内包。区分は別項目である。
       01 CAP-CUSTOMER-FEED-V2-RECORD.
          05 EC2-CUSTOMER-ID            PIC X(8).
          05 EC2-CUSTOMER-NAME          PIC X(10).
          05 EC2-BALANCE-DEMO           PIC X(8).
          05 EC2-RECORD-STATUS          PIC X(1).
          05 EC2-CUSTOMER-CLASSIFICATION PIC X(2).
          05 EC2-LAYOUT-VERSION         PIC X(3).
