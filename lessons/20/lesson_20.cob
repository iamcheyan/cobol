      * レッスン20：ソート済みの2つの口座ファイルを口座番号で照合します。
      * マスターレコードは27文字、取引レコードは20文字です。
      * 各入力は10文字のキーで昇順にソートされています。
      * マージ処理で、照合一致と片側だけに存在するレコードを分類します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MATCH20.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-MASTER
               ASSIGN TO "accounts.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT DAILY-TRANSACTIONS
               ASSIGN TO "transactions.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-TRANSACTION-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-MASTER.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD DAILY-TRANSACTIONS.
       01 FD-TRANSACTION-RECORD.
          05 FD-TRANSACTION-ACCOUNT PIC X(10).
          05 FD-TRANSACTION-TYPE PIC X.
          05 FD-TRANSACTION-AMOUNT PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-TRANSACTION-STATUS PIC XX VALUE SPACES.
       01 WS-ACCOUNT-EOF PIC X VALUE "N".
       01 WS-TRANSACTION-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-MATCH-COUNT PIC 9(3) VALUE ZERO.
       01 WS-ACCOUNT-ONLY-COUNT PIC 9(3) VALUE ZERO.
       01 WS-TRANSACTION-ONLY-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * どちらかのストリームを位置付ける前に、両方のソート済み入力を開きます。
       0000-MAIN.
           OPEN INPUT ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN INPUT DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "OPEN=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               CLOSE ACCOUNT-MASTER
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=ACCOUNT OK OPEN=TRANSACTION OK"
           PERFORM 1000-READ-ACCOUNT
           PERFORM 2000-READ-TRANSACTION
           PERFORM UNTIL WS-ACCOUNT-EOF = "Y"
               AND WS-TRANSACTION-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 3000-MATCH-CURRENT-RECORDS
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 現在のキーを比較し、小さい方または一致した両方のストリームを進めます。
       3000-MATCH-CURRENT-RECORDS.
           EVALUATE TRUE
               WHEN WS-ACCOUNT-EOF = "Y"
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN WS-TRANSACTION-EOF = "Y"
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER < FD-TRANSACTION-ACCOUNT
                   PERFORM 4000-REPORT-ACCOUNT-ONLY
                   PERFORM 1000-READ-ACCOUNT
               WHEN FD-ACCOUNT-NUMBER > FD-TRANSACTION-ACCOUNT
                   PERFORM 4100-REPORT-TRANSACTION-ONLY
                   PERFORM 2000-READ-TRANSACTION
               WHEN OTHER
                   PERFORM 4200-REPORT-MATCH
                   PERFORM 1000-READ-ACCOUNT
                   IF WS-IO-ERROR = "N"
                       PERFORM 2000-READ-TRANSACTION
                   END-IF
           END-EVALUATE.
      * 次のマスターレコードを読むか、このストリームだけをEOFとして記録します。
       1000-READ-ACCOUNT.
           READ ACCOUNT-MASTER
               AT END
                   MOVE "Y" TO WS-ACCOUNT-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-ACCOUNT-STATUS NOT = "00"
               AND WS-ACCOUNT-STATUS NOT = "10"
               DISPLAY "READ=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 次の取引レコードを読むか、このストリームだけをEOFとして記録します。
       2000-READ-TRANSACTION.
           READ DAILY-TRANSACTIONS
               AT END
                   MOVE "Y" TO WS-TRANSACTION-EOF
               NOT AT END
                   CONTINUE
           END-READ
           IF WS-TRANSACTION-STATUS NOT = "00"
               AND WS-TRANSACTION-STATUS NOT = "10"
               DISPLAY "READ=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * マスターキーは現在の取引キーより前に並びます。
       4000-REPORT-ACCOUNT-ONLY.
           ADD 1 TO WS-ACCOUNT-ONLY-COUNT
           DISPLAY "ACCOUNT_ONLY ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE.
      * 取引キーは現在のマスターキーより前に並びます。
       4100-REPORT-TRANSACTION-ONLY.
           ADD 1 TO WS-TRANSACTION-ONLY-COUNT
           DISPLAY "TRANSACTION_ONLY ACCOUNT="
               FD-TRANSACTION-ACCOUNT
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * 一致するキーは、1つの口座とその日次取引を示します。
       4200-REPORT-MATCH.
           ADD 1 TO WS-MATCH-COUNT
           DISPLAY "MATCH ACCOUNT=" FD-ACCOUNT-NUMBER
               " CUSTOMER=" FD-CUSTOMER-ID
               " BALANCE=" FD-ACCOUNT-BALANCE
               " TYPE=" FD-TRANSACTION-TYPE
               " AMOUNT=" FD-TRANSACTION-AMOUNT.
      * 両方の入力を閉じ、3種類の分類件数を報告します。
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-MASTER
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=ACCOUNT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE DAILY-TRANSACTIONS
           IF WS-TRANSACTION-STATUS NOT = "00"
               DISPLAY "CLOSE=TRANSACTION FAILED STATUS="
                   WS-TRANSACTION-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY MATCHED=" WS-MATCH-COUNT
               " ACCOUNT_ONLY=" WS-ACCOUNT-ONLY-COUNT
               " TRANSACTION_ONLY=" WS-TRANSACTION-ONLY-COUNT.
      * 両方のフィクスチャファイルは口座キーの昇順にソートされています。
      * マスターキーは10文字の口座番号です。
      * 取引キーも同じ10文字の口座番号です。
      * マスターキーの方が小さい場合、一致する取引キーはありません。
      * 取引キーの方が小さい場合、一致するマスターキーはありません。
      * キーが一致すると、レコードの組を照合一致として分類します。
      * 一致した後、両方の入力ストリームを1回ずつ進めます。
      * 片側だけのレコードの後は、その側だけを進めます。
      * 片側がEOFに達した時点で、もう一方に残るレコードは孤立レコードです。
      * 各ストリームは独自のステータスとEOF状態を持ちます。
      * ステータス10は正常なEOFです。それ以外の読み込みエラーではマージを停止します。
      * AT ENDは、その直前のREADにおけるEOFを処理します。
      * FILE STATUSを確認して、その他の読み込み失敗を判別します。
      * 口座残高と取引金額は、暗黙のセント単位を使います。
      * この例では値を報告しますが、新しい残高は計算しません。
      * 重複キーは、このレッスンの「1キーにつき1行」という規則の対象外です。
      * 入力がソートされていないと、前方向の比較アルゴリズムは成立しません。
      * まず両方のファイルを同じ口座キー照合順序でソートしてください。
      * キーのフィールド長は等しく、テキストとして比較します。
      * 先頭のゼロは、これらの口座キーで意味を持ちます。
      * マスターと取引のレコードレイアウトは固定幅のテキスト行です。
      * 各物理行にはレコードが1件含まれ、フィールド間の区切り文字はありません。
      * FDレコード長はフィクスチャの行長と一致します。
      * 両方のファイルが必須であり、正常に開ける必要があります。
      * 2つ目のOPENに失敗した場合、最初の入力を閉じます。
      * READが成功すると、そのREADで指定したファイルだけが進みます。
      * 行数にかかわらず、マージ処理の作業領域は一定です。
      * 入力ファイル全体をメモリに保存するOCCURSテーブルは使いません。
      * これは順次マージであり、両ファイルを入れ子にして検索する方法ではありません。
      * 実行時間は入力レコードの総数に応じて増加します。
      * 出力ラベルで照合一致と、両方向の孤立レコードを区別します。
      * 照合一致の組に対して、各入力は最大1行を提供します。
      * 比較で現在のキーを参照する前にEOFを確認します。
      * 空ファイル側のレコード数は0件です。
      * サマリーは読み込み試行回数ではなく、分類件数を集計します。
      * プログラムはどちらの入力フィクスチャも書き込みも変更もしません。
      * 以降のレッスンでは、ソートと完全なバッチ出力ファイルを追加します。
      * 両方のASSIGNパスからフィクスチャを見つけられるよう、ここで実行してください。
      * I/Oエラーの後、プログラムはゼロ以外のステータスを返します。
      * サンプルには照合一致、マスター側だけの行、孤立レコードが含まれます。
      * 取引側だけの1行は、2つのマスターキーの間に並びます。
      * もう1つの取引側だけの行は、マスターがEOFになった後も残ります。
      * フィクスチャでは、両方向のキー比較とEOF処理を確認できます。
      * STOP RUNはバッチのステータスコードをオペレーティングシステムに返します。
