      * 第 05 课：使用 EVALUATE 对一个事务代码进行分类。
      * 三个已知的代码是存款、取款和转账。
      * 单个主题与 WHEN 选项按顺序进行比较。
      * 所选分支报告类别和业务操作。
      * WHEN OTHER 处理没有指定 WHEN 替代项的任何代码。
      * 样本值是固定的，因此输出保持可重复。
      * 本课对交易进行分类；它不会发布它。
      * 不会读取或更改帐户余额或外部文件。
      * 在生产中使用接口契约定义的代码值。
      * 未知代码必须可见，以便拒绝或审查。
      * IDENTIFICATION 命名拥有此源文件的程序。
      * PROGRAM-ID 为编译器提供了稳定的程序名称。
      * DATA DIVISION 声明过程使用的值。
      * WORKING-STORAGE 在此运行期间保留这些样本值。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 该参考号标识这笔固定的示例交易。
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * 文本引用保留字母和前导零。
      * PIC X 定义存储形状，而不是允许的代码列表。
      * VALUE 在执行之前初始化示例事务代码。
      * 该代码是教学界面中的一个字符。
      * D表示存款； W表示取款； T表示转账。
      * 任何其他值都会匹配 WHEN OTHER。
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
      * 对于这个特意小的代码集来说，一个字符就足够了。
       PROCEDURE DIVISION.
      * 在对其代码进行分类之前显示输入。
           DISPLAY "TRANSACTION-REFERENCE="
               WS-TRANSACTION-REFERENCE
           DISPLAY "TRANSACTION-CODE=" WS-TRANSACTION-CODE
      * DISPLAY 在每个输出标签后添加字段内容。
      * 稳定的标签使四个代码路径易于比较。
      * EVALUATE 根据其 WHEN 选择检查一个事务代码。
      * 主语是一个字符数据项，而不是一个条件。
      * 带引号的 WHEN 文字精确比较字符值。
           EVALUATE WS-TRANSACTION-CODE
      * 存款会在后续处理步骤中增加账户余额。
               WHEN "D"
                   DISPLAY "CATEGORY=DEPOSIT"
                   DISPLAY "ACTION=ADD_TO_ACCOUNT"
      * 该标签将 D 类分类而不改变天平。
      * 提款会在后续步骤中减少账户余额。
               WHEN "W"
                   DISPLAY "CATEGORY=WITHDRAWAL"
                   DISPLAY "ACTION=SUBTRACT_FROM_ACCOUNT"
      * W 具有与 D 不同的分类和作用。
      * 转账需要源账户和目标账户处理。
               WHEN "T"
                   DISPLAY "CATEGORY=TRANSFER"
                   DISPLAY "ACTION=PROCESS_BOTH_ACCOUNTS"
      * T 标识需要两个账户标识符的转账。
      * 每个未列出的值都被明确标记以供审查。
      * 后备使不支持的代码在输出中可见。
               WHEN OTHER
                   DISPLAY "CATEGORY=UNKNOWN"
                   DISPLAY "ACTION=REJECT_FOR_REVIEW"
           END-EVALUATE
      * 此控制语句不会修改输入代码。
      * 行动标签描述了未来的工作；它不执行它。
      * 确保有效代码值与数据接口约定保持一致。
      * 确认其业务含义后才添加WHEN分支。
      * END-EVALUATE 结束多路选择语句。
      * 仅匹配的 WHEN 分支针对此主题值运行。
      * 仅当没有较早的 WHEN 选择匹配时，WHEN OTHER 才会运行。
      * 分支不是通过从一个分支到下一个分支来处理的。
      * 参考和代码是输入数据，而不是输出类别。
      * 在此示例中，代码匹配是精确的字符比较。
      * 小写的 d 不是合约使用的大写代码 D。
      * 如果允许小写，请在后面的课程中将其标准化。
      * 未经制作人同意，请勿发明额外的别名。
      * 每个类别都映射到一个已声明的业务操作标签。
      * 操作标签用于说明意图；本例不会实际转移资金。
      * 转账操作需要来源账户和目标账户标识。
      * 切勿将未知代码默默地解释为存款。
      * 生产数据接口需要记录代码定义的责任方和版本。
      * 定义空白代码是否缺失或格式错误。
      * 记录交易参考以及每个拒绝原因。
      * 新代码需要商定的类别和操作映射。
      * 精确匹配意味着小写 d 与大写 D 不匹配。
      * 该练习一次更改一个代码以隔离其路径。
      * 这个单记录示例没有计数、循环或文件处理。
      * PERFORM 稍后将重复处理一系列记录。
      * 后续课程会用段落将分类逻辑与主流程分开。
      * 上一课中的 IF 处理条件和边界。
      * EVALUATE 使一组固定的替代方案易于扫描。
      * 各个 WHEN 选项应表达清晰且便于审查的不同业务类别。
      * WHEN OTHER 使默认路径对维护者可见。
      * 该陈述是一个以最后一个句号结束的句子。
      * END-EVALUATE 在程序结束之前关闭作用域。
      * 显示输出对于脚本学习检查来说是稳定的。
      * 更改代码 VALUE 并重新运行以练习每个分支。
      * 在比较下一个分支之前恢复原始值。
      * 该分支仅显示一种类别和一种操作。
      * 在此示例执行期间，没有数据项发生更改。
      * STOP RUN 结束该单事务演示。
           STOP RUN.
