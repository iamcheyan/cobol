      * 因此，最后一个索引为零，不处理任何样本记录。
      * 处理后的计数记录实际运行了多少个循环体。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
      * 处理后的计数与循环索引分开。
       PROCEDURE DIVISION.
           DISPLAY "最后样例编号=" WS-LAST-SAMPLE
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
               EVALUATE WS-SAMPLE-INDEX
                   WHEN 1
                       DISPLAY "样例=001 代码=D 金额=125.50"
                   WHEN 2
                       DISPLAY "样例=002 代码=W 金额=040.10"
                   WHEN 3
                       DISPLAY "样例=003 代码=T 金额=075.00"
                   WHEN OTHER
                       DISPLAY "样例=UNMAPPED"
               END-EVALUATE
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
           DISPLAY "已处理样例数=" WS-PROCESSED-COUNT
      * 超过三的限制也会执行未映射的样本分支。
      * 最后一个索引为零，初始测试已经正确。
      * 样本计数与配置的最后一个索引是分开的。
           STOP RUN.
