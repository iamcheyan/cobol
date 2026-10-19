      *共通却下レコード。取引またはcustomer v2を格納。
      *取引は55B。customer v1は32B幅で格納。
      *末尾に区切り1文字と理由10文字を付ける。
       01 REJECT-RECORD.
          05 REJ-DATA             PIC X(55).
          05 REJ-SEP              PIC X(1).
          05 REJ-REASON           PIC X(10).
