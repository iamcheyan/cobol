      *レッスン 11: 小さなバッチを OCCURS テーブルに保存します。
      *OCCURS は、固定数の繰り返しデータ エントリを作成します。
      *グループエントリは、その下位の基本項目をすべて繰り返します。
      *括弧内の数値添字は、1 つのテーブルオカレンスを選択します。
      *このレッスンでは、インデックスではなく、通常の数値添字を使用します。
      *テーブルバインドは 4 つです。ループはエントリ 1 ～ 4 を訪問します。
      *貸方ではサンプル残高が増加し、借方ではサンプル残高が減少します。
      *不明なコードが表示され、残高は変更されません。
      *テーブル データは、処理される前に MOVE でロードされます。
      *ここでは、ファイル、外部入力、または動的テーブルは使用されません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. OCCURS11.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *各 05 エントリは、コードと小数第 2 位の金額を繰り返します。
       01 WS-TRANSACTION-TABLE.
          05 WS-TRANSACTION-ENTRY OCCURS 4 TIMES.
             10 WS-TXN-CODE PIC X.
             10 WS-TXN-AMOUNT PIC 9(5)V99.
      *数値フィールドはテーブル参照の添字です。
       01 WS-SAMPLE-INDEX PIC 9(2) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-BALANCE PIC 9(7)V99 VALUE 1000.00.
       PROCEDURE DIVISION.
      *テーブルをロードし、そのテーブルに設定された範囲を処理して、レポートします。
       0000-MAIN.
           PERFORM 1000-LOAD-TABLE
           PERFORM 2000-PROCESS-TABLE
           PERFORM 9000-REPORT
           STOP RUN.
      *数字の添字を使用して 4 つの出現箇所をすべて初期化します。
       1000-LOAD-TABLE.
           MOVE "C" TO WS-TXN-CODE(1)
           MOVE 125.50 TO WS-TXN-AMOUNT(1)
           MOVE "D" TO WS-TXN-CODE(2)
           MOVE 40.10 TO WS-TXN-AMOUNT(2)
           MOVE "X" TO WS-TXN-CODE(3)
           MOVE 25.00 TO WS-TXN-AMOUNT(3)
           MOVE "C" TO WS-TXN-CODE(4)
           MOVE 20.00 TO WS-TXN-AMOUNT(4).
      *設定された最後のインデックスを通じて、設定されたエントリを処理します。
       2000-PROCESS-TABLE.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-PROCESS-ENTRY
           END-PERFORM.
      *現在のオカレンスからコードと金額を読み取ります。
       2100-PROCESS-ENTRY.
           DISPLAY "ENTRY=" WS-SAMPLE-INDEX
               " CODE=" WS-TXN-CODE(WS-SAMPLE-INDEX)
               " AMOUNT=" WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
           EVALUATE WS-TXN-CODE(WS-SAMPLE-INDEX)
               WHEN "C"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           + WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=CREDIT"
               WHEN "D"
                   COMPUTE WS-ACCOUNT-BALANCE =
                       WS-ACCOUNT-BALANCE
                           - WS-TXN-AMOUNT(WS-SAMPLE-INDEX)
                   DISPLAY "ACTION=DEBIT"
               WHEN OTHER
                   DISPLAY "ACTION=IGNORED_UNKNOWN_CODE"
           END-EVALUATE
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      *処理されたエントリとその結果のアカウント残高をレポートします。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT
           DISPLAY "FINAL-BALANCE=" WS-ACCOUNT-BALANCE.
      *WS-TRANSACTION-TABLE は、すべてのテーブル エントリの親グループです。
      *OCCURS 4 TIMES は、この固定テーブルに 4 つのオカレンスを割り当てます。
      *各オカレンスには、WS-TXN-CODE と WS-TXN-AMOUNT の両方が含まれます。
      *グループレベルの OCCURS は、その下位構造全体を繰り返します。
      *どちらの基本フィールドでも、エントリごとに同じ数値添え字が使用されます。
      *添字はデータ名の後ろの括弧内に記述します。
      *最初に出現したものには添え字 1 が付けられます。
      *4 番目と最後の出現には、添え字 4 が付けられます。
      *WS-LAST-SAMPLE は、宣言されたテーブルの上限を決して超えてはなりません。
      *ループは、各処理パスの前に終了条件をチェックします。
      *終了テストではより大きいを使用するため、インデックス 4 が処理されます。
      *インデックス 4 の後に、インデックス 5 が終了テストを満たします。
      *実行されたエントリ段落はループ本体に戻ります。
      *このループは、テーブル エントリごとに 1 回、処理されたカウントをインクリメントします。
      *数値添字は通常の数値データ項目です。
      *レッスン 12 では、INDEXED BY およびテーブル インデックス データ項目を紹介します。
      *このテーブルの容量は、使用するエントリが少なくても固定です。
      *このサンプルでは、​​ループの前に割り当てられたすべてのオカレンスを埋めます。
      *OCCURS は値をロードしたり、トランザクション ビジネス ルールをチェックしたりしません。
      *EVALUATE は、すでに学習したコード分類を明示的に保ちます。
      *不明なコード分岐により、実行残高は変更されません。
      *エントリは添え字で選択された順序で処理されます。
      *テーブルが宣言された場合、暗黙的な並べ替えや検索は行われません。
      *後のレッスンでは、アカウント識別子を使用してテーブルを検索します。
      *4 つのサンプル量は、125.50、40.10、25.00、および 20.00 です。
      *受け入れられたクレジットとデビットのシーケンスは残高 1105.40 で終了します。
      *無視された不明コードの量は残高に追加されません。
      *このプログラムの実行では、テーブルは WORKING-STORAGE に保存されます。
      *固定された OCCURS 境界により、ストレージ計画とテーブルのレビューが簡素化されます。
      *テーブルのバインドとループ範囲の一貫性を維持します。
      *宣言された出現範囲外の添え字は使用しないでください。
      *このプログラムは、グループ レコード全体ではなく、フィールドを表示します。
      *STOP RUN は、この固定テーブルのデモンストレーションを終了します。
