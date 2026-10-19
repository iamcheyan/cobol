      *TRANSACTION v1：固定形式、55B、ASCII、LF終端。
      *1-10 account_id：10桁、照合キー。
      *11-26 transaction_id：16文字、冪等性キーの一部。
      *27-34 business_date：8桁、実行営業日と一致。
      *35-40 sequence_no：6桁、口座ごとの処理順。
      *41 direction：C=貸方、D=借方。
      *42-54 amount：13桁、最小通貨単位、非負。
      *55 status：N=新規。他の値は運用規則による。
       01 TRANSACTION-V1-RECORD.
          05 TX1-ACCOUNT-ID      PIC X(10).
          05 TX1-TRANSACTION-ID  PIC X(16).
          05 TX1-BUSINESS-DATE   PIC X(8).
          05 TX1-SEQUENCE-NO     PIC X(6).
          05 TX1-DIRECTION       PIC X(1).
          05 TX1-AMOUNT          PIC X(13).
          05 TX1-STATUS          PIC X(1).
