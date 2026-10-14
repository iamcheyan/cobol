      * レッスン 13: OCCURS テーブルでアカウント キーを見つけます。
      * SEARCH は、設定されたインデックスからテーブル エントリを順番にチェックします。
      * SEARCH ALL は二分検索を使用し、ソートされた一意のキーが必要です。
      * 以下のアカウント キーはテキストの昇順で保存されます。
      * どちらのステートメントでも、参照に INDEXED BY テーブル インデックスを使用します。
      * 検索対象はテーブルに存在する場合もあれば、存在しない場合もあります。
      * AT END は、一致するアカウントに到達しない検索を処理します。
      * テーブルの順序とその ASCENDING KEY 句は一致する必要があります。
      * SEARCH ALL は、データを並べ替えたり、実際のキーの順序を確認したりしません。
      * このサンプルでは、​​4 つの固定アカウント エントリを使用し、ファイル入力は使用しません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SEARCH13.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * key 句は、SEARCH ALL に必要な順序を記述します。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             ASCENDING KEY IS WS-ACCOUNT-NUMBER
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
       01 WS-SEARCH-KEY PIC X(10) VALUE SPACES.
       PROCEDURE DIVISION.
      * 両方の方法で 1 つの存在キーと 1 つの欠落キーを検索します。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           MOVE "0002468101" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           MOVE "0005550000" TO WS-SEARCH-KEY
           PERFORM 2000-SEQUENTIAL-SEARCH
           PERFORM 3000-BINARY-SEARCH
           STOP RUN.
      * 4 つの一意のアカウント キーを昇順でロードします。
       1000-LOAD-ACCOUNTS.
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(1)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(2)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(3)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(4)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(4).
      * SEARCH は、インデックス 1 から順に各エントリをチェックします。
       2000-SEQUENTIAL-SEARCH.
           DISPLAY "SEARCH=SEQUENTIAL KEY=" WS-SEARCH-KEY
           SET WS-ACCOUNT-IDX TO 1
           SEARCH WS-ACCOUNT-ENTRY
               AT END
                   DISPLAY "SEQUENTIAL=NOT_FOUND"
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   DISPLAY "SEQUENTIAL=FOUND ACCOUNT="
                       WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                       " BALANCE="
                       WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           END-SEARCH.
      * SEARCH ALL は、宣言されたキー順序に対して二分検索を実行します。
       3000-BINARY-SEARCH.
           DISPLAY "SEARCH=BINARY KEY=" WS-SEARCH-KEY
           SEARCH ALL WS-ACCOUNT-ENTRY
               AT END
                   DISPLAY "BINARY=NOT_FOUND"
               WHEN WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                   = WS-SEARCH-KEY
                   DISPLAY "BINARY=FOUND ACCOUNT="
                       WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
                       " BALANCE="
                       WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           END-SEARCH.
      * SEARCH は現在の検索インデックスから開始されるため、最初に 1 に設定します。
      * 失敗した場合、SEARCH はすべてのテーブル エントリのインデックスを進めます。
      * SEARCH ALL は二分探索を実行しながら位置を選択します。
      * WHEN条件は同じテーブルキーと検索対象を使用します。
      * FOUND 出力は、一致するオカレンスから残高を読み取ります。
      * AT END は、すべての連続エントリが一致しなかった後に実行されます。
      * SEARCH ALL は、キーがテーブルに存在しない場合に AT END を使用します。
      * SEARCH ALL では、OCCURS 定義に INDEXED BY が必要です。
      * ASCENDING KEY は、予想される順序を示しますが、それを作成しません。
      * 1000-LOAD-ACCOUNTS にロードされる値は実際には昇順です。
      * この SEARCH ALL テーブルに必要なため、アカウント キーは一意です。
      * 固定幅のテキスト キーは、比較中に先頭のゼロを保持します。
      * ターゲット 0002468101 は 3 番目のアカウント エントリと一致します。
      * ターゲット 0005550000 は保存されたキーの間にありますが、存在しません。
      * どちらの検索フォームでも、有効なデータについて同じ一致または不一致が報告されます。
      * シーケンシャルフォームでは、エントリを 1 つずつ検査できます。
      * バイナリ形式は、残りの順序付き範囲を繰り返し狭めます。
      * 実際のキーの順序が間違っているテーブルでは決して SEARCH ALL を使用しないでください。
      * コンパイラは、実行時の値の順序ではなく、キー句をチェックします。
      * テーブルの順序が間違っていると、SEARCH ALL が間違っている可能性があります。
      * 重複キーもこの検索規約に違反します。
      * キーまたは順序を変更する場合は、すべてのエントリを確認してください。
      * このプログラムは、テーブルを検索する前にソートしません。
      * レッスン 14 では、テーブル検索とアカウント トランザクションを組み合わせます。
      * テーブルには WORKING-STORAGE に 4 つのアカウントが保持されます。
      * インデックスはテーブルの INDEXED BY 句によって提供されます。
      * どちらの検索でも同じテーブル インデックス名が使用されます。
      * インデックスに対して演算は実行されません。
      * テーブルは、いずれかの検索が開始される前にすでにロードされています。
      * 検索キーとアカウント キーの幅は同じ X(10) です。
      * 検索ミスは通常の結果であり、実行時エラーではありません。
      * 出力では、各検索の検索方法とキーが特定されます。
      * STOP RUN は、この固定テーブル検索のデモンストレーションを終了します。
