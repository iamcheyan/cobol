      * 第 06 课：使用 PERFORM VARYING 处理固定序列。
      * 三个样本记录演示了重复的顺序处理。
      * EVALUATE 为每个固定样本选择详细信息。
      * 它不使用表格；表存储将在后面的课程中介绍。
      * 循环索引从 1 开始，每次迭代增加 1。
      * UNTIL index > last 表示包含最后一个索引。
      * 循环在每次迭代之前检查其 UNTIL 条件。
      * 因此，最后一个索引为零，不处理任何样本记录。
      * 处理后的计数记录实际运行了多少个循环体。
      * 此演示不读取输入文件或数据库。
      * IDENTIFICATION DIVISION 标记该程序的源身份。
      * PROGRAM-ID 命名这个独立程序。
      * DATA DIVISION 声明过程使用的存储空间。
      * WORKING-STORAGE 在程序执行期间保留初始值。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 对于完整的固定样本序列，设置为 3。
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
      * VARYING 在第一次测试之前初始化该索引。
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
      * 每处理一个样本，该计数器就会增加一次。
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
      * LAST-SAMPLE 控制循环的包含上限。
      * VARYING 通过其 FROM 和 BY 子句更改索引。
      * 处理后的计数与循环索引分开。
      * 这些 PIC 9 字段是无符号整数计数器。
       PROCEDURE DIVISION.
      * 显示配置的包含最终样本数。
           DISPLAY "LAST-SAMPLE=" WS-LAST-SAMPLE
      * 将样本编号从 1 迭代到配置的最后一个。
      * 循环之前的显示还公开了零迭代运行。
      * FROM 为本次执行提供索引的初始值。
      * BY 提供在完成的循环体之后添加的步骤。
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
      * EVALUATE 将每个循环编号映射到其固定样本值。
               EVALUATE WS-SAMPLE-INDEX
      * 示例之一是存款交易。
                   WHEN 1
                       DISPLAY "SAMPLE=001 CODE=D AMOUNT=125.50"
      * 示例二是取款交易。
                   WHEN 2
                       DISPLAY "SAMPLE=002 CODE=W AMOUNT=040.10"
      * 样本三是一笔转账交易。
                   WHEN 3
                       DISPLAY "SAMPLE=003 CODE=T AMOUNT=075.00"
      * 在样本三之后，更高的限制到达此分支。
                   WHEN OTHER
                       DISPLAY "SAMPLE=UNMAPPED"
               END-EVALUATE
      * 样本分支完成后进行计数。
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
      * 在另一次迭代开始之前测试循环条件。
      * 每个 WHEN 发出一个采样行并继续循环体。
      * COMPUTE 在样本分支之后递增计数。
      * END-PERFORM 报告最终计数后的 DISPLAY。
      * 显示实际通过 UNTIL 测试的迭代次数。
           DISPLAY "SAMPLES-PROCESSED=" WS-PROCESSED-COUNT
      * 索引在第一个大于 LAST-SAMPLE 的值处停止。
      * 超过三的限制也会执行未映射的样本分支。
      * 此循环不使用表或文件作为其输入源。
      * 对于每个接受的索引，PERFORM 主体完成一次。
      * VARYING 在主体完成后推进索引。
      * 下一个 UNTIL 测试看到递增的索引。
      * 对于最后一个示例三，包括索引一、二和三。
      * 索引四满足>三并结束该样本循环。
      * 最后一个索引为零，初始测试已经正确。
      * 在这种情况下，循环体将被跳过并且计数保持为零。
      * 最后一个索引 1 处理一项，然后在两项处停止。
      * 三个以上的最后一个样本达到 WHEN OTHER 以获得额外索引。
      * 此示例公开了该边界，而不是隐藏额外的工作。
      * END-PERFORM 关闭内联循环的语句范围。
      * END-EVALUATE 关闭每次迭代内的样本选择。
      * 每个显示的样本都是从其当前循环索引中选择的。
      * 计数使用前面课程中介绍的 COMPUTE 语法。
      * 循环内不会出现任何句点来提前结束 PERFORM。
      * 最后的 STOP RUN 周期结束循环后的句子。
      * EVALUATE 通过索引将样本详细信息保存在一起。
      * 后面的课程将这些记录存储为重复的表条目。
      * 后面的课程将这项工作移至指定段落中。
      * 生产批次还验证记录并处理错误。
      * 此示例使用一个小的已知限制和固定值。
      * 交易按输入顺序显示；不执行任何排序。
      * 该循环是顺序的、单线程的。
      * 没有过帐余额，也没有更改任何交易。
      * 代码和金额文本是标签，而不是算术操作数。
      * 样本计数与配置的最后一个索引是分开的。
      * 这种区别让输出报告完成的迭代。
      * 已处理计数的初始值为零。
      * 计数器仅在示例分支执行后才会更改。
      * 如果主体不运行，则初始零保持不变。
      * 编译器检查循环控制和分支结构。
      * 运行边界练习以验证观察到的计数。
      * 将最后一个样本恢复为默认示例的三个。
      * STOP RUN 结束该固定序列演示。
           STOP RUN.
