      * 第03课：入账交易并计算简单账户利息。
      * 这是教学示例，不是生产级计息系统。
      * 所有金额数据都在PICTURE中明确指定小数位。
      * 值由VALUE子句在WORKING-STORAGE中初始化。
      * COMPUTE执行算术运算并将结果写入字段。
      * MOVE复制值，不会对金额做加减。
      * 未指定ROUNDED时，多余小数位会被截断。
      * 单一账户和固定交易集使结果稳定。
      * 输出是账簿快照，不使用文件或操作员输入。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 今日示例交易处理前的账户期初余额。
      * 本课示例用两位小数表示分。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
      * 贷记会增加余额，但PIC不会执行入账。
      * 过程部中的COMPUTE才执行实际加法。
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.55.
      * 借记表示为待扣除的正数金额。
      * 业务方向由COMPUTE表达式决定。
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * 固定服务费也是待扣除的正数金额。
      * 本例未模拟货币兑换或税务规则。
       01 WS-SERVICE-FEE PIC 9(5)V99 VALUE 5.25.
      * 利率有四位小数；它不是“1.25%”这样的文本。
      * 示例直接应用0.0125一次，不作日计数调整。
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0125.
      * 此字段接收期初余额加贷记、减借记后的结果。
      * 其分级精度用于后续利息计算。
       01 WS-PRE-INTEREST-BALANCE PIC 9(7)V99 VALUE ZERO.
      * 保留四位小数以检查运算结果。
      * 目标字段精度决定保留多少位。
       01 WS-INTEREST-RAW PIC 9(5)V9999 VALUE ZERO.
      * MOVE到分精度演示不使用ROUNDED时降低精度。
      * 接收字段有两位小数，而非四位。
       01 WS-INTEREST-MOVE PIC 9(5)V99 VALUE ZERO.
      * 此处COMPUTE未使用ROUNDED也会截断。
      * 保留两个结果，便于比较两种语句。
       01 WS-INTEREST-TRUNC PIC 9(5)V99 VALUE ZERO.
      * ROUNDED要求按接收字段精度进行算术舍入。
      * GnuCOBOL默认采用远离零方向的最近值舍入。
       01 WS-INTEREST-ROUNDED PIC 9(5)V99 VALUE ZERO.
      * 入账时，期末余额使用舍入后的利息金额。
      * 这是练习中明确选定的示例业务规则。
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
      * 先计算交易金额处理后的余额。
      * 按语句顺序应用存款、取款和费用。
           COMPUTE WS-PRE-INTEREST-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT
                   - WS-WITHDRAWAL - WS-SERVICE-FEE.
      * 将分精度余额乘以四位小数利率。
      * 结果在此数据项中保留四位小数。
           COMPUTE WS-INTEREST-RAW =
               WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE.
      * MOVE将精度从四位小数变为两位。
      * MOVE不使用算术ROUNDED短语。
           MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE.
      * COMPUTE可将数值表达式赋给接收字段。
      * 未指定ROUNDED时，多余小数位会被截断。
           COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW.
      * ROUNDED只影响存入此接收字段的结果。
      * 源字段WS-INTEREST-RAW保持不变。
           COMPUTE WS-INTEREST-ROUNDED ROUNDED =
               WS-INTEREST-RAW.
      * 将选定的舍入金额入账至期末余额。
      * 本示例选择入账舍入后的金额。
           COMPUTE WS-CLOSING-BALANCE =
               WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED.
      * 先显示原始输入，再显示计算值。
           DISPLAY "OPENING-BALANCE=" WS-OPENING-BALANCE
           DISPLAY "DEPOSIT=" WS-DEPOSIT
           DISPLAY "WITHDRAWAL=" WS-WITHDRAWAL
           DISPLAY "SERVICE-FEE=" WS-SERVICE-FEE
           DISPLAY "PERIOD-RATE=" WS-PERIOD-RATE
      * 比较计息前余额与完整精度的利息结果。
           DISPLAY "PRE-INTEREST-BALANCE="
               WS-PRE-INTEREST-BALANCE
           DISPLAY "INTEREST-RAW-4DP=" WS-INTEREST-RAW
      * 以下输出展示MOVE和COMPUTE写入两位小数字段的结果。
           DISPLAY "INTEREST-MOVE-2DP=" WS-INTEREST-MOVE
           DISPLAY "INTEREST-COMPUTE-TRUNC=" WS-INTEREST-TRUNC
           DISPLAY "INTEREST-COMPUTE-ROUNDED="
               WS-INTEREST-ROUNDED
           DISPLAY "CLOSING-BALANCE=" WS-CLOSING-BALANCE
      * 每个显示金额都有明确声明的接收字段精度。
      * DISPLAY显示隐含小数点；PIC V不占存储位。
      * 此处COMPUTE表达式不会改变源金额。
      * MOVE语句只改变其接收数据项。
      * COMPUTE将结果存入等号左侧字段。
      * 接收字段过小可能触发尺寸错误条件。
      * ON SIZE ERROR可显式处理尺寸错误。
      * 示例值均适合声明的字段。
      * 实际批处理需要明确记录舍入和入账规则。
      * 本示例只处理一个账户，不读取外部文件。
      * 交易验证和拒绝路径将在后续课程介绍。
      * 段落、循环和条件也将在后续课程讲解。
      * 显示计算结果后，STOP RUN结束示例程序。
           STOP RUN.
