       IDENTIFICATION DIVISION.
       PROGRAM-ID. INPUTCSV.
       AUTHOR. TEST-DEVELOPER.
      *
      *  input.txt を読み込み output.csv を作成するサンプル。
      *  入力形式: 社員番号|氏名|年齢|給与
      *  例      : 00001|Taro Yamada|28|350000
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. LINUX-X86-64.
       OBJECT-COMPUTER. LINUX-X86-64.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE ASSIGN TO "input.txt"
               FILE STATUS IS WS-INPUT-STATUS
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OUTPUT-FILE ASSIGN TO "output.csv"
               FILE STATUS IS WS-OUTPUT-STATUS
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  INPUT-FILE.
       01  INPUT-RECORD                 PIC X(256).

       FD  OUTPUT-FILE.
       01  OUTPUT-RECORD                PIC X(256).

       WORKING-STORAGE SECTION.
      * --- 文件状态区 ---
       01  WS-FILE-STATUS.
           05  WS-INPUT-STATUS          PIC XX.
               88  INPUT-OK             VALUE "00".
               88  INPUT-EOF            VALUE "10".
           05  WS-OUTPUT-STATUS         PIC XX.
               88  OUTPUT-OK            VALUE "00".

      * --- 控制标志与计数器 ---
       01  WS-FLAGS.
           05  WS-EOF-FLAG              PIC X VALUE "N".
               88  EOF-YES              VALUE "Y".
               88  EOF-NO               VALUE "N".
           05  WS-CONVERT-FLAG          PIC X VALUE "N".
               88  CONVERT-SUCCESS      VALUE "S".
               88  CONVERT-ERROR        VALUE "E".

       01  WS-COUNTERS.
           05  WS-RECORD-COUNT          PIC 9(5) COMP VALUE ZERO.
           05  WS-ERROR-COUNT           PIC 9(5) COMP VALUE ZERO.
           05  WS-TOTAL-SALARY          PIC S9(9) COMP-3 VALUE ZERO.
           05  WS-FIELD-COUNT           PIC 99 VALUE ZERO.

      * --- 输入字段分解工作区 ---
       01  WS-INPUT-FIELDS.
           05  IN-EMPLOYEE-ID           PIC X(20).
           05  IN-NAME-GROUP.
               10  IN-FULL-NAME         PIC X(80).
               10  NAME-LENGTH          PIC 99.
           05  IN-AGE                   PIC X(10).
           05  IN-SALARY                PIC X(30).
           05  CSV-LINE                 PIC X(256).

      * --- 外部 COPYBOOK 引入 (用于测试 copybook 导航) ---
       COPY "EMP-REC.CPY".

       PROCEDURE DIVISION.
      *================================================================*
      * 主控制逻辑 (Main Control Logic)                                *
      *================================================================*
       0000-MAIN-LOGIC SECTION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-FILE
           PERFORM 9000-FINALIZE
           STOP RUN.

      *================================================================*
      * 1000: 初始化与文件打开                                         *
      *================================================================*
       1000-INIT-SECTION SECTION.
       1000-INITIALIZE.
           INITIALIZE WS-FLAGS WS-COUNTERS
           OPEN INPUT INPUT-FILE
                OUTPUT OUTPUT-FILE

           IF NOT INPUT-OK
               DISPLAY "入力ファイル OPEN ERROR=" WS-INPUT-STATUS
               GO TO 9999-ERROR-EXIT
           END-IF

           IF NOT OUTPUT-OK
               DISPLAY "出力ファイル OPEN ERROR=" WS-OUTPUT-STATUS
               CLOSE INPUT-FILE
               GO TO 9999-ERROR-EXIT
           END-IF

           MOVE "employee_id,name,age,salary" TO OUTPUT-RECORD
           WRITE OUTPUT-RECORD.

      *================================================================*
      * 2000: 循环读取与处理文件记录                                   *
      *================================================================*
       2000-PROCESS-SECTION SECTION.
       2000-PROCESS-FILE.
           PERFORM UNTIL EOF-YES
               READ INPUT-FILE
                   AT END
                       SET EOF-YES TO TRUE
                   NOT AT END
                       PERFORM 2100-PROCESS-RECORD
               END-READ
           END-PERFORM.

       2100-PROCESS-RECORD.
           IF INPUT-RECORD = SPACES
               GO TO 2199-PROCESS-RECORD-EXIT
           END-IF

           PERFORM 3000-PARSE-RECORD
           IF CONVERT-SUCCESS
               PERFORM 4000-FORMAT-AND-WRITE
               ADD 1 TO WS-RECORD-COUNT
           ELSE
               ADD 1 TO WS-ERROR-COUNT
           END-IF.

       2199-PROCESS-RECORD-EXIT.
           EXIT.

      *================================================================*
      * 3000: 解析与拆分字段                                           *
      *================================================================*
       3000-PARSE-SECTION SECTION.
       3000-PARSE-RECORD.
           INITIALIZE WS-INPUT-FIELDS
           MOVE ZERO TO WS-FIELD-COUNT

           UNSTRING INPUT-RECORD
               DELIMITED BY "|"
               INTO IN-EMPLOYEE-ID
                    IN-FULL-NAME
                    IN-AGE
                    IN-SALARY
               TALLYING IN WS-FIELD-COUNT
           END-UNSTRING

           IF WS-FIELD-COUNT = 4
               SET CONVERT-SUCCESS TO TRUE
           ELSE
               DISPLAY "不正な行: " INPUT-RECORD
               SET CONVERT-ERROR TO TRUE
           END-IF.

      *================================================================*
      * 4000: 格式化 CSV 并写入输出                                    *
      *================================================================*
       4000-WRITE-SECTION SECTION.
       4000-FORMAT-AND-WRITE.
           COMPUTE NAME-LENGTH =
               FUNCTION LENGTH(FUNCTION TRIM(IN-FULL-NAME))

           STRING FUNCTION TRIM(IN-EMPLOYEE-ID) DELIMITED BY SIZE
                  "," DELIMITED BY SIZE
                  QUOTE DELIMITED BY SIZE
                  IN-FULL-NAME(1:NAME-LENGTH) DELIMITED BY SIZE
                  QUOTE DELIMITED BY SIZE
                  "," DELIMITED BY SIZE
                  FUNCTION TRIM(IN-AGE) DELIMITED BY SIZE
                  "," DELIMITED BY SIZE
                  FUNCTION TRIM(IN-SALARY) DELIMITED BY SIZE
                  INTO CSV-LINE
           END-STRING

           MOVE CSV-LINE TO OUTPUT-RECORD
           WRITE OUTPUT-RECORD.

      *================================================================*
      * 9000: 正常收尾与异常退出                                       *
      *================================================================*
       9000-FINALIZE-SECTION SECTION.
       9000-FINALIZE.
           CLOSE INPUT-FILE OUTPUT-FILE
           DISPLAY "変換完了: output.csv"
           DISPLAY "処理件数: " WS-RECORD-COUNT
           DISPLAY "エラー件数: " WS-ERROR-COUNT.

       9999-ERROR-EXIT.
           DISPLAY "異常終了しました。"
           STOP RUN.
