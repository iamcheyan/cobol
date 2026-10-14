      * Lesson 07: organize one batch into named COBOL paragraphs.
      * 第 07 课：将一批组织成命名的 COBOL 段落。
      * レッスン 07: 1 つのバッチを名前付き COBOL 段落に編成します。
      * The main paragraph performs initialize, process, and finalize.
      * 主要段落执行初始化、处理和终结。
      * メイン段落では、初期化、処理、およびファイナライズを実行します。
      * Each named paragraph owns one stage of the batch flow.
      * 每个命名段落都拥有批处理流程的一个阶段。
      * 名前付き段落はそれぞれ、バッチ フローの 1 つのステージを所有します。
      * PERFORM returns to the statement after the called paragraph.
      * PERFORM 返回被调用段落之后的语句。
      * PERFORM は、呼び出された段落の後のステートメントに戻ります。
      * Paragraph names are written in Area A of fixed-format source.
      * 段落名称写在固定格式源的A区。
      * 段落名は定型ソースのA領域に記述されます。
      * STOP RUN prevents falling into later paragraph definitions.
      * STOP RUN 可以防止落入后面的段落定义。
      * STOP RUN は、後の段落定義に陥ることを防ぎます。
      * This example uses earlier MOVE and COMPUTE statements.
      * 此示例使用早期的 MOVE 和 COMPUTE 语句。
      * この例では、以前の MOVE ステートメントと COMPUTE ステートメントを使用します。
      * It does not contain a loop, table, or file operation.
      * 它不包含循环、表或文件操作。
      * ループ、テーブル、ファイル操作は含まれません。
      * Values are fixed so the call order can be checked in output.
      * 值是固定的，因此可以在输出中检查调用顺序。
      * 値は固定されているため、出力で呼び出し順序を確認できます。
      * Paragraphs make this flow easier to locate and maintain.
      * 段落使该流程更易于定位和维护。
      * 段落を使用すると、このフローを見つけて維持しやすくなります。
      * PROGRAM-ID sets the program name used by the compiler.
      * PROGRAM-ID 设置编译器使用的程序名称。
      * PROGRAM-ID は、コンパイラが使用するプログラム名を設定します。
      * Execution starts at the first paragraph in PROCEDURE DIVISION.
      * 从 PROCEDURE DIVISION 中的第一段开始执行。
      * 実行は PROCEDURE DIVISION の最初の段落から開始されます。
      * Main coordinates the stages but does not contain their work.
      * Main 协调各个阶段，但不包含其工作。
      * Main はステージを調整しますが、その作業は含まれません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PARAGRAPH07.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The opening amount and sample transactions are fixed inputs.
      * 开仓金额和样本交易是固定输入。
      * 開始金額とサンプル取引は固定入力です。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 125.50.
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * The result is initialized in the first performed paragraph.
      * 结果在第一个执行的段落中初始化。
      * 結果は、最初に実行された段落で初期化されます。
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
      * All amount fields use the same two-decimal scale.
      * 所有金额字段都使用相同的两位小数刻度。
      * すべての金額フィールドでは同じ小数第 2 位を使用します。
      * VALUE supplies fixed examples rather than external input.
      * VALUE 提供固定示例而不是外部输入。
      * VALUE は、外部入力ではなく固定サンプルを提供します。
      * The closing balance starts at zero before processing.
      * 处理前期末余额从零开始。
      * 処理前の期末残高はゼロから始まります。
       PROCEDURE DIVISION.
      * Program execution begins at the first procedure paragraph.
      * 程序从第一个过程段落开始执行。
      * プログラムの実行は最初のプロシージャ段落から始まります。
       0000-MAIN.
      * Calls run in initialize, process, and finalize order.
      * 调用按初始化、处理和完成的顺序运行。
      * 呼び出しは、初期化、処理、終了の順序で実行されます。
      * Each call runs a named paragraph and returns to this point.
      * 每个调用都会运行一个命名段落并返回到这一点。
      * 各呼び出しでは、名前付き段落が実行され、この時点に戻ります。
      * These are procedural calls, not inline PERFORM loop blocks.
      * 这些是过程调用，而不是内联 PERFORM 循环块。
      * これらは手続き型呼び出しであり、インライン PERFORM ループ ブロックではありません。
      * Each target has a paragraph definition later in the source.
      * 每个目标在源代码后面都有一个段落定义。
      * 各ターゲットには、ソースの後半に段落定義があります。
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS
           PERFORM 9000-FINALIZE
      * This display proves control returned to the main paragraph.
      * 此显示证明控制权已返回到主段落。
      * この表示は、制御がメインの段落に戻ったことを証明します。
      * STOP RUN prevents ordinary flow into paragraph definitions.
      * STOP RUN 防止普通流程进入段落定义。
      * STOP RUN は、段落定義への通常の流れを防ぎます。
      * Main is the entry path used by this standalone program.
      * Main是这个独立程序使用的入口路径。
      * Main は、このスタンドアロン プログラムによって使用されるエントリ パスです。
           DISPLAY "BATCH=COMPLETE"
      * STOP RUN ends main before execution can fall into definitions.
      * STOP RUN 在执行进入定义之前结束 main。
      * STOP RUN は、実行が定義に入る前に main を終了します。
           STOP RUN.
      * Initialize stage prepares the output field for processing.
      * 初始化阶段准备输出字段以进行处理。
      * 初期化ステージでは、出力フィールドの処理を準備します。
       1000-INITIALIZE.
           DISPLAY "STAGE=INITIALIZE"
           MOVE ZERO TO WS-CLOSING-BALANCE.
      * Process stage calculates the result from the fixed inputs.
      * 处理阶段根据固定输入计算结果。
      * プロセス ステージでは、固定入力から結果を計算します。
       2000-PROCESS.
           DISPLAY "STAGE=PROCESS"
           COMPUTE WS-CLOSING-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT - WS-WITHDRAWAL
           DISPLAY "CLOSING-BALANCE=" WS-CLOSING-BALANCE.
      * Finalize stage reports the completed batch result.
      * Finalize 阶段报告已完成的批次结果。
      * Finalize ステージでは、完了したバッチ結果がレポートされます。
       9000-FINALIZE.
           DISPLAY "STAGE=FINALIZE"
           DISPLAY "FINAL-BALANCE=" WS-CLOSING-BALANCE.
      * Each PERFORM targets one named paragraph in this program.
      * 每个 PERFORM 都针对该程序中的一个指定段落。
      * 各 PERFORM は、このプログラム内の 1 つの名前付き段落を対象としています。
      * A paragraph ends at the next name or end of procedure division.
      * 段落以下一个名称或程序段结尾处结束。
      * 段落は次の名前または手続き部の終わりで終了します。
      * Reaching the paragraph end returns control to the caller.
      * 到达段落末尾将控制权返回给调用者。
      * 段落の終わりに到達すると、呼び出し元に制御が戻ります。
      * A paragraph is not a separate program or process.
      * 段落不是单独的程序或过程。
      * 段落は別個のプログラムやプロセスではありません。
      * PERFORM does not create a new WORKING-STORAGE copy.
      * PERFORM 不会创建新的 WORKING-STORAGE 副本。
      * PERFORM は、新しい WORKING-STORAGE コピーを作成しません。
      * All four data items remain shared program storage here.
      * 所有四个数据项仍然保留在这里的共享程序存储。
      * 4 つのデータ項目はすべて、ここでの共有プログラム ストレージのままです。
      * The main paragraph is the top-level sequence coordinator.
      * 主要段落是顶级序列协调器。
      * メイン段落は、トップレベルのシーケンス コーディネーターです。
      * Initialization precedes the arithmetic processing stage.
      * 初始化在算术处理阶段之前。
      * 初期化は演算処理段階に先立って行われます。
      * Finalization runs only after the process paragraph returns.
      * 终结仅在流程段落返回后运行。
      * ファイナライゼーションは、プロセス段落が戻った後にのみ実行されます。
      * The closing amount is displayed after it has been calculated.
      * 计算后显示平仓金额。
      * 最終金額は計算後に表示されます。
      * Paragraph names in this sample use numeric prefixes.
      * 此示例中的段落名称使用数字前缀。
      * このサンプルの段落名には数値の接頭辞が使用されています。
      * Prefixes can group related work in a larger batch program.
      * 前缀可以将相关工作分组到较大的批处理程序中。
      * プレフィックスを使用すると、関連する作業をより大きなバッチ プログラムにグループ化できます。
      * The exact naming scheme is a team convention, not syntax.
      * 确切的命名方案是团队约定，而不是语法。
      * 正確な命名スキームは、構文ではなくチームの規則です。
      * These paragraph names are unique within this program.
      * 这些段落名称在该程序中是唯一的。
      * これらの段落名は、このプログラム内で一意です。
      * A paragraph label starts in Area A in fixed-format source.
      * 段落标签在固定格式源中从区域 A 开始。
      * 段落ラベルは、固定形式ソースの領域 A から始まります。
      * Procedure statements and their periods are placed in Area B.
      * 过程语句及其周期放置在 B 区。
      * 手続きステートメントとそのピリオドは領域 B に配置されます。
      * A period ends the current COBOL sentence and its open scopes.
      * 句点结束当前 COBOL 语句及其开放范围。
      * 現在の COBOL 文とその開いているスコープはピリオドで終了します。
      * The MOVE period ends the initialize paragraph's sentence.
      * MOVE 期间结束初始化段落的句子。
      * MOVE 期間は、初期化段落の文を終了します。
      * The DISPLAY period ends the process paragraph's sentence.
      * DISPLAY 期间结束过程段落的句子。
      * DISPLAY ピリオドはプロセス段落の文を終了します。
      * The final DISPLAY period ends the finalize paragraph's sentence.
      * 最后的 DISPLAY 周期结束了 Finalize 段落的句子。
      * 最後の DISPLAY ピリオドは、finalize 段落の文を終了します。
      * Main ends with STOP RUN before the next paragraph label.
      * Main 在下一段标签之前以 STOP RUN 结束。
      * メインは、次の段落ラベルの前に STOP RUN で終了します。
      * This prevents ordinary flow entering a stage by accident.
      * 这可以防止普通流意外进入某个阶段。
      * これにより、通常のフローが誤ってステージに入るのを防ぎます。
      * PERFORM calls a paragraph and returns within this program.
      * PERFORM 调用一个段落并在该程序内返回。
      * PERFORM は段落を呼び出し、このプログラム内で戻ります。
      * Use CALL for a separately compiled program in a later lesson.
      * 在后面的课程中，将 CALL 用于单独编译的程序。
      * 後のレッスンで、個別にコンパイルされたプログラムに対して CALL を使用します。
      * A later lesson combines paragraphs with repeated processing.
      * 后面的课程将段落与重复处理结合起来。
      * 後のレッスンでは、段落を繰り返し処理と組み合わせます。
      * This lesson deliberately keeps one execution of each stage.
      * 本课特意保留每个阶段的一次执行。
      * このレッスンでは、各ステージの実行を 1 つずつ意図的に保持します。
      * The MOVE changes only the closing-balance receiving field.
      * MOVE 仅更改期末余额接收字段。
      * MOVE は、期末残高受け取りフィールドのみを変更します。
      * COMPUTE stores opening plus credit less debit in that field.
      * COMPUTE 商店开业加上该领域的贷方减去借方。
      * COMPUTE ストアのオープンと、そのフィールドのクレジットからデビットを差し引いたものを計算します。
      * Expected arithmetic is 1000.00 + 125.50 - 40.10.
      * 预期算术结果为 1000.00 + 125.50 - 40.10。
      * 予想される算術演算値は 1000.00 + 125.50 - 40.10 です。
      * Paragraph order is visible as three STAGE output lines.
      * 段落顺序显示为三个 STAGE 输出行。
      * 段落の順序は 3 つの STAGE 出力行として表示されます。
      * Omitting a PERFORM call removes that stage's output.
      * 省略 PERFORM 调用会删除该阶段的输出。
      * PERFORM 呼び出しを省略すると、そのステージの出力が削除されます。
      * Reordering calls changes the visible stage order.
      * 重新排序调用会更改可见阶段顺序。
      * コールの順序を変更すると、表示されるステージの順序が変わります。
      * No input values are read from a terminal or external file.
      * 不会从终端或外部文件读取任何输入值。
      * 入力値は端末または外部ファイルから読み取られません。
      * No branch changes whether these three paragraphs are called.
      * 无论这三段是否被调用，分支都不会改变。
      * これら 3 つの段落が呼び出されても、分岐は変わりません。
      * Main reports batch completion after finalization returns.
      * 主要报告最终确定返回后的批次完成情况。
      * Main は、ファイナライズが返された後にバッチの完了を報告します。
      * The final paragraph does not terminate the program itself.
      * 最后一段并不终止程序本身。
      * 最後の段落ではプログラム自体は終了しません。
      * Control returns to main, where STOP RUN terminates execution.
      * 控制返回到主程序，其中 STOP RUN 终止执行。
      * 制御はメインに戻り、STOP RUN で実行が終了します。
      * This separation helps test and review each stage independently.
      * 这种分离有助于独立测试和审查每个阶段。
      * この分離は、各段階を個別にテストおよびレビューするのに役立ちます。
      * It also gives later file lessons named places for their work.
      * 它还提供了后来的档案课程，并为他们的工作命名了地点。
      * また、後でファイル レッスンに作業場所を指定することもできます。
      * Keep calculations in the processing stage, not final reporting.
      * 将计算保留在处理阶段，而不是最终报告。
      * 計算は最終レポートではなく、処理段階に留めてください。
      * Keep initialization before any stage that consumes the result.
      * 在消耗结果的任何阶段之前保持初始化。
      * 結果を使用するステージの前に初期化を続けてください。
      * The example's paragraphs each contain one terminated sentence.
      * 该示例的每个段落都包含一个结尾句子。
      * この例の各段落には、終了した文が 1 つ含まれています。
      * The displayed closing value confirms shared data visibility.
      * 显示的收盘值确认了共享数据的可见性。
      * 表示された終了値により、共有データの可視性が確認されます。
      * STOP RUN ends this paragraph-organization demonstration.
      * STOP RUN 结束本段组织演示。
      * STOP RUN は、この段落編成のデモンストレーションを終了します。
