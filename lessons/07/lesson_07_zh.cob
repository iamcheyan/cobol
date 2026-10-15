      * 第 07 课：将一批组织成命名的 COBOL 段落。
      * 主要段落执行初始化、处理和终结。
      * 每个命名段落都拥有批处理流程的一个阶段。
      * PERFORM 返回被调用段落之后的语句。
      * 段落名称写在固定格式源的A区。
      * STOP RUN 可以防止落入后面的段落定义。
      * 此示例使用早期的 MOVE 和 COMPUTE 语句。
      * 它不包含循环、表或文件操作。
      * 值是固定的，因此可以在输出中检查调用顺序。
      * 段落使该流程更易于定位和维护。
      * PROGRAM-ID 设置编译器使用的程序名称。
      * 从 PROCEDURE DIVISION 中的第一段开始执行。
      * Main 协调各个阶段，但不包含其工作。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARAGRAPH07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 开仓金额和样本交易是固定输入。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 125.50.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * 结果在第一个执行的段落中初始化。
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
      * 所有金额字段都使用相同的两位小数刻度。
      * VALUE 提供固定示例而不是外部输入。
      * 处理前期末余额从零开始。
       PROCEDURE DIVISION.
      * 程序从第一个过程段落开始执行。
       0000-MAIN.
      * 调用按初始化、处理和完成的顺序运行。
      * 每个调用都会运行一个命名段落并返回到这一点。
      * 这些是过程调用，而不是内联 PERFORM 循环块。
      * 每个目标在源代码后面都有一个段落定义。
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
      * 此显示证明控制权已返回到主段落。
      * STOP RUN 防止普通流程进入段落定义。
      * Main是这个独立程序使用的入口路径。
           DISPLAY "批次=COMPLETE"
      * STOP RUN 在执行进入定义之前结束 main。
           STOP RUN.
      * 初始化阶段准备输出字段以进行处理。
       1000-INITIALIZE.
           DISPLAY "阶段=INITIALIZE"
           MOVE ZERO TO WS-CLOSING-BALANCE.
      * 处理阶段根据固定输入计算结果。
       2000-PROCESS.
           DISPLAY "阶段=PROCESS"
           COMPUTE WS-CLOSING-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT - WS-WITHDRAWAL
           DISPLAY "期末余额=" WS-CLOSING-BALANCE.
      * Finalize 阶段报告已完成的批次结果。
       9000-FINALIZE.
           DISPLAY "阶段=FINALIZE"
           DISPLAY "最终余额=" WS-CLOSING-BALANCE.
      * 每个 PERFORM 都针对该程序中的一个指定段落。
      * 段落以下一个名称或程序段结尾处结束。
      * 到达段落末尾将控制权返回给调用者。
      * 段落不是单独的程序或过程。
      * PERFORM 不会创建新的 WORKING-STORAGE 副本。
      * 所有四个数据项仍然保留在这里的共享程序存储。
      * 主要段落是顶级序列协调器。
      * 初始化在算术处理阶段之前。
      * 终结仅在流程段落返回后运行。
      * 计算后显示平仓金额。
      * 此示例中的段落名称使用数字前缀。
      * 前缀可以将相关工作分组到较大的批处理程序中。
      * 确切的命名方案是团队约定，而不是语法。
      * 这些段落名称在该程序中是唯一的。
      * 段落标签在固定格式源中从区域 A 开始。
      * 过程语句及其周期放置在 B 区。
      * 句点结束当前 COBOL 语句及其开放范围。
      * MOVE 期间结束初始化段落的句子。
      * DISPLAY 期间结束过程段落的句子。
      * 最后的 DISPLAY 周期结束了 Finalize 段落的句子。
      * Main 在下一段标签之前以 STOP RUN 结束。
      * 这可以防止普通流意外进入某个阶段。
      * PERFORM 调用一个段落并在该程序内返回。
      * 在后面的课程中，将 CALL 用于单独编译的程序。
      * 后面的课程将段落与重复处理结合起来。
      * 本课特意保留每个阶段的一次执行。
      * MOVE 仅更改期末余额接收字段。
      * COMPUTE 将期初余额加上贷记金额，再减去借记金额，并将结果存入该字段。
      * 预期算术结果为 1000.00 + 125.50 - 40.10。
      * 段落顺序显示为三个 STAGE 输出行。
      * 省略 PERFORM 调用会删除该阶段的输出。
      * 重新排序调用会更改可见阶段顺序。
      * 不会从终端或外部文件读取任何输入值。
      * 是否调用这三个段落不会触发任何条件分支。
      * 主要报告最终确定返回后的批次完成情况。
      * 最后一段并不终止程序本身。
      * 控制返回到主程序，其中 STOP RUN 终止执行。
      * 这种分离有助于独立测试和审查每个阶段。
      * 它还提供了后续文件课程也会为各阶段的文件处理提供明确位置。
      * 将计算保留在处理阶段，而不是最终报告。
      * 在消耗结果的任何阶段之前保持初始化。
      * 该示例的每个段落都包含一个结尾句子。
      * 显示的收盘值确认了共享数据的可见性。
      * STOP RUN 结束本段组织演示。
