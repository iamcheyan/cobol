      *非契約／意図的な誤レイアウトのデモ用copybook。
      *CUSTOMER v1のIFではない。CUSTOMER-NAMEを
      *X(11)と誤宣言し、レコード長は28Bになる。
      *LENGTH-PROBEで、誤ったPICひとつが後続の
      *オフセットをずらす様子を示すためだけに存在
      *copybooks/CUSTOMER-V1.CPY（27 B、最終Bのみ
      *CUSTOMER-STATUS）。版管理・ジョブ利用しない。
       01 CUSTOMER-RECORD.
          05 CUSTOMER-ID PIC X(8).
          05 CUSTOMER-NAME PIC X(11).
          05 BALANCE-DEMO PIC X(8).
          05 CUSTOMER-STATUS PIC X.
