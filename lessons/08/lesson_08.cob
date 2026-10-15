      * レッスン 08: 小規模な固定データ アカウントのトランザクション バッチを実行します。
      * このレッスンでは、フィールド、数学、IF、EVALUATE、および PERFORM を組み合わせます。
      * 名前付き段落は、セットアップ、処理、レポートを分離します。
      * 5 つの固定トランザクションは、承認されたパスと拒否されたパスを実行します。
      * ここでは、ファイル、データベース、テーブル、または端末入力は使用されません。
      * D は残高を入金します。資金が十分にある場合は、W から借方に記入されます。
      * 他のトランザクション コードはレビューのために拒否されます。
      * この例では、すべての金額に 2 つの小数点以下の位置が使用されます。
      * これは学習バッチであり、生産台帳システムではありません。
      * その入力と出力は実行全体にわたって決定的なままです。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCH08.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * サンプルバッチを処理する前の初期アカウント残高。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-CURRENT-BALANCE PIC 9(7)V99 VALUE ZERO.
      * サンプル インデックスと最後のインデックスは、インライン PERFORM ループを制御します。
       01 WS-SAMPLE-INDEX PIC 9(3) VALUE ZERO.
       01 WS-LAST-SAMPLE PIC 9 VALUE 5.
      * 現在のサンプル コードと量は各パスでロードされます。
       01 WS-TRANSACTION-CODE PIC X VALUE SPACE.
       01 WS-TRANSACTION-AMOUNT PIC S9(5)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE ZERO.
      * カウンタは、処理されたレコード、受け入れられたレコード、および拒否されたレコードを区別します。
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCEPTED-COUNT PIC 9(3) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * Main は 3 つのバッチ ステージを依存関係の順序で呼び出します。
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-BATCH
           PERFORM 9000-REPORT
           STOP RUN.
      * 処理前に共有残高とカウンターを初期化します。
       1000-INITIALIZE.
           MOVE WS-OPENING-BALANCE TO WS-CURRENT-BALANCE
           MOVE ZERO TO WS-PROCESSED-COUNT
           MOVE ZERO TO WS-ACCEPTED-COUNT
           MOVE ZERO TO WS-REJECTED-COUNT
           DISPLAY "バッチ=START"
           DISPLAY "期首残高=" WS-OPENING-BALANCE.
      * 各固定レコードをサンプル番号を使用して順番に処理します。
       2000-PROCESS-BATCH.
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               PERFORM 2100-LOAD-SAMPLE
               PERFORM 2200-CLASSIFY-AND-POST
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM.
      * 各サンプル番号に関連付けられたコードと量をロードします。
       2100-LOAD-SAMPLE.
           EVALUATE WS-SAMPLE-INDEX
               WHEN 1
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE 125.50 TO WS-TRANSACTION-AMOUNT
               WHEN 2
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 40.10 TO WS-TRANSACTION-AMOUNT
               WHEN 3
                   MOVE "W" TO WS-TRANSACTION-CODE
                   MOVE 1500.00 TO WS-TRANSACTION-AMOUNT
               WHEN 4
                   MOVE "D" TO WS-TRANSACTION-CODE
                   MOVE -5.00 TO WS-TRANSACTION-AMOUNT
               WHEN 5
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE 25.00 TO WS-TRANSACTION-AMOUNT
               WHEN OTHER
                   MOVE "X" TO WS-TRANSACTION-CODE
                   MOVE ZERO TO WS-TRANSACTION-AMOUNT
           END-EVALUATE
           DISPLAY "レコード=" WS-SAMPLE-INDEX
               " 符号=" WS-TRANSACTION-CODE
               " 金額=" WS-TRANSACTION-AMOUNT.
      * 現在の記録を分類し、承認された金額のみを適用します。
       2200-CLASSIFY-AND-POST.
           EVALUATE WS-TRANSACTION-CODE
               WHEN "D"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       COMPUTE WS-CURRENT-BALANCE =
                           WS-CURRENT-BALANCE
                               + WS-TRANSACTION-AMOUNT
                       COMPUTE WS-ACCEPTED-COUNT =
                           WS-ACCEPTED-COUNT + 1
                       DISPLAY "結果=ACCEPTED 理由=DEPOSIT"
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "結果=REJECTED"
                           " 理由=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN "W"
                   IF WS-TRANSACTION-AMOUNT > ZERO
                       IF WS-TRANSACTION-AMOUNT
                           <= WS-CURRENT-BALANCE
                           COMPUTE WS-CURRENT-BALANCE =
                               WS-CURRENT-BALANCE
                                   - WS-TRANSACTION-AMOUNT
                           COMPUTE WS-ACCEPTED-COUNT =
                               WS-ACCEPTED-COUNT + 1
                           DISPLAY "結果=ACCEPTED"
                               " 理由=WITHDRAWAL"
                       ELSE
                           COMPUTE WS-REJECTED-COUNT =
                               WS-REJECTED-COUNT + 1
                           DISPLAY "結果=REJECTED"
                               " 理由=INSUFFICIENT_FUNDS"
                       END-IF
                   ELSE
                       COMPUTE WS-REJECTED-COUNT =
                           WS-REJECTED-COUNT + 1
                       DISPLAY "結果=REJECTED"
                           " 理由=AMOUNT_NOT_POSITIVE"
                   END-IF
               WHEN OTHER
                   COMPUTE WS-REJECTED-COUNT =
                       WS-REJECTED-COUNT + 1
                   DISPLAY "結果=REJECTED"
                       " 理由=UNKNOWN_TRANSACTION_CODE"
           END-EVALUATE.
      * 完全なサンプルバッチ後の合計と残高を報告します。
       9000-REPORT.
           DISPLAY "処理件数=" WS-PROCESSED-COUNT
           DISPLAY "承認件数=" WS-ACCEPTED-COUNT
           DISPLAY "拒否件数=" WS-REJECTED-COUNT
           DISPLAY "最終残高=" WS-CURRENT-BALANCE.
      * メイン段落は、プログラムの唯一のエントリ シーケンスです。
      * 各 PERFORM は、段落呼び出しの後にステートメントに戻ります。
      * プロセス段落では、レコードの反復に PERFORM VARYING を使用します。
      * ロード段落は、固定データをビジネス ルールから分離します。
      * EVALUATE は、サンプル インデックスをその固定コードと量にマッピングします。
      * 2 番目の EVALUATE では、入金、出金、または不明なロジックを選択します。
      * IF は、転記前にプラスの金額と利用可能な資金をチェックします。
      * 拒否されたレコードの数は増加し、残高は変更されません。
      * 受け入れられたレコードは残高と受け入れられた数を一緒に変更します。
      * 処理された数は、レコードが完了するたびに 1 回増加します。
      * 5 つのレコードから、2 つの承認結果と 3 つの拒否結果が生成されます。
      * クレジットにより残高が 1000.00 から 1125.50 に増加します。
      * 有効な引き出しにより、残高は 1085.40 まで下がります。
      * 過剰な出金は残高を変更せずに拒否されます。
      * マイナスのデポジットは、残高が変更される前に拒否されます。
      * 不明なコードは金額を通知せずに拒否されます。
      * カウンタは会計エントリではなく、記録の結果を報告します。
      * 初期化は、すべてのトランザクション処理ステップの前に行われます。
      * レポートは、処理が返された後に共有合計を読み取ります。
      * 各段落の最後の文はピリオドで終わります。
      * EVALUATE は、テーブル レッスンまでサンプルを埋め込みます。
      * 後のレッスンでは、サンプルを再利用可能なデータ構造に保存します。
      * 実稼働バッチには、ファイル ステータスと再起動処理も必要です。
      * 同時実行性と冪等性の運用ルールを定義します。
      * STOP RUN は、この統合された言語の基本の例を終了します。
