      *ENTERPRISE-CLASS v2 -- 11.5課題の目標形。
      *layout 002、24B。CUSTOMER-CLASSIFICATIONを
      *2文字へ拡張（A->A1, B->B1, C->C1, D->D1）し、
      *LAYOUT-VERSIONは'002'。v1はmigrate-customer.pyで移行。
      *v1ファイルは上書きせず、v2は幅で拒否。
      *
      *名称/関係: module 07 L4の標準形式
      *ENTERPRISE-CUSTOMER-V1（1778B、175項目）と別。
      *ENTERPRISE-CLASS-V1.CPYを参照。
      *標準CUSTOMER v1は27B。byte 27=status。
      *（byte 27=status）はv2でも変更しない。
      *
      *1-3 layout_version 3文字、固定値 '002'
      *4-11 customer_id 8桁、先頭ゼロを保持
      *12 record_status 1文字: A=有効、I=無効
      *13-22 customer_name 10文字、左詰め、空白埋め
      *23-24 customer_classification 2文字: A1/B1/C1/D1
      *
       01 ENTERPRISE-CLASS-V2.
          05 LAYOUT-VERSION PIC X(3).
          05 CUSTOMER-ID PIC X(8).
          05 RECORD-STATUS PIC X(1).
          05 CUSTOMER-NAME PIC X(10).
          05 CUSTOMER-CLASSIFICATION PIC X(2).
