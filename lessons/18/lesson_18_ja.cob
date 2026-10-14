      * レッスン18：1行1件のCSV顧客レコードを検証して解析します。
      * 5つのフィールドはID、名前、口座、ステータス、備考です。
      * 引用符内のカンマと二重引用符は、フィールドの内容として解析されます。
      * 空フィールドは保持され、20文字を超えるフィールドは拒否されます。
      * この仕様では、CSVレコード1件が物理行1行を占めます。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. CSV18.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-CSV
               ASSIGN TO "customers.csv"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD CUSTOMER-CSV.
       01 FD-CSV-RECORD PIC X(200).
       WORKING-STORAGE SECTION.
       01 WS-FIELDS.
          05 WS-FIELD-VALUE OCCURS 5 TIMES PIC X(20).
       01 WS-FILE-STATUS PIC XX VALUE SPACES.
       01 WS-END-OF-FILE PIC X VALUE "N".
       01 WS-IN-QUOTES PIC X VALUE "N".
       01 WS-AFTER-QUOTE PIC X VALUE "N".
       01 WS-FIELD-START PIC X VALUE "Y".
       01 WS-COMMA PIC X VALUE X"2C".
       01 WS-QUOTE PIC X VALUE X"22".
       01 WS-CURRENT-CHAR PIC X VALUE SPACE.
       01 WS-CSV-ERROR PIC X(20) VALUE SPACES.
       01 WS-ROW-COUNT PIC 9(2) VALUE ZERO.
       01 WS-VALID-COUNT PIC 9(2) VALUE ZERO.
       01 WS-REJECTED-COUNT PIC 9(2) VALUE ZERO.
       01 WS-LINE-LENGTH PIC 9(3) VALUE ZERO.
       01 WS-CHAR-POSITION PIC 9(3) VALUE ZERO.
       01 WS-NEXT-POSITION PIC 9(3) VALUE ZERO.
       01 WS-FIELD-NUMBER PIC 9(3) VALUE ZERO.
       01 WS-FIELD-LENGTH PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      * CSVの各物理行をファイル順に読み取り、検証します。
       0000-MAIN.
           OPEN INPUT CUSTOMER-CSV
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "OPEN=FAILED STATUS=" WS-FILE-STATUS
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM UNTIL WS-END-OF-FILE = "Y"
               READ CUSTOMER-CSV
                   AT END
                       MOVE "Y" TO WS-END-OF-FILE
                   NOT AT END
                       ADD 1 TO WS-ROW-COUNT
                       PERFORM 1000-PARSE-ROW
               END-READ
           END-PERFORM
           CLOSE CUSTOMER-CSV
           DISPLAY "SUMMARY ROWS=" WS-ROW-COUNT
               " VALID=" WS-VALID-COUNT
               " REJECTED=" WS-REJECTED-COUNT
           STOP RUN.
      * 入力行を個別に処理する前に、パーサーの状態をリセットします。
       1000-PARSE-ROW.
           INITIALIZE WS-FIELDS
           MOVE SPACES TO WS-CSV-ERROR
           MOVE 1 TO WS-FIELD-NUMBER
           MOVE ZERO TO WS-FIELD-LENGTH
           MOVE "Y" TO WS-FIELD-START
           MOVE "N" TO WS-IN-QUOTES
           MOVE "N" TO WS-AFTER-QUOTE
           COMPUTE WS-LINE-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(
                   FD-CSV-RECORD TRAILING))
           PERFORM VARYING WS-CHAR-POSITION FROM 1 BY 1
               UNTIL WS-CHAR-POSITION > WS-LINE-LENGTH
               MOVE FD-CSV-RECORD(WS-CHAR-POSITION:1)
                   TO WS-CURRENT-CHAR
               PERFORM 2000-PARSE-CHARACTER
           END-PERFORM
           IF WS-IN-QUOTES = "Y"
               PERFORM 2900-SET-UNCLOSED-QUOTE
           END-IF
           IF WS-FIELD-START = "Y" AND WS-FIELD-NUMBER > 1
               PERFORM 2920-SET-TRAILING-COMMA
           END-IF
           IF WS-FIELD-NUMBER NOT = 5
               PERFORM 2910-SET-FIELD-COUNT-ERROR
           END-IF
           PERFORM 3000-REPORT-ROW.
      * 現在の文字に対して、引用符とカンマの規則を適用します。
       2000-PARSE-CHARACTER.
           IF WS-IN-QUOTES = "Y"
               IF WS-CURRENT-CHAR = WS-QUOTE
                   PERFORM 2100-HANDLE-QUOTE-IN-FIELD
               ELSE
                   PERFORM 4000-APPEND-CHARACTER
               END-IF
           ELSE
               PERFORM 2200-HANDLE-UNQUOTED-CHAR
           END-IF.
      * 二重引用符は、引用符で囲まれた値の中では引用符1文字を表します。
       2100-HANDLE-QUOTE-IN-FIELD.
           IF WS-CHAR-POSITION < WS-LINE-LENGTH
               COMPUTE WS-NEXT-POSITION = WS-CHAR-POSITION + 1
               IF FD-CSV-RECORD(WS-NEXT-POSITION:1) = WS-QUOTE
                   PERFORM 4000-APPEND-CHARACTER
                   ADD 1 TO WS-CHAR-POSITION
               ELSE
                   MOVE "N" TO WS-IN-QUOTES
                   MOVE "Y" TO WS-AFTER-QUOTE
               END-IF
           ELSE
               MOVE "N" TO WS-IN-QUOTES
               MOVE "Y" TO WS-AFTER-QUOTE
           END-IF.
      * 引用符の外では、カンマがフィールドを終了し、引用符がフィールドを開始します。
       2200-HANDLE-UNQUOTED-CHAR.
           IF WS-AFTER-QUOTE = "Y"
               IF WS-CURRENT-CHAR = WS-COMMA
                   PERFORM 2300-START-NEXT-FIELD
               ELSE
                   IF WS-CSV-ERROR = SPACES
                       MOVE "TEXT_AFTER_QUOTE" TO WS-CSV-ERROR
                   END-IF
               END-IF
           ELSE
               EVALUATE WS-CURRENT-CHAR
                   WHEN WS-COMMA
                       PERFORM 2300-START-NEXT-FIELD
                   WHEN WS-QUOTE
                       IF WS-FIELD-START = "Y"
                           MOVE "Y" TO WS-IN-QUOTES
                           MOVE "N" TO WS-FIELD-START
                       ELSE
                           IF WS-CSV-ERROR = SPACES
                               MOVE "QUOTE_IN_UNQUOTED"
                                   TO WS-CSV-ERROR
                           END-IF
                           MOVE "N" TO WS-FIELD-START
                       END-IF
                   WHEN OTHER
                       PERFORM 4000-APPEND-CHARACTER
                       MOVE "N" TO WS-FIELD-START
               END-EVALUATE
           END-IF.
      * 区切り文字は、新しいフィールドを開始します。空フィールドの場合も同様です。
       2300-START-NEXT-FIELD.
           ADD 1 TO WS-FIELD-NUMBER
           MOVE ZERO TO WS-FIELD-LENGTH
           MOVE "Y" TO WS-FIELD-START
           MOVE "N" TO WS-AFTER-QUOTE
           IF WS-FIELD-NUMBER > 5
               IF WS-CSV-ERROR = SPACES
                   MOVE "TOO_MANY_FIELDS" TO WS-CSV-ERROR
               END-IF
           END-IF.
      * 解析に成功したフィールドを保持し、長すぎる値は拒否します。
       4000-APPEND-CHARACTER.
           ADD 1 TO WS-FIELD-LENGTH
           IF WS-FIELD-NUMBER <= 5
               IF WS-FIELD-LENGTH <= 20
                   MOVE WS-CURRENT-CHAR TO
                       WS-FIELD-VALUE(WS-FIELD-NUMBER)(
                           WS-FIELD-LENGTH:1)
               ELSE
                   IF WS-CSV-ERROR = SPACES
                       MOVE "FIELD_TOO_LONG" TO WS-CSV-ERROR
                   END-IF
               END-IF
           ELSE
               IF WS-CSV-ERROR = SPACES
                   MOVE "TOO_MANY_FIELDS" TO WS-CSV-ERROR
               END-IF
           END-IF.
      * この入力行で最初に検出した解析エラーを保持します。
       2900-SET-UNCLOSED-QUOTE.
           IF WS-CSV-ERROR = SPACES
               MOVE "UNCLOSED_QUOTE" TO WS-CSV-ERROR
           END-IF.
       2910-SET-FIELD-COUNT-ERROR.
           IF WS-CSV-ERROR = SPACES
               MOVE "FIELD_COUNT" TO WS-CSV-ERROR
           END-IF.
       2920-SET-TRAILING-COMMA.
           IF WS-CSV-ERROR = SPACES
               MOVE "TRAILING_COMMA" TO WS-CSV-ERROR
           END-IF.
      * 構造と長さの両方が有効な場合に限り、解析した値を表示します。
       3000-REPORT-ROW.
           IF WS-CSV-ERROR = SPACES
               ADD 1 TO WS-VALID-COUNT
               DISPLAY "ROW=" WS-ROW-COUNT " STATUS=OK"
                   " ID=" FUNCTION TRIM(
                       WS-FIELD-VALUE(1) TRAILING)
                   " NAME=[" FUNCTION TRIM(
                       WS-FIELD-VALUE(2) TRAILING) "]"
                   " ACCOUNT=" FUNCTION TRIM(
                       WS-FIELD-VALUE(3) TRAILING)
                   " STATE=" FUNCTION TRIM(
                       WS-FIELD-VALUE(4) TRAILING)
                   " NOTE=[" FUNCTION TRIM(
                       WS-FIELD-VALUE(5) TRAILING) "]"
           ELSE
               ADD 1 TO WS-REJECTED-COUNT
               DISPLAY "ROW=" WS-ROW-COUNT
                   " STATUS=REJECTED REASON="
                   FUNCTION TRIM(WS-CSV-ERROR TRAILING)
           END-IF.
      * 引用符で囲まれたフィールド内のCSVのカンマはデータであり、区切り文字ではありません。
      * 引用符で囲まれたフィールド内の二重引用符は、引用符1文字を表します。
      * 引用符の有無にかかわらず、空フィールドの長さは0です。
      * このCSV仕様では、末尾のカンマを拒否します。
      * スキーマでは、有効な各行にフィールドがちょうど5個必要です。
      * 余分な区切り文字があると、領域を超過せずにTOO_MANY_FIELDSになります。
      * 最後のフィールド走査後、列数が足りない行はFIELD_COUNTになります。
      * 引用符でフィールドを開始できるのは、そのフィールドの最初の文字位置だけです。
      * 閉じ引用符の後に区切り文字以外の文字が続く場合、その行は拒否されます。
      * 閉じ引用符のない開始引用符はUNCLOSED_QUOTEになります。
      * 最初の解析エラーを、その行の拒否理由として保持します。
      * 各フィールドに格納できるのは最大20文字です。
      * 長すぎる値は黙って切り詰めず、拒否します。
      * 入力行領域に格納できるのは最大200文字です。
      * これより長い行順次レコードは、ランタイムによって切り詰められる場合があります。
      * この仕様では、引用符で囲まれたフィールド内の改行をサポートしません。
      * 閉じ引用符の前の空白は、フィールド値の一部として扱われます。
      * 最後のフィールドの末尾空白が重要な場合は、そのフィールドを引用符で囲んでください。
      * 引用符のない末尾空白は、FDのパディングと区別できません。
      * TRIMは、行の長さを測定して表示する際にFDのパディングを除去します。
      * フィクスチャには、有効、空、不正形式、境界値の例が含まれます。
      * このレッスンでは、入力の物理行1行をCSVレコード1件として扱います。
      * OPENの失敗は、レコードを読み取る前に報告されます。
      * EOFはCSVの行数に含めません。
      * このプログラムはCSVを読み取りますが、入力ファイルを変更も書き込みもしません。
      * 以降のレッスンでは、複数のファイルストリームを連携させます。
      * STOP RUNは、この1行CSV解析の演習を終了します。
