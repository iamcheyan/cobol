      *レッスン 16: 機密扱いのトランザクション結果を 2 つのファイルに書き込みます。
      *OPEN OUTPUT は、各出力ファイルの以前の内容を置き換えます。
      *各 WRITE は、1 つの完全な行順次結果レコードを送信します。
      *承認されたレコードと拒否されたレコードは別々の宛先に送られます。
      *固定結果文字列の長さはちょうど 35 文字です。
      *このサンプルは、事前に分類されたレコードを使用した出力に焦点を当てています。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. WRITE16.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT 受理-FILE
               ASSIGN TO "accepted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-受理-STATUS.
           SELECT 拒否-FILE
               ASSIGN TO "rejected.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-拒否-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD 受理-FILE.
       01 FD-受理-RECORD PIC X(35).
       FD 拒否-FILE.
       01 FD-拒否-RECORD PIC X(35).
       WORKING-STORAGE SECTION.
       01 WS-RESULT-TABLE.
          05 WS-RESULT-ENTRY OCCURS 4 TIMES.
             10 WS-RESULT-DESTINATION PIC X.
             10 WS-RESULT-TEXT PIC X(35).
       01 WS-RESULT-NUMBER PIC 9 VALUE ZERO.
       01 WS-受理-STATUS PIC XX VALUE SPACES.
       01 WS-拒否-STATUS PIC XX VALUE SPACES.
       01 WS-受理-COUNT PIC 9(2) VALUE ZERO.
       01 WS-拒否-COUNT PIC 9(2) VALUE ZERO.
       01 WS-WRITE-ERROR PIC X VALUE "N".
       PROCEDURE DIVISION.
      *結果レコードを書き込む前に、両方の出力を開いてください。
       0000-MAIN.
           OPEN OUTPUT 受理-FILE
           IF WS-受理-STATUS NOT = "00"
               DISPLAY "オープン=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=受理 成功"
           OPEN OUTPUT 拒否-FILE
           IF WS-拒否-STATUS NOT = "00"
               DISPLAY "オープン=拒否 失敗 状態="
                   WS-拒否-STATUS
               CLOSE 受理-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "オープン=拒否 成功"
           PERFORM 1000-LOAD-RESULTS
           PERFORM VARYING WS-RESULT-NUMBER FROM 1 BY 1
               UNTIL WS-RESULT-NUMBER > 4
                   OR WS-WRITE-ERROR = "Y"
               PERFORM 2000-WRITE-ONE-RESULT
           END-PERFORM
           PERFORM 9000-CLOSE-OUTPUTS
           IF WS-WRITE-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      *2 つの承認された固定結果レコードと 2 つの拒否された固定結果レコードをロードします。
       1000-LOAD-RESULTS.
           MOVE "A" TO WS-RESULT-DESTINATION(1)
           MOVE "TXN-000001|0001234567|D|000125.50|A"
               TO WS-RESULT-TEXT(1)
           MOVE "A" TO WS-RESULT-DESTINATION(2)
           MOVE "TXN-000002|0007654321|T|000040.00|A"
               TO WS-RESULT-TEXT(2)
           MOVE "R" TO WS-RESULT-DESTINATION(3)
           MOVE "TXN-000003|0002468101|X|000000.00|R"
               TO WS-RESULT-TEXT(3)
           MOVE "R" TO WS-RESULT-DESTINATION(4)
           MOVE "TXN-000004|0009999999|T|000020.00|R"
               TO WS-RESULT-TEXT(4).
      *事前に分類された 1 つのレコードを、対応する出力ファイルにルーティングします。
       2000-WRITE-ONE-RESULT.
           EVALUATE WS-RESULT-DESTINATION(WS-RESULT-NUMBER)
               WHEN "A"
                   WRITE FD-受理-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-受理-STATUS = "00"
                       ADD 1 TO WS-受理-COUNT
                       DISPLAY "書込=受理"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=受理 失敗 状態="
                           WS-受理-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN "R"
                   WRITE FD-拒否-RECORD
                       FROM WS-RESULT-TEXT(WS-RESULT-NUMBER)
                   IF WS-拒否-STATUS = "00"
                       ADD 1 TO WS-拒否-COUNT
                       DISPLAY "書込=拒否"
                           " 取引=" WS-RESULT-TEXT(
                               WS-RESULT-NUMBER)(5:6)
                   ELSE
                       DISPLAY "書込=拒否 失敗 状態="
                           WS-拒否-STATUS
                       MOVE "Y" TO WS-WRITE-ERROR
                   END-IF
               WHEN OTHER
                   DISPLAY "書込=FAILED REASON=UNKNOWN_DESTINATION"
                   MOVE "Y" TO WS-WRITE-ERROR
           END-EVALUATE.
      *書き込みループの後に両方の出力ストリームを閉じます。
       9000-CLOSE-OUTPUTS.
           CLOSE 受理-FILE
           IF WS-受理-STATUS = "00"
               DISPLAY "クローズ=受理 成功"
           ELSE
               DISPLAY "クローズ=受理 失敗 状態="
                   WS-受理-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           CLOSE 拒否-FILE
           IF WS-拒否-STATUS = "00"
               DISPLAY "クローズ=拒否 成功"
           ELSE
               DISPLAY "クローズ=拒否 失敗 状態="
                   WS-拒否-STATUS
               MOVE "Y" TO WS-WRITE-ERROR
           END-IF
           DISPLAY "SUMMARY 受理=" WS-受理-COUNT
               " 拒否=" WS-拒否-COUNT.
      *OPEN OUTPUT は、ファイルを作成するか、その古い内容を置き換えます。
      *LINE SEQUENTIAL は、書き込まれたすべてのレコードを改行で終了します。
      *FD レコード サイズとソース結果サイズは両方とも 35 バイトです。
      *WRITE が成功するたびに、ファイルのステータスが 00 に設定されます。
      *2 つのファイルには独立したファイル ステータス フィールドがあります。
      *出力テーブルの A または R マーカーが宛先を選択します。
      *結果レコードは、元のテーブルの順序で書き込まれます。
      *カウントは、書き込みが成功した後にのみ増加します。
      *失敗した OPEN は、対応するファイルが書き込まれる前に停止します。
      *WRITE が失敗すると、エラー フラグが設定され、その後の書き込みが停止されます。
      *両方のファイルは、書き込みループの後に閉じられます。
      *要約レポートでは、ファイルごとに正常に書き込まれたレコードが記録されます。
      *出力パスは、プログラムの現在のディレクトリからの相対パスです。
      *一時ディレクトリで実行すると、生成されたファイルは別々に保持されます。
      *OPEN OUTPUT は追加モードではありません。古いデータは置き換えられます。
      *後のレッスンで追加動作が必要な場合は、OPEN EXTEND を使用します。
      *この例では、前のレッスンの入力ファイルを読み取りません。
      *その行は、焦点として書き込みを続けるためにすでに分類されています。
      *ここでは口座残高の計算は行われません。
      *レッスン 22 プロジェクトでは、読み取り、ルール、出力を組み合わせます。
      *CLOSE が成功すると、未処理のレコード バッファがフラッシュされます。
      *STOP RUN はファイル書き込みデモを終了します。
