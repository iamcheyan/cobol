      *第 09 课：将一个帐户交易组织为层次结构。
      *组项包含相关的从属数据项。
      *基本项有自己的 PIC 并存储字段值。
      *01 记录对客户、帐户和交易详细信息进行分组。
      *级别编号标识每个父子层级关系。
      *同一级别的项目是兄弟项目；儿童水平必须提高。
      *该示例使用固定值并且不执行外部输入。
      *重复的 STATUS 名称需要父项限定。
      *组显示是为了观察而显示，而不是作为文件契约。
      *本课程中未使用 OCCURS 或 REDEFINES 子句。
      *记录组可以包含组和基本字段。
      *组名称提供从记录到字段的路径。
      *此示例使用级别 01、05 和 10。
      *兄弟小组使用相同的 05 级别编号。
      *客户和帐户标识符是文本键。
      *帐号中的前导零仍然很重要。
      *与文本标识符不同，金额是数字。
      *尽管名称相同，状态字段仍显示不同的角色。
      *声明顺序决定了每个字段在组中的位置。
      *父名称将业务上下文添加到基本字段名称中。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *01 级记录包含三个业务子组。
       01 WS-TRANSACTION-RECORD.
      *客户字段属于一个 05 级别组。
          05 WS-CUSTOMER-INFO.
      *基本项目带有 PIC 条款和初始样本值。
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
      *帐户身份和帐户状态共享此父级。
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
      *下面也使用了 STATUS，因此引用限定了其父级。
             10 WS-STATUS PIC X VALUE "A".
      *交易详细信息在同一记录中形成单独的组。
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
      *V 给出了金额隐含的两位小数。
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
       PROCEDURE DIVISION.
      *显示每个基本字段及其业务标签。
           DISPLAY "CUSTOMER ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "CUSTOMER NAME="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "ACCOUNT NUMBER="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
      *限定符选择预期的 STATUS 基本项。
           DISPLAY "ACCOUNT STATUS=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "TRANSACTION ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "TRANSACTION CODE=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "TRANSACTION AMOUNT="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "TRANSACTION STATUS=" WS-STATUS OF WS-TXN-INFO
      *组显示公开其连续的从属内容。
      *它在字段之间不添加分隔符并省略隐含的 V。
           DISPLAY "GROUP DATA=[" WS-TRANSACTION-RECORD "]"
           STOP RUN.
      *WS-TRANSACTION-RECORD 是顶级记录组。
      *WS-CUSTOMER-INFO、WS-ACCOUNT-INFO 和 WS-TXN-INFO 是组。
      *WS-CUSTOMER-ID 和 WS-TXN-AMOUNT 是基本数据项。
      *一个群体有孩子；它没有基本的 PIC 条款。
      *每个基本 PIC 定义类、宽度和小数位。
      *01级开始记录；以下05项就属于它。
      *10 级项目属于最近的前 05 个父项。
      *缩进可以帮助读者看到嵌套的级别。
      *COBOL 使用级别编号而不是缩进来定义父子层级。
      *该组的子级按声明顺序占用存储空间。
      *组数据连接子内容而不使用分隔符。
      *金额字段在单独引用时显示为 00125.50。
      *在组显示中其数字字符显示为0012550。
      *隐含的小数点不存储为组字符。
      *该演示不是便携式交换格式。
      *直接引用时，金额仍然是数字。
      *用其父组限定重复的名称。
      *帐户状态是 WS-ACCOUNT-INFO 下的一个字符。
      *事务状态在 WS-TXN-INFO 下有七个字符。
      *资格决定名字；它不会重命名该字段。
      *可以显示叶子而不显示其父组。
      *可以在没有限定符的情况下引用唯一的字段名称。
      *此示例使用限定符来消除 STATUS 的歧义。
      *一个记录定义可以包含多个相关组件。
      *组不验证状态或事务代码值。
      *此 01 项是样本的工作存储记录。
      *文件记录使用FILE SECTION中的相关定义。
      *文件布局详细信息到达文件处理阶段。
      *这里的每个字段都由其基本 VALUE 子句初始化。
      *该程序中组本身没有 VALUE 子句。
      *这里不使用文件、表、循环、输入或算术。
      *下一课将展示使用 REDEFINES 的替代视图。
      *后面的课程将使用 OCCURS 进行重复记录。
      *分组项目使逻辑记录更易于导航和查看。
      *他们不验证字段内容或强制执行业务规则。
      *STOP RUN 结束该数据结构演示。
