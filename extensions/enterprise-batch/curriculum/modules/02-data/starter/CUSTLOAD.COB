       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTLOAD-STARTER.
      *M02雛形：CUSTOMER v1ローダーの骨格。
      *コンパイル可能だが未実装。RC 12を返し、
      *TODO完了までは受理・拒否出力を公開しない。
      *レイアウトにはCUSTOMER v1 copybookを使う。
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
       01 IN-STATUS PIC XX.
           COPY "CUSTOMER-V1.CPY".
       PROCEDURE DIVISION.
       1000-MAIN.
           ACCEPT IN-PATH FROM ENVIRONMENT 'INPUT_FILE'
      *TODO 1：OPEN INPUTし、X'0A'まで生Bを読込、
      *B長が正確に27でないレコードを拒否。
      *TODO 2：顧客IDが数字で、厳密な昇順ことを検証。
      *TODO 3：空白名（NAME-MISSING）、数字以外の残高
      *（BAD-AMOUNT）、不正状態（UNKNOWN-STATUS）を
      *この優先順位で拒否。
      *TODO 4：受理したBALANCE-DEMOを18桁の合計に加算。
      *TODO 5：'JOB|CUSTLOAD|V1'とCONTROL行をDISPLAYし、
      *RETURN-CODEを拒否なしなら0・一部拒否なら4に。
           DISPLAY 'TODO: implement validated CUSTOMER v1 loading'
           MOVE 12 TO RETURN-CODE
           GOBACK.
