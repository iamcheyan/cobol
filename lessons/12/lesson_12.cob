      *レッスン 12: INDEXED BY 項目を使用して OCCURS テーブルを走査します。
      *テーブルのインデックスは、テーブルの OCCURS 句で宣言されます。
      *SET は、テーブル参照で使用されるインデックスを割り当てて増分します。
      *添字とは異なり、インデックスには数値 PIC ではなく USAGE INDEX が含まれます。
      *プログラムは、ロードされたアカウント テーブルを出現順に表示します。
      *インデックス付き走査が開始される前に、4 つのエントリすべてがロードされます。
      *SEARCH、インデックスの算術演算、または外部入力は使用されません。
      *最終エントリ数は、トラバースがいつ終了するかを制御します。
      *この例では、テーブルと走査範囲の同期を維持します。
      *インデックス値は数値フィールドのように表示されません。
      *リテラル添字は、テーブル内の既知の位置を初期化します。
      *各リテラルは、その番号によって 1 つの出現を書き込みます。
      *テーブル エントリは 2 つの基本項目のグループです。
      *インデックスの名前は、WORKING-STORAGE ではなく OCCURS に付けられます。
      *1 つのインデックスは、現在のオカレンスの各子を選択します。
      *SET は開始テーブルのオカレンスを明示的に割り当てます。
      *SET UP BY は、インデックスをテーブル エントリ 1 つ進めます。
      *数値カウントはインデックスと比較できます。
      *このループは、アカウントを表示する前にその状態をチェックします。
      *最後の増分では、別のテーブル エントリは表示されません。
      *インデックス付き参照には追加の添え字は必要ありません。
      *フィールド名は、どちらのセレクターでも意味を保持します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INDEX12.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *各口座エントリには、そのキーと現在のサンプル残高が含まれています。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
      *INDEXED BY ではインデックスは暗黙的です。 PIC 宣言はありません。
       01 WS-LAST-ACCOUNT PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      *インデックスがテーブルを走査する前に、すべてのテーブルオカレンスをロードします。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           PERFORM 2000-DISPLAY-ACCOUNTS
           PERFORM 9000-REPORT
           STOP RUN.
      *各アカウントに通常の数値の下付き文字を入力します。
       1000-LOAD-ACCOUNTS.
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(1)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(2)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(3)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(4)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(4).
      *テーブルのインデックスを設定し、出現するたびにアクセスして、それを増加させます。
       2000-DISPLAY-ACCOUNTS.
           SET WS-ACCOUNT-IDX TO 1
           PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT
               PERFORM 2100-DISPLAY-ONE-ACCOUNT
               SET WS-ACCOUNT-IDX UP BY 1
           END-PERFORM.
      *アカウントエントリの両方のフィールドで現在のインデックスを使用します。
       2100-DISPLAY-ONE-ACCOUNT.
           DISPLAY "ACCOUNT="
               WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
               " BALANCE="
               WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      *インデックス付きループが訪問したロードされたエントリの数を報告します。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT.
      *INDEXED BY は、この OCCURS テーブルに関連付けられたインデックスを宣言します。
      *WS-ACCOUNT-IDX は、PIC 数値作業記憶フィールドではありません。
      *SET WS-ACCOUNT-IDX TO 1 は、最初の出現を選択します。
      *SET UP BY 1 は、テーブル内の次の出現箇所に進みます。
      *どちらのセレクターもテーブル参照で括弧を使用します。
      *データ項目の宣言は、どのセレクターが使用されているかを示します。
      *レッスン 11 では、代わりに WS-SAMPLE-INDEX PIC 9(2) を添え字として使用しました。
      *数値添字には、テーブルオカレンスの名前を付ける番号が格納されます。
      *インデックスは、SET で値が設定される別個のセレクターです。
      *インデックスは数値計算用の PIC フィールドではありません。
      *テーブル エントリ間でインデックスを移動するには、SET UP または SET DOWN を使用します。
      *テーブルには宣言された最大出現数が 4 つあります。
      *WS-LAST-ACCOUNT は数値カウントであり、インデックス自体ではありません。
      *インデックスは、入力されたアカウント数と比較されます。
      *インデックス 4 の後の次のインデックスは最後のエントリの後にあります。
      *その後、別のテーブル参照を試行する前にループが終了します。
      *口座番号はテキスト キーの先頭のゼロを保持します。
      *ゼロ残高は依然として設定されたエントリに属します。
      *処理された数は、訪問されたオカレンスごとに 1 回増加します。
      *インデックス自体は処理数として使用されません。
      *1 つのグループ オカレンスのすべてのインデックス付きフィールドは、同じインデックスを使用します。
      *出現するたびに、数値フィールドと残高フィールドの両方が繰り返されます。
      *このプログラムではテーブル値の検索や並べ替えは行われません。
      *レッスン 13 では、テーブル検索を使用してキーとレコードを関連付けます。
      *ここでの順序は、宣言された出現順序 (1 から 4) です。
      *ロードされたエントリ数を、宣言された OCCURS 境界内に維持してください。
      *アンロードされたエントリは、有効なアカウント レコードとして扱われてはなりません。
      *これはメモリ内トラバーサルであり、ファイル読み取り操作ではありません。
      *GnuCOBOL は、この固定形式ソースのテーブル インデックスをサポートします。
      *STOP RUN は、このインデックス付きテーブルのデモを終了します。
