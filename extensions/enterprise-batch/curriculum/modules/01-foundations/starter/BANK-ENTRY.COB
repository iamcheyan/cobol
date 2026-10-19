       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-ENTRY-STARTER.
      *M01の夜間バッチ入口の雛形。
      *コンパイル可能だが未実装。RC 12を返し、
      *TODO完了までは受理・拒否出力を公開しない。
      *以下を完成。講師用参照は編集禁止。
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO DYNAMIC IN-PATH
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS IN-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD IN-FILE.
       01 IN-BYTE PIC X.
       WORKING-STORAGE SECTION.
       01 IN-PATH PIC X(4096).
       01 RUN-DATE PIC X(8).
       01 IN-STATUS PIC XX.
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IN-PATH FROM ENVIRONMENT 'INPUT_FILE'
           ACCEPT RUN-DATE FROM ENVIRONMENT 'BUSINESS_DATE'
      *TODO 1:受信ファイルをOPEN INPUTし・失敗を検出。
      *TODO 2：X'0A'まで生Bを読込、各レコードの
      *B長が47でないなら拒否(短／長／末尾LFなし)。
      *TODO 3：口座IDが数字、レイアウトが'001'、日付が
      *BUSINESS_DATEと一致、符号が{+,-}、残高が数字、
      *口座IDが厳密な昇順ことを検証。
      *TODO 4：状態A/F/CをPASS_OUTPUT_FILEへ受理し、
      *それ以外はUNKNOWN-STATUSでREJECT_OUTPUT_FILEへ。
      *TODO 5：JOB/BUSINESS-DATE/CONTROLの報告行をDISPLAYし、
      *RETURN-CODEを拒否なしなら0・一部拒否なら4に。
           DISPLAY 'TODO: implement validated account posted-file entry'
           MOVE 12 TO RETURN-CODE
           GOBACK.
