      * Lesson 03: post transactions and accrue simple account interest.
      * 中文：第03课：入账交易并计算简单账户利息。
      * 日本語：第03課：取引を記帳し、簡単な口座利息を計算します。
      * This is a teaching example, not a production interest engine.
      * 中文：这是教学示例，不是生产级计息系统。
      * 日本語：これは学習用で、本番用の利息計算システムではありません。
      * All monetary data uses explicit decimal scales in its PICTURE.
      * 中文：所有金额数据都在PICTURE中明确指定小数位。
      * 日本語：金額データはすべてPICTUREで小数桁を明示します。
      * Values begin in WORKING-STORAGE from their VALUE clauses.
      * 中文：值由VALUE子句在WORKING-STORAGE中初始化。
      * 日本語：値はVALUE句によりWORKING-STORAGEで初期化されます。
      * COMPUTE evaluates arithmetic and places a result in a field.
      * 中文：COMPUTE执行算术运算并将结果写入字段。
      * 日本語：COMPUTEは演算を行い、結果を項目に格納します。
      * MOVE copies a value; it does not add or subtract the amount.
      * 中文：MOVE复制值，不会对金额做加减。
      * 日本語：MOVEは値を複写し、金額を加減しません。
      * Without ROUNDED, excess fractional digits are truncated.
      * 中文：未指定ROUNDED时，多余小数位会被截断。
      * 日本語：ROUNDEDがなければ余分な小数桁は切り捨てられます。
      * One account and one fixed transaction set keep results stable.
      * 中文：单一账户和固定交易集使结果稳定。
      * 日本語：口座1件と固定取引により結果を一定にします。
      * The output is a ledger snapshot with no files or operator input.
      * 中文：输出是账簿快照，不使用文件或操作员输入。
      * 日本語：出力は元帳のスナップショットで、ファイルや操作者入力は使いません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Opening account balance before today's sample transactions.
      * 中文：今日示例交易处理前的账户期初余额。
      * 日本語：本日の例示取引前の口座期首残高です。
      * Two decimal places represent cents for this lesson's example.
      * 中文：本课示例用两位小数表示分。
      * 日本語：この課の例では小数2桁をセントとして表します。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
      * A credit increases the balance but is not applied by its PIC.
      * 中文：贷记会增加余额，但PIC不会执行入账。
      * 日本語：入金は残高を増やしますが、PIC句が反映するわけではありません。
      * COMPUTE in the procedure performs the actual addition.
      * 中文：过程部中的COMPUTE才执行实际加法。
      * 日本語：実際の加算は手続き部のCOMPUTEが行います。
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.55.
      * A debit is represented as a positive amount to subtract.
      * 中文：借记表示为待扣除的正数金额。
      * 日本語：引落額は差し引く正の金額として表します。
      * The business direction comes from the COMPUTE expression.
      * 中文：业务方向由COMPUTE表达式决定。
      * 日本語：業務上の方向はCOMPUTE式で決まります。
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * The fixed service fee is another positive amount to subtract.
      * 中文：固定服务费也是待扣除的正数金额。
      * 日本語：固定サービス料も差し引く正の金額です。
      * No currency conversion or tax rule is modeled in this example.
      * 中文：本例未模拟货币兑换或税务规则。
      * 日本語：この例では通貨換算や税規則を扱いません。
       01 WS-SERVICE-FEE PIC 9(5)V99 VALUE 5.25.
      * The rate has four decimals; it is not text such as 1.25 percent.
      * 中文：利率有四位小数；它不是“1.25%”这样的文本。
      * 日本語：利率は小数4桁で、「1.25%」のような文字列ではありません。
      * The sample applies 0.0125 once, without a day-count adjustment.
      * 中文：示例直接应用0.0125一次，不作日计数调整。
      * 日本語：例では日数調整なしで0.0125を1回適用します。
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0125.
      * It receives opening balance plus credits and minus debits.
      * 中文：此字段接收期初余额加贷记、减借记后的结果。
      * 日本語：期首残高に入金を加え、引落額を引いた値を受け取ります。
      * Its cents scale feeds the later interest calculation.
      * 中文：其分级精度用于后续利息计算。
      * 日本語：セント単位の精度を後の利息計算に使います。
       01 WS-PRE-INTEREST-BALANCE PIC 9(7)V99 VALUE ZERO.
      * Keep four fractional digits to inspect the arithmetic result.
      * 中文：保留四位小数以检查运算结果。
      * 日本語：演算結果を確認できるよう小数4桁を保持します。
      * The target scale controls how many digits remain in this field.
      * 中文：目标字段精度决定保留多少位。
      * 日本語：格納先の桁数で保持する小数桁が決まります。
       01 WS-INTEREST-RAW PIC 9(5)V9999 VALUE ZERO.
      * MOVE to cents demonstrates reducing scale without ROUNDED.
      * 中文：MOVE到分精度演示不使用ROUNDED时降低精度。
      * 日本語：MOVEでセント精度にし、ROUNDEDなしの桁縮小を示します。
      * The receiver has two fractional positions rather than four.
      * 中文：接收字段有两位小数，而非四位。
      * 日本語：受け取り項目は小数4桁でなく2桁です。
       01 WS-INTEREST-MOVE PIC 9(5)V99 VALUE ZERO.
      * COMPUTE without ROUNDED has the same truncation behavior here.
      * 中文：此处COMPUTE未使用ROUNDED也会截断。
      * 日本語：ここではROUNDEDなしのCOMPUTEも同様に切り捨てます。
      * Keeping both results lets learners compare the two statements.
      * 中文：保留两个结果，便于比较两种语句。
      * 日本語：両方の結果を保持し、2つの文を比較できます。
       01 WS-INTEREST-TRUNC PIC 9(5)V99 VALUE ZERO.
      * ROUNDED requests arithmetic rounding to the receiver's scale.
      * 中文：ROUNDED要求按接收字段精度进行算术舍入。
      * 日本語：ROUNDEDは受け取り項目の桁数への算術丸めを指定します。
      * GnuCOBOL's default mode is nearest away from zero.
      * 中文：GnuCOBOL默认采用远离零方向的最近值舍入。
      * 日本語：GnuCOBOLの既定方式はゼロから遠ざかる最近値への丸めです。
       01 WS-INTEREST-ROUNDED PIC 9(5)V99 VALUE ZERO.
      * Closing balance uses the rounded interest amount for posting.
      * 中文：入账时，期末余额使用舍入后的利息金额。
      * 日本語：記帳する期末残高には丸め後の利息額を使います。
      * This explicit choice is a sample business rule for the exercise.
      * 中文：这是练习中明确选定的示例业务规则。
      * 日本語：これは練習用に明示した業務規則です。
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
      * First compute the balance after the transaction amounts.
      * 中文：先计算交易金额处理后的余额。
      * 日本語：まず取引額適用後の残高を計算します。
      * Apply deposits, withdrawals, and fee in the written order.
      * 中文：按语句顺序应用存款、取款和费用。
      * 日本語：記述順に入金、出金、手数料を適用します。
           COMPUTE WS-PRE-INTEREST-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT
                   - WS-WITHDRAWAL - WS-SERVICE-FEE.
      * Multiply the cents-scale balance by the four-place rate.
      * 中文：将分精度余额乘以四位小数利率。
      * 日本語：セント単位の残高に小数4桁の利率を掛けます。
      * The result has four fractional positions in this data item.
      * 中文：结果在此数据项中保留四位小数。
      * 日本語：このデータ項目では結果を小数4桁で保持します。
           COMPUTE WS-INTEREST-RAW =
               WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE.
      * MOVE changes scale from four fractional places to two.
      * 中文：MOVE将精度从四位小数变为两位。
      * 日本語：MOVEで小数4桁から2桁へ精度を変えます。
      * MOVE does not use the arithmetic ROUNDED phrase.
      * 中文：MOVE不使用算术ROUNDED短语。
      * 日本語：MOVEでは算術のROUNDED句を使いません。
           MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE.
      * COMPUTE can assign a numeric expression to a receiving field.
      * 中文：COMPUTE可将数值表达式赋给接收字段。
      * 日本語：COMPUTEは数値式を受け取り項目に代入できます。
      * Without ROUNDED, extra fractional digits are truncated.
      * 中文：未指定ROUNDED时，多余小数位会被截断。
      * 日本語：ROUNDEDがなければ余分な小数桁は切り捨てられます。
           COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW.
      * ROUNDED changes only the result saved in this receiving field.
      * 中文：ROUNDED只影响存入此接收字段的结果。
      * 日本語：ROUNDEDが変えるのはこの受け取り項目に保存する結果だけです。
      * The source field WS-INTEREST-RAW remains unchanged.
      * 中文：源字段WS-INTEREST-RAW保持不变。
      * 日本語：元項目WS-INTEREST-RAWは変更されません。
           COMPUTE WS-INTEREST-ROUNDED ROUNDED =
               WS-INTEREST-RAW.
      * Post the selected rounded amount into the closing balance.
      * 中文：将选定的舍入金额入账至期末余额。
      * 日本語：選択した丸め額を期末残高に記帳します。
      * Posting the rounded amount is the sample's chosen rule.
      * 中文：本示例选择入账舍入后的金额。
      * 日本語：この例では丸め後の金額を記帳する規則です。
           COMPUTE WS-CLOSING-BALANCE =
               WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED.
      * Display original inputs before the calculated values.
      * 中文：先显示原始输入，再显示计算值。
      * 日本語：計算値の前に元の入力値を表示します。
           DISPLAY "OPENING-BALANCE=" WS-OPENING-BALANCE
           DISPLAY "DEPOSIT=" WS-DEPOSIT
           DISPLAY "WITHDRAWAL=" WS-WITHDRAWAL
           DISPLAY "SERVICE-FEE=" WS-SERVICE-FEE
           DISPLAY "PERIOD-RATE=" WS-PERIOD-RATE
      * Compare the pre-interest balance and full-scale interest result.
      * 中文：比较计息前余额与完整精度的利息结果。
      * 日本語：利息計算前の残高と全桁の利息結果を比較します。
           DISPLAY "PRE-INTEREST-BALANCE="
               WS-PRE-INTEREST-BALANCE
           DISPLAY "INTEREST-RAW-4DP=" WS-INTEREST-RAW
      * These next lines show MOVE and COMPUTE with two-place receivers.
      * 中文：以下输出展示MOVE和COMPUTE写入两位小数字段的结果。
      * 日本語：続く出力で、2桁の受け取り項目へのMOVEとCOMPUTEを示します。
           DISPLAY "INTEREST-MOVE-2DP=" WS-INTEREST-MOVE
           DISPLAY "INTEREST-COMPUTE-TRUNC=" WS-INTEREST-TRUNC
           DISPLAY "INTEREST-COMPUTE-ROUNDED="
               WS-INTEREST-ROUNDED
           DISPLAY "CLOSING-BALANCE=" WS-CLOSING-BALANCE
      * Every displayed amount has a declared receiving-field scale.
      * 中文：每个显示金额都有明确声明的接收字段精度。
      * 日本語：表示する金額には受け取り項目の桁数が宣言されています。
      * DISPLAY shows the implied point; PIC V uses no storage position.
      * 中文：DISPLAY显示隐含小数点；PIC V不占存储位。
      * 日本語：DISPLAYは小数点を表示し、PIC Vは格納桁を使いません。
      * The source amounts are unchanged by COMPUTE expressions here.
      * 中文：此处COMPUTE表达式不会改变源金额。
      * 日本語：ここでのCOMPUTE式は元の金額を変更しません。
      * The MOVE statement changes only its receiving data item.
      * 中文：MOVE语句只改变其接收数据项。
      * 日本語：MOVE文が変更するのは受け取りデータ項目だけです。
      * COMPUTE stores the result in the item before the equal sign.
      * 中文：COMPUTE将结果存入等号左侧字段。
      * 日本語：COMPUTEは等号の左側の項目に結果を格納します。
      * A too-small receiving item can raise a size-error condition.
      * 中文：接收字段过小可能触发尺寸错误条件。
      * 日本語：受け取り項目が小さすぎるとサイズエラー条件が発生します。
      * ON SIZE ERROR handles a size error explicitly.
      * 中文：ON SIZE ERROR可显式处理尺寸错误。
      * 日本語：ON SIZE ERRORでサイズエラーを明示的に処理できます。
      * The sample values fit the declared fields.
      * 中文：示例值均适合声明的字段。
      * 日本語：例の値は宣言した項目に収まります。
      * Real batches require documented rounding and posting rules.
      * 中文：实际批处理需要明确记录舍入和入账规则。
      * 日本語：実運用のバッチには丸めと記帳規則の文書化が必要です。
      * This sample uses one account and does not read an external file.
      * 中文：本示例只处理一个账户，不读取外部文件。
      * 日本語：この例は口座1件を扱い、外部ファイルを読みません。
      * Transaction validation and rejection paths are later lessons.
      * 中文：交易验证和拒绝路径将在后续课程介绍。
      * 日本語：取引検証と却下処理は後の課で扱います。
      * Paragraphs, loops, and conditions are also taught later.
      * 中文：段落、循环和条件也将在后续课程讲解。
      * 日本語：段落、ループ、条件も後の課で学びます。
      * STOP RUN ends the sample after displaying calculated values.
      * 中文：显示计算结果后，STOP RUN结束示例程序。
      * 日本語：計算値を表示した後、STOP RUNで例を終了します。
           STOP RUN.
