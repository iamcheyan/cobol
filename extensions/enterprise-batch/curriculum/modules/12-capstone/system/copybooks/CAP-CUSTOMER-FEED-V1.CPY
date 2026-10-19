      * CAP-CUSTOMER-FEED
      * 顧客フィード（レイアウト版001）、31B、
      * ASCII、LF終端。
      *
      * 命名:こ31B形式はmodule 04/07正準形式である
      * 1778B・175項目ENTERPRISE-CUSTOMER v1とは異なり・
      * M11インシデント演習形式とも異なる。非互換
      * 3
      * 見えないため・capstone
      * - 正準CUSTOMER v1の27B（1-27）を内包。
      * 27B目はレコード状態A/D。
      * - 独自の区分とlayout_versionを追加。
      * 区分はstatusBではない。
      *
      * 1-8 customer_id：8桁、先頭のゼロを保持。
      * 9-18 customer_name：10文字、空白埋め。
      * 19-26 balance_demo：8桁、最小通貨単位。
      * 27 record_status：1文字、Aは有効、Dは休眠。
      * 28 classification：1文字、A/B/C/D（個人/法人/
      * 富裕層/公共部門）。
      * 29-31 layout_version："001"。
      * v2では区分を28-29B2字(A→A1～D→D1)に拡張し・
      * layout_versionを002に更新する（全体で32B）。
      *
       01 CAP-CUSTOMER-FEED-V1-RECORD.
          05 EC1-CUSTOMER-ID            PIC X(8).
          05 EC1-CUSTOMER-NAME          PIC X(10).
          05 EC1-BALANCE-DEMO           PIC X(8).
          05 EC1-RECORD-STATUS          PIC X(1).
          05 EC1-CUSTOMER-CLASSIFICATION PIC X(1).
          05 EC1-LAYOUT-VERSION         PIC X(3).
