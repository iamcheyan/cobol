      * レッスン17：固定長レコードを読み取り、固定レイアウトで書き出します。
      * 順次バイナリファイルでは、レコードを区切る行末文字はありません。
      * 各サンプル入力レコードは、表示文字でちょうど27バイトです。
      * フィールド位置：口座1–10、顧客11–18、残高19–27。
      * 出力位置：顧客1–8、口座9–18、残高19–27です。
      * 入力と出力のフィクスチャは、レコードのバイト列をそのまま連結したものです。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. FIXED17.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "accounts.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ACCOUNT-STATUS.
           SELECT BALANCE-FILE
               ASSIGN TO "balances.dat"
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-BALANCE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD ACCOUNT-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-ACCOUNT-RECORD.
          05 FD-ACCOUNT-NUMBER PIC X(10).
          05 FD-CUSTOMER-ID PIC X(8).
          05 FD-ACCOUNT-BALANCE PIC 9(7)V99.
       FD BALANCE-FILE
           RECORD CONTAINS 27 CHARACTERS.
       01 FD-BALANCE-RECORD.
          05 FD-OUT-CUSTOMER-ID PIC X(8).
          05 FD-OUT-ACCOUNT-NUMBER PIC X(10).
          05 FD-OUT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-ACCOUNT-STATUS PIC XX VALUE SPACES.
       01 WS-BALANCE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-RECORD-COUNT PIC 9(2) VALUE ZERO.
       PROCEDURE DIVISION.
      * 生のマスターファイルを開き、固定幅の出力ファイルを作成します。
       0000-MAIN.
           OPEN INPUT ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           OPEN OUTPUT BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "OPEN=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               CLOSE ACCOUNT-FILE
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY "OPEN=INPUT OK OPEN=OUTPUT OK"
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-IO-ERROR = "Y"
               PERFORM 1000-READ-AND-WRITE
           END-PERFORM
           PERFORM 9000-CLOSE-FILES
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 27バイトのレコードを1件読み取り、並べ替えたフィールドを書き出します。
       1000-READ-AND-WRITE.
           READ ACCOUNT-FILE
               AT END
                   MOVE "Y" TO WS-END-OF-FILE
               NOT AT END
                   PERFORM 1100-WRITE-BALANCE-RECORD
           END-READ.
      * 名前付きフィールドを、出力レコードで定義した位置に移します。
       1100-WRITE-BALANCE-RECORD.
           MOVE FD-CUSTOMER-ID TO FD-OUT-CUSTOMER-ID
           MOVE FD-ACCOUNT-NUMBER TO FD-OUT-ACCOUNT-NUMBER
           MOVE FD-ACCOUNT-BALANCE TO FD-OUT-BALANCE
           WRITE FD-BALANCE-RECORD
           IF WS-BALANCE-STATUS = "00"
               ADD 1 TO WS-RECORD-COUNT
               DISPLAY "WROTE ACCOUNT=" FD-OUT-ACCOUNT-NUMBER
                   " CUSTOMER=" FD-OUT-CUSTOMER-ID
                   " BALANCE=" FD-OUT-BALANCE
           ELSE
               DISPLAY "WRITE=FAILED STATUS=" WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * 両方のファイルを閉じ、正常に書き込めたレコード数を報告します。
       9000-CLOSE-FILES.
           CLOSE ACCOUNT-FILE
           IF WS-ACCOUNT-STATUS NOT = "00"
               DISPLAY "CLOSE=INPUT FAILED STATUS="
                   WS-ACCOUNT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           CLOSE BALANCE-FILE
           IF WS-BALANCE-STATUS NOT = "00"
               DISPLAY "CLOSE=OUTPUT FAILED STATUS="
                   WS-BALANCE-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "CLOSE=OK RECORDS=" WS-RECORD-COUNT.
      * RECORD CONTAINSとFDフィールド定義は、どちらも27バイトです。
      * DISPLAYフィールドはテキストのバイトを使い、小数点位置は暗黙的に表します。
      * PIC 9(7)V99のVは、ファイル上の実バイトを占めません。
      * したがって、残高は表示数字9桁分のバイトを占めます。
      * 入力フィクスチャは27バイトのレコード3件で構成され、区切り文字はありません。
      * 2件目のレコードはバイトオフセット28から始まります。
      * 出力レコードは口座IDではなく、顧客IDから始まります。
      * 続く10バイトには口座番号が格納されます。
      * 最後の9バイトには同じ数値の残高が格納されます。
      * ORGANIZATION SEQUENTIALは、生の固定長レコードをバイト単位で配置する形式です。
      * LINE SEQUENTIALテキストとは物理形式が異なります。
      * 順次レコードの間に改行文字を挿入しないでください。
      * テキストエディターは行末文字を追加するため、このフィクスチャが壊れます。
      * READが成功するたびに、FDレコードが1件プログラムに渡されます。
      * READ AT ENDはループを終了し、出力レコードは作成しません。
      * WRITEが成功するたびに、ちょうど27バイトの出力レコードが1件追加されます。
      * 出力ファイルのサイズは、レコード数に27バイトを掛けた値です。
      * ファイルステータス00は、OPEN、READ、WRITE、CLOSEの成功を示します。
      * プログラムは入力ファイル内の口座順を維持します。
      * ソート、検索、算術演算によって口座残高が変更されることはありません。
      * OPEN OUTPUTはbalances.datの既存内容を置き換えます。
      * パスはプロセスの現在の作業ディレクトリからの相対パスです。
      * accounts.datを置いた一時ディレクトリで実行してください。
      * このサンプルではASCIIの表示文字と数字を使います。
      * バイナリCOMPデータには、別途レイアウトの指定が必要です。
      * 入力と出力ではフィールド順が異なりますが、合計サイズは同じです。
      * 固定幅データファイルを受け渡す前に、フィールドのオフセットを確認してください。
      * 入力ファイルが見つからない場合、出力ファイルを開く前にエラーを報告します。
      * 出力ファイルを正常に閉じると、固定長レコードがフラッシュされます。
      * STOP RUNは、この固定長レコード変換の例を終了します。
