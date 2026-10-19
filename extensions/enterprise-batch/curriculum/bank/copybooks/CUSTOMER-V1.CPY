      *> CUSTOMER v1：固定形式・27バイト・ASCII。
      *> 各レコードの後にLF。LFは27バイトに含めない。
      *> 1-8   customer_id    8桁・先頭ゼロ保持・一意。
      *> 9-18  customer_name  10文字・左詰め・空白埋め。
      *> 19-26 balance_demo   8桁・最小通貨単位・符号なし
      *> 27    status         1文字。A=有効、D=休眠
      *>
      *> byte 27はレコードSTATUS。顧客区分ではない。
      *> module 11/12の顧客区分は別項目であり、独立した
      *> 版管理されたenterpriseレイアウトに置く。
      *> このバイトには置かない。BANK-SYSTEM.md 2節と
      *> module 07 L4 ENTERPRISE-CUSTOMER-V1を参照。
      *> そのCUSTOMER-CLASSIFICATIONはv1がX(1)、v2がX(2)。
       01 CUSTOMER-RECORD.
          05 CUSTOMER-ID          PIC X(8).
          05 CUSTOMER-NAME        PIC X(10).
          05 CUSTOMER-BALANCE-DEMO PIC X(8).
          05 CUSTOMER-STATUS      PIC X(1).
