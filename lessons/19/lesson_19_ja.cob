      * レッスン19：マスターファイルと日次取引ファイルを読み込みます。
      * 各入力ファイルは、それぞれ独自のファイル状態、EOFフラグ、件数を持ちます。
      * 2つのストリームのレコード件数は異なる場合があります。
      * このレッスンではテキストレコードを読み込みます。口座キーの照合は行いません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MULTI19.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-INPUT
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT TRANSACTION-INPUT
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-INPUT.
       01 FD-ACCOUNT-RECORD PIC X(100).
       FD TRANSACTION-INPUT.
       01 FD-TRANSACTION-RECORD PIC X(100).
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-ACCOUNT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * バッチがどちらかのストリームを読む前に、両方の入力を開く必要があります。
       0000-MAIN.
           OPEN INPUT ACCOUNT-INPUT
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT TRANSACTION-INPUT
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-INPUT
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               IF WS-ACCOUNT-EOF = "N"
                   PERFORM 1000-READ-ACCOUNT
               END-IF
               IF WS-TRANSACTION-EOF = "N"
                   AND WS-IO-ERROR = "N"
                   PERFORM 2000-READ-TRANSACTION
               END-IF
           END-PERFORM
           CLOSE ACCOUNT-INPUT
           CLOSE TRANSACTION-INPUT
           IF WS-ACCOUNT-STATUS = "00"
               AND WS-TRANSACTION-STATUS = "00"
               DISPLAY "CLOSE=OK ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TRANSACTIONS=" WS-TRANSACTION-COUNT
           ELSE
               DISPLAY "CLOSE=FAILED ACCOUNT=" WS-ACCOUNT-STATUS
                   " TRANSACTION=" WS-TRANSACTION-STATUS
               MOVE 1 TO RETURN-CODE
           END-IF
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 口座ストリームがEOFに達していない間だけ読み込みます。
       1000-READ-ACCOUNT.
           READ ACCOUNT-INPUT
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   IF WS-ACCOUNT-STATUS = "00"
                       ADD 1 TO WS-ACCOUNT-COUNT
                       DISPLAY "ACCOUNT="
                           FUNCTION TRIM(
                               FD-ACCOUNT-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 取引ストリームがEOFに達していない間だけ読み込みます。
       2000-READ-TRANSACTION.
           READ TRANSACTION-INPUT
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   IF WS-TRANSACTION-STATUS = "00"
                       ADD 1 TO WS-TRANSACTION-COUNT
                       DISPLAY "TRANSACTION="
                           FUNCTION TRIM(
                               FD-TRANSACTION-RECORD TRAILING)
                   END-IF
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * OPEN INPUTでは、各ファイルに個別のステータスを割り当てます。
      * 2つ目を試す前に、最初の入力ファイルを開く必要があります。
      * 2つ目のOPENに失敗した場合、最初のファイルを閉じます。
      * 必要な入力ファイルが両方開くまで、READは実行されません。
      * 各FDは最大100文字のテキスト行を定義します。
      * 各SELECTはLINE SEQUENTIAL編成を使用します。
      * 物理行1行が論理入力レコード1件になります。
      * 短い行はFDレコード領域でパディングされます。
      * TRIMは表示時に右側のパディングを取り除きます。
      * プログラムは表示したフィールドを分割も検証もしません。
      * マスターと取引のレコードレイアウトは異なります。
      * それぞれのレイアウトは2つのフィクスチャファイルで確認できます。
      * ループ1回につき、稼働中の各ストリームを最大1回読み込みます。
      * 口座ファイルが取引ファイルより先にEOFに達する場合があります。
      * 取引ファイルが口座ファイルより先にEOFに達する場合があります。
      * EOFフラグはステータス10になったファイルだけに属します。
      * READが成功すると、そのファイルのレコード件数だけを増やします。
      * EOFになった読み込み試行では、どちらの件数も増えません。
      * EOFに達したファイルは、その後のループでは毎回スキップします。
      * 両方のEOFフラグが立つと処理を終了します。
      * EOF以外の読み込みエラーが発生した場合も、ループを停止します。
      * AT ENDは、そのREAD文におけるステータス10を処理します。
      * NOT AT ENDは、ステータス00のREAD成功を処理します。
      * その他のゼロ以外のステータスは入力エラーとして報告します。
      * I/Oエラーは通常のファイル終端とは異なります。
      * 正常終了時または読み込みエラー時に、両方のファイルを閉じます。
      * クローズエラーは読み込み件数とは別に報告します。
      * OPEN、READ、CLOSEの失敗時は、リターンコードがゼロ以外になります。
      * 空ファイルは最初のREAD試行でEOFに達します。
      * 一方が空でも、もう一方のファイルの読み込みは止まりません。
      * フィクスチャには口座マスターレコードが3件あります。
      * フィクスチャには日次取引レコードが4件あります。
      * これらのファイルは意図的にレコード件数を変えています。
      * 両方のファイルが稼働中は、表示出力が交互に行われます。
      * 口座ファイルがEOFになった後も、取引レコードの読み込みを続けます。
      * 取引ファイルがEOFになった後も、口座レコードの読み込みを続けます。
      * このレッスンでは口座と取引の照合を行いません。
      * 次のレッスンでは、ソート済みキーでレコードを照合します。
      * 本番ジョブではファイル名とバッチ識別子をログに記録してください。
      * この例では、授業で確認しやすいよう出力を短くしています。
      * READとCLOSEのたびにファイルステータスを確認します。
      * OPENが成功すると、ファイルステータスは00になります。
      * ファイルステータス10は、順次読み込みの正常なファイル終端を示します。
      * OPENに失敗すると、バッチは読み込みループに入りません。
      * STOP RUNは、累積したRETURN-CODEをシェルに返します。
      * 両方のフィクスチャを見つけられるよう、レッスンのディレクトリから実行してください。
      * 個別にテストするには、両方の入力を実行ファイルと同じ場所にコピーしてください。
      * このプログラムは出力ファイルを作成も変更もしません。
      * レッスン19では、独立した順次入力ストリームを紹介します。
      * レッスン20では、これらのファイルを使って順序付き照合を行います。
      * 2つの入力ファイルでEOFフラグを共有することはありません。
      * レコード件数は3桁の数値フィールドで表示します。
      * サンプルファイルのレコード数は1000件未満です。
      * ファイル終端は正常な入力状態であり、I/Oエラーではありません。
      * 口座ストリームは現在位置を独立して保持します。
      * 取引ストリームには独自の現在位置があります。
      * READが成功するたびに、選択したファイルだけが進みます。
      * 2つ目のOPENに失敗した場合、すでに開いた最初のファイルを解放します。
      * 空入力時の動作も演習シナリオの一部です。
      * フィクスチャは読みやすいよう、印字可能なASCII文字を使います。
      * ここでは解析と口座照合を扱いません。
      * サマリーで各入力ファイルから読み取った件数を確認できます。
      * 最終サマリーを表示する前に、両方のファイルを閉じます。
      * 行順次ランタイムが物理行末を処理します。
      * 改行バイトがCOBOLレコードのフィールドにコピーされることはありません。
      * この例では入力を2つ使いますが、同じパターンを拡張できます。
      * 入力が増える場合は、各ファイルに独自のステータスとEOF状態を持たせてください。
      * 1つのストリームだけがファイル終端に達したとき、すべてのストリームを停止しないでください。
      * 完全なバッチでは、すべての入力エラーに対する方針を定める必要があります。
      * このレッスンでは、最初のREADエラー後に直ちに停止します。
      * プログラムはどちらの入力ストリームも開き直しませんし、巻き戻しません。
      * 順次READは、ファイル内の元の順序でレコードを読み込みます。
      * 両方の入力ファイルが必須であり、OPTIONALではありません。
      * これらのレコードは読み取り専用で、変更されません。
