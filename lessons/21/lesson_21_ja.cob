      * レッスン21：手続きで未ソートの口座ファイルをソートします。
      * 入力手続きはレコードをソート作業ファイルにRELEASEします。
      * 出力手続きはキーの昇順でレコードをRETURNします。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SORT21.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT UNSORTED-INPUT
               ASSIGN TO "accounts-unsorted.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT SORT-WORK ASSIGN TO DISK.
       DATA DIVISION.
       FILE SECTION.
       FD UNSORTED-INPUT.
       01 FD-INPUT-RECORD PIC X(27).
       SD SORT-WORK.
       01 SD-SORT-RECORD.
          05 SD-ACCOUNT-NUMBER PIC X(10).
          05 SD-CUSTOMER-ID PIC X(8).
          05 SD-ACCOUNT-BALANCE PIC 9(7)V99.
       WORKING-STORAGE SECTION.
       01 WS-INPUT-STATUS PIC XX VALUE SPACES.
       01 WS-INPUT-EOF PIC X VALUE "N".
       01 WS-SORT-EOF PIC X VALUE "N".
       01 WS-IO-ERROR PIC X VALUE "N".
       01 WS-INPUT-COUNT PIC 9(3) VALUE ZERO.
       01 WS-OUTPUT-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * SORTが入力、ソート、出力の各段階を制御します。
       0000-MAIN.
           SORT SORT-WORK ON ASCENDING KEY SD-ACCOUNT-NUMBER
               INPUT PROCEDURE 1000-LOAD-INPUT
               OUTPUT PROCEDURE 2000-RETURN-SORTED.
           IF SORT-RETURN NOT = ZERO
               DISPLAY "SORT=FAILED STATUS=" SORT-RETURN
               MOVE "Y" TO WS-IO-ERROR
           END-IF
           DISPLAY "SUMMARY INPUT=" WS-INPUT-COUNT
               " OUTPUT=" WS-OUTPUT-COUNT
           IF WS-IO-ERROR = "Y"
               MOVE 1 TO RETURN-CODE
           END-IF
           STOP RUN.
      * 入力行を読み込み、有効な各レコードをSORTにRELEASEします。
       1000-LOAD-INPUT.
           OPEN INPUT UNSORTED-INPUT
           IF WS-INPUT-STATUS NOT = "00"
               DISPLAY "OPEN=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           ELSE
               PERFORM UNTIL WS-INPUT-EOF = "Y"
                   OR WS-IO-ERROR = "Y"
                   PERFORM 1100-READ-AND-RELEASE
               END-PERFORM
               CLOSE UNSORTED-INPUT
               IF WS-INPUT-STATUS NOT = "00"
                   DISPLAY "CLOSE=INPUT FAILED STATUS="
                       WS-INPUT-STATUS
                   MOVE "Y" TO WS-IO-ERROR
               END-IF
           END-IF.
      * 1行を読み込みます。AT ENDで終了するのは入力手続きのループだけです。
       1100-READ-AND-RELEASE.
           READ UNSORTED-INPUT
               AT END
                   MOVE "Y" TO WS-INPUT-EOF
               NOT AT END
                   IF WS-INPUT-STATUS = "00"
                       MOVE FD-INPUT-RECORD TO SD-SORT-RECORD
                       RELEASE SD-SORT-RECORD
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-INPUT-COUNT
                       ELSE
                           DISPLAY "RELEASE=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
                   END-IF
           END-READ
           IF WS-INPUT-STATUS NOT = "00"
               AND WS-INPUT-STATUS NOT = "10"
               DISPLAY "READ=INPUT FAILED STATUS=" WS-INPUT-STATUS
               MOVE "Y" TO WS-IO-ERROR
           END-IF.
      * SORTが出力EOFを報告するまで、ソート済みレコードをRETURNします。
       2000-RETURN-SORTED.
           PERFORM UNTIL WS-SORT-EOF = "Y"
               OR WS-IO-ERROR = "Y"
               RETURN SORT-WORK
                   AT END
                       MOVE "Y" TO WS-SORT-EOF
                   NOT AT END
                       IF SORT-RETURN = ZERO
                           ADD 1 TO WS-OUTPUT-COUNT
                           DISPLAY "SORTED ACCOUNT="
                               SD-ACCOUNT-NUMBER
                               " CUSTOMER=" SD-CUSTOMER-ID
                               " BALANCE=" SD-ACCOUNT-BALANCE
                       ELSE
                           DISPLAY "RETURN=FAILED STATUS="
                               SORT-RETURN
                           MOVE "Y" TO WS-IO-ERROR
                       END-IF
               END-RETURN
           END-PERFORM.
      * 入力ファイルは意図的にキー順ではありません。
      * レコード幅は27文字で、レッスン17と同じです。
      * 口座番号は1～10桁を占めます。
      * 顧客IDは11～18桁を占めます。
      * 残高は19～27桁を占めます。
      * ソート作業レコードも同じフィールドレイアウトを使います。
      * SORT-WORKはFDではなくSDで記述します。
      * 作業ファイルはSORTが管理し、プログラムはOPENしません。
      * 入力手続きはSORTの入力段階の一部として実行されます。
      * RELEASEは現在のSDレコードをソート作業ファイルに追加します。
      * 入力手続きはソースファイルがEOFに達するまで読み込みます。
      * FILE STATUSでEOFとその他の入力エラーを区別します。
      * ソート出力手続きの前にソースファイルを閉じます。
      * ソート段階では、宣言したキーでレコードを並べます。
      * 口座キーは先頭ゼロを含む固定幅テキストです。
      * このフィクスチャに重複キーはありません。
      * ソート完了後に出力手続きを実行します。
      * RETURNはソート済みレコードを1件ずつ取得します。
      * RETURN AT ENDで出力手続きのループを終了します。
      * 出力手続きはキーの昇順でレコードを表示します。
      * SORTが成功すれば、入力件数と出力件数は等しくなるはずです。
      * 入力が空の場合、RELEASEは0回、RETURNレコードも0件です。
      * RELEASEの成功後に限り、入力件数を増やします。
      * RETURNの成功後に限り、出力件数を増やします。
      * ソースのOPEN、READ、CLOSEでエラーが起きると失敗フラグを設定します。
      * SORT-RETURNがゼロ以外の場合、RELEASE、RETURN、またはSORTの失敗を示します。
      * I/Oエラーを検出すると、プロセスはステータス1を返します。
      * このプログラムはソート済みレコードを表示し、出力ファイルは作成しません。
      * ソート作業領域は、小規模なメモリ内テーブルを超えるサイズにできます。
      * GnuCOBOLは、大規模なソートで一時ストレージを使う場合があります。
      * フィクスチャは印字可能文字を使い、物理行は1行です。
      * 各行の3つの固定幅フィールドの間に区切り文字はありません。
      * 行末文字は27文字のFDレコードに含まれません。
      * ASSIGNで入力フィクスチャを見つけられるよう、このディレクトリから実行してください。
      * ソート処理は口座や顧客の識別子を検証しません。
      * ソートによって入力ファイルの元の順序が変わることはありません。
      * プログラムは入力キーの順序に依存しません。
      * ソート結果は口座番号だけを基準に昇順になります。
      * 後続のバッチで、この順序付きストリームをファイル照合に渡せます。
      * レッスン20では、順序付き口座キーを使って逐次照合します。
      * 入力手続きはPERFORMされた手続きと同様に終了する必要があります。
      * 出力手続きは最後のRETURN後に終了する必要があります。
      * SORTは各段階で、それぞれの名前付き手続きを呼び出します。
      * SORTの入力手続きではRELEASEを使用できます。
      * SORTの出力手続きではRETURNを使用できます。
      * ソート作業の各操作後にSORT-RETURNを確認します。
      * 最終サマリーでレコードの欠落や重複を確認できます。
      * この小規模な演習では、すべてのカウンターが3桁フィールドです。
      * 想定入力には異なる口座キーが4つ含まれます。
      * 出力順は入力順に左右されません。
      * STOP RUNは最終RETURN-CODEをシェルに返します。
