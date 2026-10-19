       IDENTIFICATION DIVISION.
       PROGRAM-ID. BATCHL4-STARTER.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 TODO-MARKER PIC X VALUE "Y".
       PROCEDURE DIVISION.
       MAIN-PARA.
      * 未実装：V1をCOPYし、順序付き二分読取を実装。
      * レコード枠/version/ABI/key/domain を比較前に検証。
      * 175項目を RAW/TEXT-NORM/NUMERIC/IGNORE 規則で比較。
      * 機密を伏字化し、制御値を検証して公開。
           DISPLAY "TODO: B04 core is incomplete"
           MOVE 12 TO RETURN-CODE
           STOP RUN.
