      * メイン段落では、初期化、処理、およびファイナライズを実行します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARAGRAPH07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 125.50.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * 呼び出しは、初期化、処理、終了の順序で実行されます。
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
           DISPLAY "バッチ=COMPLETE"
           STOP RUN.
      * 初期化ステージでは、出力フィールドの処理を準備します。
       1000-INITIALIZE.
           DISPLAY "段階=INITIALIZE"
           MOVE ZERO TO WS-CLOSING-BALANCE.
       2000-PROCESS.
           DISPLAY "段階=PROCESS"
           COMPUTE WS-CLOSING-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT - WS-WITHDRAWAL
           DISPLAY "期末残高=" WS-CLOSING-BALANCE.
       9000-FINALIZE.
           DISPLAY "段階=FINALIZE"
           DISPLAY "最終残高=" WS-CLOSING-BALANCE.
      * 4 つのデータ項目はすべて、ここでの共有プログラム ストレージのままです。
      * 初期化は演算処理段階に先立って行われます。
      * コールの順序を変更すると、表示されるステージの順序が変わります。
