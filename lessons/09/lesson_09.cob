      * Lesson 09: organize one account transaction as a hierarchy.
      * 第 09 课：将一个帐户交易组织为层次结构。
      * レッスン 09: 1 つのアカウント トランザクションを階層として編成します。
      * A group item contains related subordinate data items.
      * 组项包含相关的从属数据项。
      * グループ項目には、関連する従属データ項目が含まれます。
      * An elementary item has its own PIC and stores a field value.
      * 基本项有自己的 PIC 并存储字段值。
      * 基本項目には独自の PIC があり、フィールド値が格納されます。
      * The 01 record groups customer, account, and transaction details.
      * 01 记录对客户、帐户和交易详细信息进行分组。
      * 01 レコードは、顧客、アカウント、トランザクションの詳細をグループ化します。
      * Level numbers identify each parent-child relationship.
      * 级别编号标识每个亲子关系。
      * レベル番号は各親子関係を識別します。
      * Same-level items are siblings; child levels must increase.
      * 同一级别的项目是兄弟项目；儿童水平必须提高。
      * 同じレベルのアイテムは兄弟です。子供のレベルを上げる必要があります。
      * This sample uses fixed values and performs no external input.
      * 该示例使用固定值并且不执行外部输入。
      * このサンプルでは固定値を使用し、外部入力は行いません。
      * Duplicate STATUS names need parent qualification.
      * 重复的 STATUS 名称需要家长资格。
      * 重複する STATUS 名には親修飾が必要です。
      * Group display is shown for observation, not as a file contract.
      * 组显示是为了观察而显示，而不是作为文件契约。
      * グループ表示は、ファイル契約としてではなく、観察のために表示されます。
      * No OCCURS or REDEFINES clause is used in this lesson.
      * 本课程中未使用 OCCURS 或 REDEFINES 子句。
      * このレッスンでは、OCCURS 句または REDEFINES 句は使用されません。
      * A record group can contain groups and elementary fields.
      * 记录组可以包含组和基本字段。
      * レコード グループには、グループと基本フィールドを含めることができます。
      * Group names provide a path from the record to a field.
      * 组名称提供从记录到字段的路径。
      * グループ名は、レコードからフィールドへのパスを提供します。
      * This sample uses levels 01, 05, and 10.
      * 此示例使用级别 01、05 和 10。
      * このサンプルではレベル 01、05、10 を使用します。
      * Sibling subgroups use the same 05 level number.
      * 兄弟小组使用相同的 05 级别编号。
      * 兄弟サブグループは同じ 05 レベル番号を使用します。
      * Customer and account identifiers are text keys.
      * 客户和帐户标识符是文本键。
      * 顧客およびアカウントの識別子はテキスト キーです。
      * Leading zeroes remain significant in the account number.
      * 帐号中的前导零仍然很重要。
      * アカウント番号の先頭のゼロは引き続き重要です。
      * The amount is numeric, unlike its text identifiers.
      * 与文本标识符不同，金额是数字。
      * 金額はテキスト識別子とは異なり、数値です。
      * Status fields show separate roles despite a shared name.
      * 尽管名称相同，状态字段仍显示不同的角色。
      * ステータス フィールドには、名前が共有されているにもかかわらず、別々の役割が表示されます。
      * Declaration order determines each field's place in the group.
      * 声明顺序决定了每个字段在组中的位置。
      * 宣言の順序によって、グループ内の各フィールドの位置が決まります。
      * Parent names add business context to elementary field names.
      * 父名称将业务上下文添加到基本字段名称中。
      * 親名は、基本フィールド名にビジネス コンテキストを追加します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The 01-level record contains three business subgroups.
      * 01 级记录包含三个业务子组。
      * 01 レベルのレコードには 3 つのビジネス サブグループが含まれています。
       01 WS-TRANSACTION-RECORD.
      * Customer fields belong together under one 05-level group.
      * 客户字段属于一个 05 级别组。
      * 顧客フィールドは、1 つの 05 レベルのグループにまとめて属します。
          05 WS-CUSTOMER-INFO.
      * Elementary items carry PIC clauses and initial sample values.
      * 基本项目带有 PIC 条款和初始样本值。
      * 基本項目には PIC 句と初期サンプル値が含まれます。
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
      * Account identity and account status share this parent.
      * 帐户身份和帐户状态共享此父级。
      * アカウント ID とアカウント ステータスはこの親を共有します。
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
      * STATUS is also used below, so references qualify its parent.
      * 下面也使用了 STATUS，因此引用限定了其父级。
      * STATUS は以下でも使用されるため、参照はその親を修飾します。
             10 WS-STATUS PIC X VALUE "A".
      * Transaction details form a separate group in the same record.
      * 交易详细信息在同一记录中形成单独的组。
      * トランザクションの詳細は、同じレコード内の別のグループを形成します。
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
      * V gives the amount two implied decimal positions.
      * V 给出了金额隐含的两位小数。
      * V は、金額に暗黙の小数点以下 2 桁を与えます。
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
       PROCEDURE DIVISION.
      * Display each elementary field with its business label.
      * 显示每个基本字段及其业务标签。
      * 各基本フィールドをビジネス ラベルとともに表示します。
           DISPLAY "CUSTOMER ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "CUSTOMER NAME="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "ACCOUNT NUMBER="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
      * Qualifiers choose the intended STATUS elementary item.
      * 限定符选择预期的 STATUS 基本项。
      * 修飾子は、目的の STATUS 基本項目を選択します。
           DISPLAY "ACCOUNT STATUS=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "TRANSACTION ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "TRANSACTION CODE=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "TRANSACTION AMOUNT="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "TRANSACTION STATUS=" WS-STATUS OF WS-TXN-INFO
      * A group display exposes its contiguous subordinate contents.
      * 组显示公开其连续的从属内容。
      * グループ表示では、その連続した従属コンテンツが公開されます。
      * It adds no separators between fields and omits the implied V.
      * 它在字段之间不添加分隔符并省略隐含的 V。
      * フィールド間に区切り文字は追加されず、暗黙の V が省略されます。
           DISPLAY "GROUP DATA=[" WS-TRANSACTION-RECORD "]"
           STOP RUN.
      * WS-TRANSACTION-RECORD is the top-level record group.
      * WS-TRANSACTION-RECORD 是顶级记录组。
      * WS-TRANSACTION-RECORD は最上位のレコード グループです。
      * WS-CUSTOMER-INFO, WS-ACCOUNT-INFO, and WS-TXN-INFO are groups.
      * WS-CUSTOMER-INFO、WS-ACCOUNT-INFO 和 WS-TXN-INFO 是组。
      * WS-CUSTOMER-INFO、WS-ACCOUNT-INFO、および WS-TXN-INFO はグループです。
      * WS-CUSTOMER-ID and WS-TXN-AMOUNT are elementary data items.
      * WS-CUSTOMER-ID 和 WS-TXN-AMOUNT 是基本数据项。
      * WS-CUSTOMER-ID および WS-TXN-AMOUNT は基本データ項目です。
      * A group has children; it does not have an elementary PIC clause.
      * 一个群体有孩子；它没有基本的 PIC 条款。
      * グループには子がいます。基本的な PIC 句はありません。
      * Each elementary PIC defines class, width, and decimal scale.
      * 每个基本 PIC 定义类、宽度和小数位。
      * 各基本 PIC は、クラス、幅、および小数位取りを定義します。
      * Level 01 begins a record; the following 05 items belong to it.
      * 01级开始记录；以下05项就属于它。
      * レベル 01 がレコードを開始します。以下の05アイテムが該当します。
      * Level 10 items belong to the most recent preceding 05 parent.
      * 10 级项目属于最近的前 05 个父项。
      * レベル 10 の項目は、直前の 05 の親に属します。
      * Indentation helps readers see the nested levels.
      * 缩进可以帮助读者看到嵌套的级别。
      * インデントにより、読者はネストされたレベルを確認することができます。
      * COBOL uses level numbers, not indentation, to define parentage.
      * COBOL 使用级别编号而不是缩进来定义出身。
      * COBOL では、親子関係を定義するためにインデントではなくレベル番号を使用します。
      * The group's children occupy storage in declaration order.
      * 该组的子级按声明顺序占用存储空间。
      * グループの子は宣言順にストレージを占有します。
      * Group data joins child contents without delimiters.
      * 组数据连接子内容而不使用分隔符。
      * グループ データは、区切り文字なしで子コンテンツを結合します。
      * The amount field displays as 00125.50 when referenced by itself.
      * 金额字段在单独引用时显示为 00125.50。
      * 金額フィールドを単独で参照すると、00125.50 と表示されます。
      * In the group display its digit characters appear as 0012550.
      * 在组显示中其数字字符显示为0012550。
      * グループ表示では、その数字文字は 0012550 として表示されます。
      * The implied decimal point is not stored as a group character.
      * 隐含的小数点不存储为组字符。
      * 暗黙の小数点はグループ文字として保存されません。
      * This demonstration is not a portable interchange format.
      * 该演示不是便携式交换格式。
      * このデモンストレーションは、ポータブルな交換形式ではありません。
      * The amount remains numeric when referenced directly.
      * 直接引用时，金额仍然是数字。
      * 直接参照しても、金額は数値のままです。
      * Qualify repeated names with their parent group.
      * 用其父组限定重复的名称。
      * 繰り返される名前はその親グループで修飾されます。
      * Account STATUS is one character under WS-ACCOUNT-INFO.
      * 帐户状态是 WS-ACCOUNT-INFO 下的一个字符。
      * アカウントのステータスは、WS-ACCOUNT-INFO の下の 1 文字です。
      * Transaction STATUS is seven characters under WS-TXN-INFO.
      * 事务状态在 WS-TXN-INFO 下有七个字符。
      * トランザクション STATUS は、WS-TXN-INFO の下の 7 文字です。
      * Qualification resolves a name; it does not rename the field.
      * 资格决定名字；它不会重命名该字段。
      * 資格によって名前が解決されます。フィールドの名前は変更されません。
      * A leaf can be displayed without displaying its parent group.
      * 可以显示叶子而不显示其父组。
      * 親グループを表示せずにリーフを表示できます。
      * A unique field name can be referenced without a qualifier.
      * 可以在没有限定符的情况下引用唯一的字段名称。
      * 一意のフィールド名は修飾子なしで参照できます。
      * This sample uses qualifiers to disambiguate STATUS.
      * 此示例使用限定符来消除 STATUS 的歧义。
      * このサンプルでは、​​修飾子を使用して STATUS を明確にします。
      * One record definition can contain multiple related components.
      * 一个记录定义可以包含多个相关组件。
      * 1 つのレコード定義に複数の関連コンポーネントを含めることができます。
      * A group does not validate status or transaction-code values.
      * 组不验证状态或事务代码值。
      * グループはステータスまたはトランザクション コードの値を検証しません。
      * This 01 item is a working-storage record for the sample.
      * 此 01 项是样本的工作存储记录。
      * この 01 アイテムは、サンプルの作業用ストレージ レコードです。
      * File records use related definitions in the FILE SECTION.
      * 文件记录使用FILE SECTION中的相关定义。
      * ファイル レコードは、ファイル セクション内の関連定義を使用します。
      * File layout details arrive in the file-processing phase.
      * 文件布局详细信息到达文件处理阶段。
      * ファイル レイアウトの詳細は、ファイル処理フェーズで到着します。
      * Every field here is initialized by its elementary VALUE clause.
      * 这里的每个字段都由其基本 VALUE 子句初始化。
      * ここのすべてのフィールドは、基本的な VALUE 句によって初期化されます。
      * The group itself has no VALUE clause in this program.
      * 该程序中组本身没有 VALUE 子句。
      * このプログラムにはグループ自体に VALUE 句がありません。
      * No file, table, loop, input, or arithmetic is used here.
      * 这里不使用文件、表、循环、输入或算术。
      * ここでは、ファイル、テーブル、ループ、入力、または算術演算は使用されません。
      * The next lesson will show alternate views using REDEFINES.
      * 下一课将展示使用 REDEFINES 的替代视图。
      * 次のレッスンでは、REDEFINES を使用した代替ビューを示します。
      * Later lessons will use OCCURS for repeated records.
      * 后面的课程将使用 OCCURS 进行重复记录。
      * 後のレッスンでは、繰り返しの記録に OCCURS を使用します。
      * Group items make a logical record easier to navigate and review.
      * 分组项目使逻辑记录更易于导航和查看。
      * グループ項目を使用すると、論理レコードの移動と確認が容易になります。
      * They do not validate field contents or enforce business rules.
      * 他们不验证字段内容或强制执行业务规则。
      * フィールドの内容を検証したり、ビジネス ルールを適用したりすることはありません。
      * STOP RUN ends this data-structure demonstration.
      * STOP RUN 结束该数据结构演示。
      * STOP RUN はこのデータ構造のデモを終了します。
