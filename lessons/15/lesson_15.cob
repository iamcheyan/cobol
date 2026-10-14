      *レッスン 15: 毎日の取引テキストを一度に 1 行ずつ読んでください。
      *LINE SEQUENTIAL は、各物理行に 1 つのテキスト レコードを保存します。
      *READ は、AT END 句が実行されるまで次のレコードを取得します。
      *FD 記録領域には短い行が埋め込まれます。
      *TRIM は、表示操作の場合にのみそのパディングを削除します。
      *このプログラムはレコードをテキストとして読み取り、フィールドを解析しません。
      *ここを実行すると、ASSIGN が入力フィクスチャを見つけます。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. READ15.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD TRANSACTION-FILE.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      *オープンの失敗は、読み取りが試行される前に報告されます。
       0000-MAIN.
           OPEN INPUT TRANSACTION-FILE
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "OPEN=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               PERFORM 1000-READ-ONE-RECORD
           END-PERFORM
           DISPLAY "EOF=YES RECORDS=" WS-RECORD-COUNT
           CLOSE TRANSACTION-FILE
           IF WS-FILE-STATUS = "00"
               DISPLAY "CLOSE=OK"
           ELSE
               DISPLAY "CLOSE=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      *READ は 1 つの物理行を取得するか、ファイルの終わりを通知します。
       1000-READ-ONE-RECORD.
           READ TRANSACTION-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   ADD 1 TO WS-RECORD-COUNT
                   DISPLAY "RECORD="
                       FUNCTION TRIM(FD-TRANSACTION-RECORD TRAILING)
           END-READ.
      *OPEN INPUT は、既存のファイルを読み取り用に準備します。
      *OPEN が成功すると、ファイルのステータス 00 が報告されます。
      *必要なファイルが見つからない場合、OPEN はゼロ以外のステータスを返します。
      *入力をオープンできない場合、プログラムはステータス 1 を返します。
      *FD には 1 つの行順テキストレコードが記述されます。
      *行順次レコードは各物理改行で終了します。
      *入力レコードは 100 文字の FD エリアよりも短いです。
      *GnuCOBOL は、短い行順次レコードにスペースを埋め込みます。
      *FUNCTION TRIM は、表示の右側のパディングのみを削除します。
      *保存されたファイル レコード自体は TRIM によって変更されません。
      *ランダム キーを使用しない READ は、次の連続レコードを取得します。
      *READ AT END は、次のレコードが利用できないことを示します。
      *EOF 分岐はフラグを設定しますが、カウントは増加しません。
      *ループは、最初の READ がファイルの終わりに達した後に終了します。
      *最後の改行によって余分な空のデータ レコードが作成されることはありません。
      *レコード カウンタは、読み取りが成功するたびに 1 回増加します。
      *プログラムは、各入力レコードの元のテキストを表示します。
      *このレッスンでは、パイプで区切られたフィールドは分割されません。
      *READ が成功した後のファイルのステータスは 00 です。
      *ファイル終了後のファイルステータスは、ファイルが閉じるまで 10 です。
      *CLOSE は成功するとステータス 00 を返します。
      *この SELECT は OPTIONAL ではないため、ファイルは存在する必要があります。
      *入力パスは現在のディレクトリからの相対パスです。
      *フィクスチャを使用するには、レッスン ディレクトリからプログラムを起動します。
      *このプログラムは書き込みを実行せず、入力データを変更しません。
      *次のレッスンでは、承認された出力レコードと拒否された出力レコードを書き込みます。
      *レッスン 18 では、区切り文字で区切られたフィールドを解析します。
      *このフィクスチャには、4 つの毎日の口座取引記録が含まれています。
      *行処理を示すために、レコードの長さが異なります。
      *各読み取りでは同じ FD レコード領域が使用されます。
      *READ AT END のみがこの入力ストリームを完了としてマークします。
      *ファイル読み取りエラーは、通常のファイルの終わりとは異なります。
      *I/O 障害を診断するときは、ファイルのステータスを調べる必要があります。
      *ファイルが空の場合でも、読み取りループの後にファイルを閉じます。
      *出力カウントは、利用可能なすべてのレコードがアクセスされたことを確認します。
      *空のファイルはレコード数がゼロの EOF を報告します。
      *このレッスンでは、テーブル検索や口座残高の更新は行われません。
      *STOP RUN はシーケンシャル入力デモを終了します。
      *フィクスチャはパイプ文字を使用して表示フィールドを区切ります。
      *このレッスンでは、各行全体が 1 つの文字レコードのままになります。
      *日付とトランザクション識別子はチェックなしで表示されます。
      *トランザクション コードと金額は COBOL フィールドに変換されません。
      *後のレッスンでは、区切り文字で区切られた列からフィールドを解析します。
      *行順ファイルでは、レコード間に改行区切り文字が使用されます。
      *テキスト エディタは、この入力フィクスチャを直接作成できます。
      *空の入力は、最初の READ 試行で AT END に達します。
      *読み取りが成功すると、カウントが 1 回だけインクリメントされます。
      *FD レコード幅は、最長の入力行を収容できる必要があります。
