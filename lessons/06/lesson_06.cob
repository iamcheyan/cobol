      * Lesson 06: process a fixed sequence with PERFORM VARYING.
      * 第 06 课：使用 PERFORM VARYING 处理固定序列。
      * レッスン 06: PERFORM VARYING を使用して固定シーケンスを処理します。
      * Three sample records demonstrate repeated sequential processing.
      * 三个样本记录演示了重复的顺序处理。
      * 3 つのサンプル レコードは、繰り返される順次処理を示しています。
      * EVALUATE chooses details for each fixed sample.
      * EVALUATE 为每个固定样本选择详细信息。
      * EVALUATE は、各固定サンプルの詳細を選択します。
      * It does not use a table; table storage comes in a later lesson.
      * 它不使用表格；表存储将在后面的课程中介绍。
      * テーブルは使用しません。テーブルのストレージについては後のレッスンで説明します。
      * The loop index begins at one and advances by one each iteration.
      * 循环索引从 1 开始，每次迭代增加 1。
      * ループ インデックスは 1 から始まり、反復ごとに 1 ずつ進みます。
      * UNTIL index > last means the last index is included.
      * UNTIL index > last 表示包含最后一个索引。
      * UNTIL インデックス > 最後 は、最後のインデックスが含まれることを意味します。
      * The loop checks its UNTIL condition before each iteration.
      * 循环在每次迭代之前检查其 UNTIL 条件。
      * ループは、各反復の前に UNTIL 条件をチェックします。
      * A last index of zero therefore processes no sample records.
      * 因此，最后一个索引为零，不处理任何样本记录。
      * したがって、最後のインデックスが 0 の場合、サンプル レコードは処理されません。
      * The processed count records how many loop bodies actually ran.
      * 处理后的计数记录实际运行了多少个循环体。
      * 処理された数は、実際に実行されたループ本体の数を記録します。
      * No input file or database is read by this demonstration.
      * 此演示不读取输入文件或数据库。
      * このデモでは入力ファイルやデータベースは読み取られません。
      * IDENTIFICATION DIVISION marks this program's source identity.
      * IDENTIFICATION DIVISION 标记该程序的源身份。
      * IDENTIFICATION DIVISION は、このプログラムのソース ID をマークします。
      * PROGRAM-ID names this standalone program.
      * PROGRAM-ID 命名这个独立程序。
      * PROGRAM-ID は、このスタンドアロン プログラムの名前を指定します。
      * DATA DIVISION declares storage used by the procedure.
      * DATA DIVISION 声明过程使用的存储空间。
      * DATA DIVISION は、プロシージャによって使用されるストレージを宣言します。
      * WORKING-STORAGE keeps initial values during program execution.
      * WORKING-STORAGE 在程序执行期间保留初始值。
      * WORKING-STORAGE は、プログラム実行中に初期値を保持します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PERFORM06.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Set to three for the complete fixed sample sequence.
      * 对于完整的固定样本序列，设置为 3。
      * 完全な固定サンプル シーケンスの場合は 3 に設定します。
       01 WS-LAST-SAMPLE PIC 9 VALUE 3.
      * VARYING initializes this index before its first test.
      * VARYING 在第一次测试之前初始化该索引。
      * VARYING は、最初のテストの前にこのインデックスを初期化します。
       01 WS-SAMPLE-INDEX PIC 9 VALUE ZERO.
      * This counter is increased once for every processed sample.
      * 每处理一个样本，该计数器就会增加一次。
      * このカウンタは、処理されたサンプルごとに 1 回増加します。
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
      * LAST-SAMPLE controls the loop's inclusive upper boundary.
      * LAST-SAMPLE 控制循环的包含上限。
      * LAST-SAMPLE は、ループの包括的な上限を制御します。
      * VARYING changes the index through its FROM and BY clauses.
      * VARYING 通过其 FROM 和 BY 子句更改索引。
      * VARYING は、FROM 句と BY 句を使用してインデックスを変更します。
      * The processed count is separate from the loop index.
      * 处理后的计数与循环索引分开。
      * 処理されたカウントはループ インデックスとは別のものです。
      * These PIC 9 fields are unsigned whole-number counters.
      * 这些 PIC 9 字段是无符号整数计数器。
      * これらの PIC 9 フィールドは、符号なしの整数カウンターです。
       PROCEDURE DIVISION.
      * Show the configured inclusive final sample number.
      * 显示配置的包含最终样本数。
      * 設定された包括的な最終サンプル番号を表示します。
           DISPLAY "LAST-SAMPLE=" WS-LAST-SAMPLE
      * Iterate the sample numbers from one through the configured last.
      * 将样本编号从 1 迭代到配置的最后一个。
      * サンプル番号を 1 から構成された最後の番号まで繰り返します。
      * The display before the loop also exposes zero-iteration runs.
      * 循环之前的显示还公开了零迭代运行。
      * ループ前の表示では、ゼロ反復実行も公開されます。
      * FROM supplies the index's initial value for this execution.
      * FROM 为本次执行提供索引的初始值。
      * FROM は、この実行のインデックスの初期値を提供します。
      * BY supplies the step added after a completed loop body.
      * BY 提供在完成的循环体之后添加的步骤。
      * BY は、完了したループ本体の後に追加されるステップを提供します。
           PERFORM VARYING WS-SAMPLE-INDEX FROM 1 BY 1
               UNTIL WS-SAMPLE-INDEX > WS-LAST-SAMPLE
      * EVALUATE maps each loop number to its fixed sample values.
      * EVALUATE 将每个循环编号映射到其固定样本值。
      * EVALUATE は、各ループ番号をその固定サンプル値にマップします。
               EVALUATE WS-SAMPLE-INDEX
      * Sample one is a deposit transaction.
      * 示例之一是存款交易。
      * サンプル 1 は入金トランザクションです。
                   WHEN 1
                       DISPLAY "SAMPLE=001 CODE=D AMOUNT=125.50"
      * Sample two is a withdrawal transaction.
      * 示例二是取款交易。
      * サンプル 2 は出金トランザクションです。
                   WHEN 2
                       DISPLAY "SAMPLE=002 CODE=W AMOUNT=040.10"
      * Sample three is a transfer transaction.
      * 样本三是一笔转账交易。
      * サンプル 3 は転送トランザクションです。
                   WHEN 3
                       DISPLAY "SAMPLE=003 CODE=T AMOUNT=075.00"
      * A higher limit reaches this branch after sample three.
      * 在样本三之后，更高的限制到达此分支。
      * サンプル 3 の後に上限がこの分岐に達します。
                   WHEN OTHER
                       DISPLAY "SAMPLE=UNMAPPED"
               END-EVALUATE
      * Count after the sample branch has completed.
      * 样本分支完成后进行计数。
      * サンプル分岐が完了した後にカウントします。
               COMPUTE WS-PROCESSED-COUNT =
                   WS-PROCESSED-COUNT + 1
           END-PERFORM
      * The loop condition is tested before another iteration starts.
      * 在另一次迭代开始之前测试循环条件。
      * ループ条件は、別の反復が開始される前にテストされます。
      * Each WHEN emits one sample line and continues the loop body.
      * 每个 WHEN 发出一个采样行并继续循环体。
      * 各 WHEN は 1 つのサンプル ラインを出力し、ループ本体を継続します。
      * COMPUTE increments the count after the sample branch.
      * COMPUTE 在样本分支之后递增计数。
      * COMPUTE は、サンプル分岐後にカウントをインクリメントします。
      * DISPLAY after END-PERFORM reports the final count.
      * END-PERFORM 报告最终计数后的 DISPLAY。
      * END-PERFORM 後の DISPLAY は最終カウントを報告します。
      * Show how many iterations actually passed the UNTIL test.
      * 显示实际通过 UNTIL 测试的迭代次数。
      * 実際に UNTIL テストに合格した反復回数を表示します。
           DISPLAY "SAMPLES-PROCESSED=" WS-PROCESSED-COUNT
      * Index stops at the first value greater than LAST-SAMPLE.
      * 索引在第一个大于 LAST-SAMPLE 的值处停止。
      * インデックスは、LAST-SAMPLE より大きい最初の値で停止します。
      * A limit above three also exercises the unmapped sample branch.
      * 超过三的限制也会执行未映射的样本分支。
      * 制限が 3 を超えると、マップされていないサンプル ブランチも適用されます。
      * This loop does not use a table or a file as its input source.
      * 此循环不使用表或文件作为其输入源。
      * このループは、入力ソースとしてテーブルやファイルを使用しません。
      * The PERFORM body completes once for each accepted index.
      * 对于每个接受的索引，PERFORM 主体完成一次。
      * PERFORM 本体は、受け入れられたインデックスごとに 1 回完了します。
      * VARYING advances the index after the body completes.
      * VARYING 在主体完成后推进索引。
      * VARYING は、本体の完了後にインデックスを進めます。
      * The next UNTIL test sees the incremented index.
      * 下一个 UNTIL 测试看到递增的索引。
      * 次の UNTIL テストでは、増分されたインデックスが確認されます。
      * For last sample three, indexes one, two, and three are included.
      * 对于最后一个示例三，包括索引一、二和三。
      * 最後のサンプル 3 には、インデックス 1、2、および 3 が含まれています。
      * Index four satisfies > three and ends this sample loop.
      * 索引四满足>三并结束该样本循环。
      * インデックス 4 は > 3 を満たし、このサンプル ループを終了します。
      * With last index zero, the initial test is already true.
      * 最后一个索引为零，初始测试已经正确。
      * 最後のインデックスが 0 の場合、最初のテストはすでに true です。
      * In that case the loop body is skipped and the count stays zero.
      * 在这种情况下，循环体将被跳过并且计数保持为零。
      * その場合、ループ本体はスキップされ、カウントはゼロのままになります。
      * Last index one processes one item, then stops at two.
      * 最后一个索引 1 处理一项，然后在两项处停止。
      * 最後のインデックス 1 は 1 つの項目を処理し、2 つの項目で停止します。
      * A last sample above three reaches WHEN OTHER for extra indexes.
      * 三个以上的最后一个样本达到 WHEN OTHER 以获得额外索引。
      * 3 を超える最後のサンプルは、追加のインデックスの WHEN OTHER に達します。
      * This example exposes that boundary instead of hiding extra work.
      * 此示例公开了该边界，而不是隐藏额外的工作。
      * この例では、余分な作業を隠すのではなく、その境界を公開します。
      * END-PERFORM closes the inline loop's statement scope.
      * END-PERFORM 关闭内联循环的语句范围。
      * END-PERFORM は、インライン ループのステートメント スコープを閉じます。
      * END-EVALUATE closes the sample selection inside each iteration.
      * END-EVALUATE 关闭每次迭代内的样本选择。
      * END-EVALUATE は、各反復内のサンプル選択を閉じます。
      * Each displayed sample is selected from its current loop index.
      * 每个显示的样本都是从其当前循环索引中选择的。
      * 表示される各サンプルは、現在のループ インデックスから選択されます。
      * The count uses COMPUTE syntax introduced in the prior lessons.
      * 计数使用前面课程中介绍的 COMPUTE 语法。
      * カウントには、前のレッスンで紹介した COMPUTE 構文を使用します。
      * No period occurs inside the loop to end PERFORM early.
      * 循环内不会出现任何句点来提前结束 PERFORM。
      * PERFORM を早期に終了するために、ループ内にピリオドは発生しません。
      * The final STOP RUN period closes the sentence after the loop.
      * 最后的 STOP RUN 周期结束循环后的句子。
      * 最後の STOP RUN 期間は、ループ後の文を閉じます。
      * EVALUATE keeps sample details together by index.
      * EVALUATE 通过索引将样本详细信息保存在一起。
      * EVALUATE は、サンプルの詳細をインデックスごとにまとめます。
      * A later lesson stores these records as repeated table entries.
      * 后面的课程将这些记录存储为重复的表条目。
      * 後のレッスンでは、これらのレコードを繰り返しテーブル エントリとして保存します。
      * A later lesson moves this work into a named paragraph.
      * 后面的课程将这项工作移至指定段落中。
      * 後のレッスンでは、この作業を名前付き段落に移動します。
      * Production batches also validate records and handle errors.
      * 生产批次还验证记录并处理错误。
      * 実稼働バッチはレコードを検証し、エラーを処理します。
      * This example uses a small known limit and fixed values.
      * 此示例使用一个小的已知限制和固定值。
      * この例では、小さな既知の制限と固定値を使用します。
      * Transactions are shown in input order; no sorting is performed.
      * 交易按输入顺序显示；不执行任何排序。
      * トランザクションは入力順に表示されます。並べ替えは行われません。
      * The loop is sequential and single-threaded.
      * 该循环是顺序的、单线程的。
      * ループはシーケンシャルでシングルスレッドです。
      * No balance is posted and no transaction is changed.
      * 没有过帐余额，也没有更改任何交易。
      * 残高は転記されず、トランザクションは変更されません。
      * The code and amount text are labels, not arithmetic operands.
      * 代码和金额文本是标签，而不是算术操作数。
      * コードと金額のテキストはラベルであり、算術オペランドではありません。
      * The sample count is separate from the configured last index.
      * 样本计数与配置的最后一个索引是分开的。
      * サンプル数は、設定された最後のインデックスとは別のものです。
      * This distinction lets output report completed iterations.
      * 这种区别让输出报告完成的迭代。
      * この区別により、完了した反復のレポートを出力できます。
      * The initial value of the processed count is zero.
      * 已处理计数的初始值为零。
      * 処理回数の初期値は0です。
      * The counter changes only after a sample branch executes.
      * 计数器仅在示例分支执行后才会更改。
      * カウンタはサンプル分岐の実行後にのみ変化します。
      * If the body does not run, the initial zero remains unchanged.
      * 如果主体不运行，则初始零保持不变。
      * 本体が実行されない場合、最初の 0 は変更されません。
      * The compiler checks the loop control and branch structure.
      * 编译器检查循环控制和分支结构。
      * コンパイラはループ制御と分岐構造をチェックします。
      * Run the boundary exercise to verify the observed counts.
      * 运行边界练习以验证观察到的计数。
      * 境界演習を実行して、観察された数を確認します。
      * Restore the last sample to three for the default example.
      * 将最后一个样本恢复为默认示例的三个。
      * デフォルトの例では、最後のサンプルを 3 に戻します。
      * STOP RUN ends this fixed sequence demonstration.
      * STOP RUN 结束该固定序列演示。
      * STOP RUN は、この固定シーケンスのデモンストレーションを終了します。
           STOP RUN.
