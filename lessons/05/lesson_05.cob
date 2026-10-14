      * Lesson 05: classify one transaction code with EVALUATE.
      * 第 05 课：使用 EVALUATE 对一个事务代码进行分类。
      * レッスン 05: EVALUATE を使用して 1 つのトランザクション コードを分類します。
      * Three known codes are deposit, withdrawal, and transfer.
      * 三个已知的代码是存款、取款和转账。
      * 既知の 3 つのコードは、入金、出金、および送金です。
      * A single subject is compared with the WHEN choices in order.
      * 单个主题与 WHEN 选项按顺序进行比较。
      * 単一の主題が WHEN の選択肢と順番に比較されます。
      * The selected branch reports a category and a business action.
      * 所选分支报告类别和业务操作。
      * 選択したブランチは、カテゴリとビジネス アクションをレポートします。
      * WHEN OTHER handles any code without a named WHEN alternative.
      * WHEN OTHER 处理没有指定 WHEN 替代项的任何代码。
      * WHEN OTHER は、名前付き WHEN 代替を使用せずにあらゆるコードを処理します。
      * The sample value is fixed so output remains repeatable.
      * 样本值是固定的，因此输出保持可重复。
      * サンプル値は固定されているため、出力は再現可能です。
      * This lesson classifies a transaction; it does not post it.
      * 本课对交易进行分类；它不会发布它。
      * このレッスンではトランザクションを分類します。それは投稿しません。
      * No account balance or external file is read or changed.
      * 不会读取或更改帐户余额或外部文件。
      * アカウント残高や外部ファイルの読み取りや変更は行われません。
      * Use code values defined by the interface contract in production.
      * 在生产中使用接口契约定义的代码值。
      * 運用環境ではインターフェイス コントラクトによって定義されたコード値を使用します。
      * Unknown codes must be visible for rejection or review.
      * 未知代码必须可见，以便拒绝或审查。
      * 不明なコードは、拒否またはレビューのために表示される必要があります。
      * IDENTIFICATION names the program that owns this source file.
      * IDENTIFICATION 命名拥有此源文件的程序。
      * IDENTIFICATION は、このソース ファイルを所有するプログラムの名前を指定します。
      * PROGRAM-ID gives the compiler a stable program name.
      * PROGRAM-ID 为编译器提供了稳定的程序名称。
      * PROGRAM-ID は、コンパイラに安定したプログラム名を与えます。
      * DATA DIVISION declares values used by the procedure.
      * DATA DIVISION 声明过程使用的值。
      * DATA DIVISION は、プロシージャで使用される値を宣言します。
      * WORKING-STORAGE keeps these sample values during this run.
      * WORKING-STORAGE 在此运行期间保留这些样本值。
      * WORKING-STORAGE は、この実行中にこれらのサンプル値を保持します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVAL05.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * This reference identifies the fixed example transaction.
      * 该参考标识固定示例交易。
      * このリファレンスでは、修正されたトランザクションの例を示します。
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * A text reference preserves letters and leading zeroes.
      * 文本引用保留字母和前导零。
      * テキスト参照では、文字と先頭のゼロが保持されます。
      * PIC X defines storage shape, not a permitted-code list.
      * PIC X 定义存储形状，而不是允许的代码列表。
      * PIC X は、許可されたコード リストではなく、ストレージの形状を定義します。
      * VALUE initializes the sample transaction code before execution.
      * VALUE 在执行之前初始化示例事务代码。
      * VALUE は、実行前にサンプル トランザクション コードを初期化します。
      * The code is one character in the teaching interface.
      * 该代码是教学界面中的一个字符。
      * コードはティーチングインターフェース内の 1 文字です。
      * D means deposit; W means withdrawal; T means transfer.
      * D表示存款； W表示退出； T表示转移。
      * D はデポジットを意味します。 W は撤退を意味します。 Tは転送を意味します。
      * Any other value must fall through to WHEN OTHER.
      * 任何其他值都必须传递给 WHEN OTHER。
      * 他の値は WHEN OTHER に該当する必要があります。
       01 WS-TRANSACTION-CODE PIC X VALUE "D".
      * One character is enough for this deliberately small code set.
      * 对于这个特意小的代码集来说，一个字符就足够了。
      * この意図的に小さなコード セットには 1 文字で十分です。
       PROCEDURE DIVISION.
      * Display the input before classifying its code.
      * 在对其代码进行分类之前显示输入。
      * コードを分類する前に入力を表示します。
           DISPLAY "TRANSACTION-REFERENCE="
               WS-TRANSACTION-REFERENCE
           DISPLAY "TRANSACTION-CODE=" WS-TRANSACTION-CODE
      * DISPLAY adds the field contents after each output label.
      * DISPLAY 在每个输出标签后添加字段内容。
      * DISPLAY は、各出力ラベルの後にフィールドの内容を追加します。
      * Stable labels make the four code paths easy to compare.
      * 稳定的标签使四个代码路径易于比较。
      * ラベルが安定しているため、4 つのコード パスを簡単に比較できます。
      * EVALUATE checks one transaction code against its WHEN choices.
      * EVALUATE 根据其 WHEN 选择检查一个事务代码。
      * EVALUATE は、1 つのトランザクション コードを WHEN の選択と照合してチェックします。
      * The subject is one character data item, not a condition.
      * 主语是一个字符数据项，而不是一个条件。
      * 件名は条件ではなく、1 つの文字データ項目です。
      * Quoted WHEN literals compare character values exactly.
      * 带引号的 WHEN 文字精确比较字符值。
      * 引用符で囲まれた WHEN リテラルは文字値を正確に比較します。
           EVALUATE WS-TRANSACTION-CODE
      * Deposits increase an account balance in a later processing step.
      * 存款会在后续处理步骤中增加账户余额。
      * 入金により、後の処理ステップで口座残高が増加します。
               WHEN "D"
                   DISPLAY "CATEGORY=DEPOSIT"
                   DISPLAY "ACTION=ADD_TO_ACCOUNT"
      * This label classifies D without changing a balance.
      * 该标签将 D 类分类而不改变天平。
      * このラベルはバランスを変えずに D を分類します。
      * Withdrawals decrease an account balance in a later step.
      * 提款会在后续步骤中减少账户余额。
      * 引き出しにより、後のステップでアカウント残高が減少します。
               WHEN "W"
                   DISPLAY "CATEGORY=WITHDRAWAL"
                   DISPLAY "ACTION=SUBTRACT_FROM_ACCOUNT"
      * W has a distinct classification and action from D.
      * W 具有与 D 不同的分类和作用。
      * W には D とは異なる分類とアクションがあります。
      * Transfers require source and destination account processing.
      * 转账需要源账户和目标账户处理。
      * 送金には、送金元と送金先のアカウント処理が必要です。
               WHEN "T"
                   DISPLAY "CATEGORY=TRANSFER"
                   DISPLAY "ACTION=PROCESS_BOTH_ACCOUNTS"
      * T identifies a transfer requiring both account identifiers.
      * T 标识需要两个账户标识符的转账。
      * T は、両方のアカウント ID を必要とする転送を示します。
      * Every unlisted value is explicitly marked for review.
      * 每个未列出的值都被明确标记以供审查。
      * リストされていない値はすべて、レビュー対象として明示的にマークされています。
      * The fallback keeps unsupported codes visible in output.
      * 后备使不支持的代码在输出中可见。
      * フォールバックにより、サポートされていないコードが出力に表示されたままになります。
               WHEN OTHER
                   DISPLAY "CATEGORY=UNKNOWN"
                   DISPLAY "ACTION=REJECT_FOR_REVIEW"
           END-EVALUATE
      * This control statement does not change the input code.
      * 该控制语句不会改变输入代码。
      * この制御ステートメントは入力コードを変更しません。
      * The action label describes future work; it does not perform it.
      * 行动标签描述了未来的工作；它不执行它。
      * アクションラベルは将来の作業を説明します。それは実行しません。
      * Keep valid code values synchronized with the feed contract.
      * 保持有效代码值与 Feed 合同同步。
      * 有効なコード値をフィード コントラクトと同期させます。
      * Add a WHEN branch only after confirming its business meaning.
      * 确认其业务含义后才添加WHEN分支。
      * WHEN 分岐は、ビジネス上の意味を確認した後に追加してください。
      * END-EVALUATE ends the multiway selection statement.
      * END-EVALUATE 结束多路选择语句。
      * END-EVALUATE は、多方向選択ステートメントを終了します。
      * Only the matching WHEN branch runs for this subject value.
      * 仅匹配的 WHEN 分支针对此主题值运行。
      * このサブジェクト値に対しては、一致する WHEN 分岐のみが実行されます。
      * WHEN OTHER runs only if no earlier WHEN choice matches.
      * 仅当没有较早的 WHEN 选择匹配时，WHEN OTHER 才会运行。
      * WHEN OTHER は、以前の WHEN 選択が一致しない場合にのみ実行されます。
      * Branches are not processed by falling through from one to next.
      * 分支不是通过从一个分支到下一个分支来处理的。
      * 分岐は、次から次へのフォールスルーによって処理されません。
      * The reference and code are input data, not output categories.
      * 参考和代码是输入数据，而不是输出类别。
      * リファレンスとコードは入力データであり、出力カテゴリではありません。
      * Code matching is an exact character comparison in this example.
      * 在此示例中，代码匹配是精确的字符比较。
      * この例では、コード マッチングは文字の正確な比較です。
      * Lowercase d is not the uppercase code D used by the contract.
      * 小写的 d 不是合约使用的大写代码 D。
      * 小文字の d は、契約で使用される大文字のコード D ではありません。
      * If lowercase is permitted, normalize it in a later lesson.
      * 如果允许小写，请在后面的课程中将其标准化。
      * 小文字が許可されている場合は、後のレッスンで正規化します。
      * Do not invent extra aliases without agreement from the producer.
      * 未经制作人同意，请勿发明额外的别名。
      * 制作者の同意なしに余分なエイリアスを作成しないでください。
      * Each category maps to one declared business action label.
      * 每个类别都映射到一个已声明的业务操作标签。
      * 各カテゴリは、宣言された 1 つのビジネス アクション ラベルにマップされます。
      * The action labels document intent; they do not move money.
      * 该操作标记文档意图；他们不转移资金。
      * アクションは文書の意図にラベルを付けます。彼らはお金を動かしません。
      * A transfer action needs both source and destination identifiers.
      * 传输操作需要源标识符和目标标识符。
      * 転送アクションには、送信元と宛先の両方の識別子が必要です。
      * Unknown codes must never be silently interpreted as deposits.
      * 切勿将未知代码默默地解释为存款。
      * 未知のコードを黙って預金として解釈してはなりません。
      * Production feeds need documented code ownership and versions.
      * 生产源需要记录代码所有权和版本。
      * 実稼働フィードには、コードの所有権とバージョンを文書化する必要があります。
      * Define whether blank codes are missing or malformed.
      * 定义空白代码是否缺失或格式错误。
      * 空白コードが欠落しているか、または不正な形式であるかどうかを定義します。
      * Log the transaction reference with each rejection reason.
      * 记录交易参考以及每个拒绝原因。
      * 各拒否理由とともにトランザクション参照を記録します。
      * A new code needs an agreed category and action mapping.
      * 新代码需要商定的类别和操作映射。
      * 新しいコードには、合意されたカテゴリとアクションのマッピングが必要です。
      * Exact matching means lowercase d does not match uppercase D.
      * 精确匹配意味着小写 d 与大写 D 不匹配。
      * 完全一致とは、小文字の d が大文字の D と一致しないことを意味します。
      * The exercise changes one code at a time to isolate its path.
      * 该练习一次更改一个代码以隔离其路径。
      * この演習では、一度に 1 つのコードを変更して、そのパスを分離します。
      * This one-record example has no count, loop, or file handling.
      * 这个单记录示例没有计数、循环或文件处理。
      * この 1 レコードの例には、カウント、ループ、ファイル処理はありません。
      * PERFORM will later repeat processing for a sequence of records.
      * PERFORM 稍后将重复处理一系列记录。
      * PERFORM は後で一連のレコードの処理を繰り返します。
      * Paragraphs will later separate classification from main flow.
      * 段落稍后会将分类与主流分开。
      * 段落は後で分類をメインフローから分離します。
      * IF from the previous lesson handles conditions and boundaries.
      * 上一课中的 IF 处理条件和边界。
      * 前のレッスンの IF は条件と境界を処理します。
      * EVALUATE makes a fixed set of alternatives easy to scan.
      * EVALUATE 使一组固定的替代方案易于扫描。
      * EVALUATE を使用すると、固定された選択肢のセットを簡単にスキャンできます。
      * WHEN choices should be mutually meaningful and easy to audit.
      * 何时选择应该是互惠互利且易于审核的。
      * WHEN の選択は相互に意味があり、監査が簡単である必要があります。
      * WHEN OTHER makes the default path visible to maintainers.
      * WHEN OTHER 使默认路径对维护者可见。
      * WHEN OTHER は、デフォルトのパスをメンテナに表示します。
      * This statement is one sentence terminated by the final period.
      * 该陈述是一个以最后一个句号结束的句子。
      * このステートメントは最後のピリオドで終わる 1 つの文です。
      * END-EVALUATE closes the scope before the program ends.
      * END-EVALUATE 在程序结束之前关闭作用域。
      * END-EVALUATE は、プログラムが終了する前にスコープを閉じます。
      * The display output is stable for scripted learning checks.
      * 显示输出对于脚本学习检查来说是稳定的。
      * 表示出力は、スクリプト化された学習チェックでは安定しています。
      * Change the code VALUE and rerun to exercise each branch.
      * 更改代码 VALUE 并重新运行以练习每个分支。
      * コード VALUE を変更して再実行し、各分岐を実行します。
      * Restore the original value before comparing the next branch.
      * 在比较下一个分支之前恢复原始值。
      * 次の分岐を比較する前に、元の値を復元します。
      * The branch displays exactly one category and one action.
      * 该分支仅显示一种类别和一种操作。
      * このブランチには、カテゴリとアクションが 1 つだけ表示されます。
      * No data item changes during this example's execution.
      * 在此示例执行期间，没有数据项发生更改。
      * この例の実行中にデータ項目は変更されません。
      * STOP RUN ends this single-transaction demonstration.
      * STOP RUN 结束该单事务演示。
      * STOP RUN は、この単一トランザクションのデモを終了します。
           STOP RUN.
