      * Lesson 18: validate and parse one-line CSV customer records.
      * 第18课：验证并解析每行一条的CSV客户记录。
      * レッスン18：1行1件のCSV顧客レコードを検証して解析します。
      * The five fields are ID, name, account, status, and note.
      * 五个字段依次为ID、姓名、账户、状态和备注。
      * 5つのフィールドはID、名前、口座、ステータス、備考です。
      * Quoted commas and doubled quotes are parsed as field content.
      * 引号内的逗号和成对转义的引号会作为字段内容解析。
      * 引用符内のカンマと二重引用符は、フィールドの内容として解析されます。
      * Empty fields are preserved; fields longer than 20 are rejected.
      * 空字段会保留；长度超过20的字段会被拒绝。
      * 空フィールドは保持され、20文字を超えるフィールドは拒否されます。
      * Each CSV record occupies one physical line in this profile.
      * 此配置中，每条CSV记录占用一个物理行。
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
      * Read and validate all physical CSV lines in file order.
      * 按文件顺序读取并验证所有CSV物理行。
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
      * Reset parser state before each independent input row.
      * 处理每条独立输入行前重置解析器状态。
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
      * Apply quote and comma rules to the current character.
      * 根据当前字符应用引号和逗号规则。
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
      * A doubled quote contributes one quote to a quoted value.
      * 成对的引号在带引号的值中表示一个引号。
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
      * Outside quotes, commas end fields and quotes start fields.
      * 在引号外，逗号结束字段，引号则开始带引号的字段。
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
      * A delimiter begins a new field, including an empty field.
      * 分隔符会开始一个新字段，包括空字段。
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
      * Preserve valid parsed fields and reject oversized values.
      * 保留解析有效的字段，并拒绝超长值。
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
      * Keep the first detected parser error for this input row.
      * 保留此输入行中最先检测到的解析错误。
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
      * Display parsed values only when structure and sizes are valid.
      * 只有结构和长度都有效时才显示解析值。
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
      * CSV commas inside quoted fields are data, not delimiters.
      * 带引号字段内的CSV逗号属于数据，不是分隔符。
      * 引用符で囲まれたフィールド内のCSVのカンマはデータであり、区切り文字ではありません。
      * A doubled quote inside a quoted field represents one quote.
      * 带引号字段内的成对引号表示一个引号。
      * 引用符で囲まれたフィールド内の二重引用符は、引用符1文字を表します。
      * An empty unquoted or quoted field has a length of zero.
      * 无论字段是否带引号，空字段的长度都是零。
      * 引用符の有無にかかわらず、空フィールドの長さは0です。
      * A trailing comma is rejected by this CSV profile.
      * 此CSV配置会拒绝行尾逗号。
      * このCSV仕様では、末尾のカンマを拒否します。
      * The schema requires exactly five fields in every valid row.
      * 模式要求每条有效行恰好包含五个字段。
      * スキーマでは、有効な各行にフィールドがちょうど5個必要です。
      * An extra delimiter produces TOO_MANY_FIELDS without overflow.
      * 额外的分隔符会触发TOO_MANY_FIELDS，且不会溢出。
      * 余分な区切り文字があると、領域を超過せずにTOO_MANY_FIELDSになります。
      * A short row produces FIELD_COUNT after the final field scan.
      * 字段扫描结束后，字段不足的行会触发FIELD_COUNT。
      * 最後のフィールド走査後、列数が足りない行はFIELD_COUNTになります。
      * A quote may only open a field at its first character.
      * 引号只能出现在字段首字符位置以开启引用字段。
      * 引用符でフィールドを開始できるのは、そのフィールドの最初の文字位置だけです。
      * Non-delimiter text after a closing quote is rejected.
      * 结束引号后若出现非分隔符文本，则该行会被拒绝。
      * 閉じ引用符の後に区切り文字以外の文字が続く場合、その行は拒否されます。
      * An unmatched opening quote produces UNCLOSED_QUOTE.
      * 未匹配的起始引号会触发UNCLOSED_QUOTE。
      * 閉じ引用符のない開始引用符はUNCLOSED_QUOTEになります。
      * The first parser error is retained as the row's reject reason.
      * 首个解析错误会作为该行的拒绝原因保留。
      * 最初の解析エラーを、その行の拒否理由として保持します。
      * Each field stores at most 20 characters.
      * 每个字段最多存储20个字符。
      * 各フィールドに格納できるのは最大20文字です。
      * Longer values are rejected rather than silently truncated.
      * 超长值会被拒绝，不会静默截断。
      * 長すぎる値は黙って切り詰めず、拒否します。
      * The input line area holds at most 200 characters.
      * 输入行区域最多容纳200个字符。
      * 入力行領域に格納できるのは最大200文字です。
      * Longer line-sequential records may be truncated by the runtime.
      * 更长的行顺序记录可能会被运行时截断。
      * これより長い行順次レコードは、ランタイムによって切り詰められる場合があります。
      * This profile does not support newlines inside quoted fields.
      * 此配置不支持带引号字段内的换行符。
      * この仕様では、引用符で囲まれたフィールド内の改行をサポートしません。
      * Spaces before a closing quote remain part of the field value.
      * 结束引号前的空格仍属于字段值。
      * 閉じ引用符の前の空白は、フィールド値の一部として扱われます。
      * Quote final fields when their trailing spaces are significant.
      * 若最后一个字段的尾随空格有意义，请用引号括起该字段。
      * 最後のフィールドの末尾空白が重要な場合は、そのフィールドを引用符で囲んでください。
      * Unquoted trailing spaces are indistinguishable from FD padding.
      * 未加引号的尾随空格无法与FD填充空格区分。
      * 引用符のない末尾空白は、FDのパディングと区別できません。
      * TRIM removes FD padding when measuring and displaying a row.
      * TRIM会在测量和显示行时去除FD填充空格。
      * TRIMは、行の長さを測定して表示する際にFDのパディングを除去します。
      * The fixture has valid, empty, malformed, and boundary examples.
      * 样例包含有效、空、格式错误和边界示例。
      * フィクスチャには、有効、空、不正形式、境界値の例が含まれます。
      * A physical input line is one CSV record for this lesson.
      * 本课将一个物理输入行视为一条CSV记录。
      * このレッスンでは、入力の物理行1行をCSVレコード1件として扱います。
      * OPEN failure is reported before any record is read.
      * OPEN失败会在读取任何记录之前报告。
      * OPENの失敗は、レコードを読み取る前に報告されます。
      * EOF is not counted as a CSV row.
      * EOF不计作CSV行。
      * EOFはCSVの行数に含めません。
      * This program reads CSV but does not change or write the input.
      * 此程序读取CSV，但不会更改或写入输入文件。
      * このプログラムはCSVを読み取りますが、入力ファイルを変更も書き込みもしません。
      * Later lessons will coordinate multiple file streams.
      * 后续课程将协调多个文件流。
      * 以降のレッスンでは、複数のファイルストリームを連携させます。
      * STOP RUN ends the one-line CSV parsing exercise.
      * STOP RUN结束此单行CSV解析练习。
      * STOP RUNは、この1行CSV解析の演習を終了します。
