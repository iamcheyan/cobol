      * 第18课：验证并解析每行一条的CSV客户记录。
      * 五个字段依次为ID、姓名、账户、状态和备注。
      * 引号内的逗号和成对转义的引号会作为字段内容解析。
      * 空字段会保留；长度超过20的字段会被拒绝。
      * 此配置中，每条CSV记录占用一个物理行。
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
      * 按文件顺序读取并验证所有CSV物理行。
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
      * 处理每条独立输入行前重置解析器状态。
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
      * 根据当前字符应用引号和逗号规则。
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
      * 成对的引号在带引号的值中表示一个引号。
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
      * 在引号外，逗号结束字段，引号则开始带引号的字段。
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
      * 分隔符会开始一个新字段，包括空字段。
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
      * 保留解析有效的字段，并拒绝超长值。
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
      * 保留此输入行中最先检测到的解析错误。
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
      * 只有结构和长度都有效时才显示解析值。
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
      * 带引号字段内的CSV逗号属于数据，不是分隔符。
      * 带引号字段内的成对引号表示一个引号。
      * 无论字段是否带引号，空字段的长度都是零。
      * 此CSV配置会拒绝行尾逗号。
      * 模式要求每条有效行恰好包含五个字段。
      * 额外的分隔符会触发TOO_MANY_FIELDS，且不会溢出。
      * 字段扫描结束后，字段不足的行会触发FIELD_COUNT。
      * 引号只能出现在字段首字符位置以开启引用字段。
      * 结束引号后若出现非分隔符文本，则该行会被拒绝。
      * 未匹配的起始引号会触发UNCLOSED_QUOTE。
      * 首个解析错误会作为该行的拒绝原因保留。
      * 每个字段最多存储20个字符。
      * 超长值会被拒绝，不会静默截断。
      * 输入行区域最多容纳200个字符。
      * 更长的行顺序记录可能会被运行时截断。
      * 此配置不支持带引号字段内的换行符。
      * 结束引号前的空格仍属于字段值。
      * 若最后一个字段的尾随空格有意义，请用引号括起该字段。
      * 未加引号的尾随空格无法与FD填充空格区分。
      * TRIM会在测量和显示行时去除FD填充空格。
      * 样例包含有效、空、格式错误和边界示例。
      * 本课将一个物理输入行视为一条CSV记录。
      * OPEN失败会在读取任何记录之前报告。
      * EOF不计作CSV行。
      * 此程序读取CSV，但不会更改或写入输入文件。
      * 后续课程将协调多个文件流。
      * STOP RUN结束此单行CSV解析练习。
