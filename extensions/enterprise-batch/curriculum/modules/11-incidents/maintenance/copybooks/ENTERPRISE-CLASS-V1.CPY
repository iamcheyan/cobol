      *ENTERPRISE-CLASS v1 -- 版管理顧客区分演習。
      *module 11.5で使用（layout 001、23B、ASCII）。
      *レコード末尾にLFを付加。幅には含めない。
      *
      *名称/関係: 標準enterprise形式はmodule 07 L4の
      *ENTERPRISE-CUSTOMER-V1（175項目、固定1778B）。
      *CUSTOMER-CLASSIFICATIONはv1でX(1)、v2でX(2)。
      *混同を避けるため別名ENTERPRISE-CLASSを使い、
      *項目を絞った投影と明記。
      *区分の意味（A/B/C/D ->
      *A1/B1/C1/D1）は維持し、演習に必要な項目だけを
      * 保持。
      *
      *これは27Bの標準CUSTOMER v1とも別形式。
      *同形式のbyte 27はレコードSTATUS（A/D）であり、
      *顧客区分ではない。
      *
      *1-3 layout_version 3文字、固定値'001'
      *4-11 customer_id 8桁、先頭ゼロを保持
      *12 record_status 1文字: A=有効、I=無効
      *13-22 customer_name 10文字、左詰め、空白埋め
      *23 customer_classification 1文字: A/B/C/D
      *
      *
       01 ENTERPRISE-CLASS-V1.
          05 LAYOUT-VERSION PIC X(3).
          05 CUSTOMER-ID PIC X(8).
          05 RECORD-STATUS PIC X(1).
          05 CUSTOMER-NAME PIC X(10).
          05 CUSTOMER-CLASSIFICATION PIC X(1).
