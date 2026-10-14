      * Lesson 04: decide whether one transaction passes account rules.
      * 中文：第04课：判断单笔交易是否符合账户规则。
      * 日本語：第04課：1件の取引が口座規則を満たすか判定します。
      * This example demonstrates nested IF and explicit ELSE paths.
      * 中文：本例演示嵌套IF和明确的ELSE路径。
      * 日本語：この例では入れ子のIFと明示的なELSE経路を示します。
      * Values are fixed in WORKING-STORAGE for repeatable runs.
      * 中文：值固定在WORKING-STORAGE中，确保运行结果可复现。
      * 日本語：再現可能な実行のため値をWORKING-STORAGEに固定します。
      * The example validates a single amount and account status only.
      * 中文：本例只验证单笔金额和账户状态。
      * 日本語：この例では単一金額と口座状態だけを検証します。
      * No balance, files, or external input are used here.
      * 中文：本例不使用余额、文件或外部输入。
      * 日本語：ここでは残高、ファイル、外部入力を使いません。
      * The positive amount rule rejects zero and all negative amounts.
      * 中文：正金额规则会拒绝零和所有负数。
      * 日本語：正の金額という規則により、ゼロと負数は却下されます。
      * The maximum amount is inclusive: its exact limit is accepted.
      * 中文：最高金额边界包含限值；恰好等于限值也接受。
      * 日本語：上限値を含み、ちょうど上限と等しい金額も受理します。
      * An account must also have active status to pass this example.
      * 中文：账户还必须处于有效状态才能通过本例检查。
      * 日本語：この例を通過するには口座が有効状態である必要もあります。
      * Each branch displays its own decision and reason.
      * 中文：每个分支都会显示对应的决定和原因。
      * 日本語：各分岐がそれぞれ判定と理由を表示します。
      * PROGRAM-ID supplies the name used when compiling this source.
      * 中文：PROGRAM-ID指定编译此源码时使用的程序名。
      * 日本語：PROGRAM-IDはこのソースのコンパイル時に使うプログラム名です。
      * The DATA DIVISION separates values from executable logic.
      * 中文：DATA DIVISION将数据与可执行逻辑分开。
      * 日本語：DATA DIVISIONはデータと実行ロジックを分けます。
      * Each 01 entry defines one elementary field in this example.
      * 中文：本例中每个01条目定义一个基本字段。
      * 日本語：この例では各01項目が基本フィールドを1つ定義します。
      * The procedure uses conditions and DISPLAY statements only.
      * 中文：过程部仅使用条件和DISPLAY语句。
      * 日本語：手続き部では条件とDISPLAY文だけを使います。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * Keep a text reference as an identifier, including its hyphens.
      * 中文：引用号作为文本标识符保存，包括其中的连字符。
      * 日本語：参照番号はハイフンも含め識別子文字列として保持します。
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * A means active in this small, explicitly stated status scheme.
      * 中文：在此明确说明的小型状态体系中，A表示有效。
      * 日本語：ここで明示した簡易状態体系ではAが有効を示します。
      * Other status values are treated as inactive by this example.
      * 中文：本例将其他状态值视为无效。
      * 日本語：この例では他の状態値を無効として扱います。
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
      * Signed amount allows the validation rule to reject negatives.
      * 中文：带符号金额使验证规则能够拒绝负数。
      * 日本語：符号付き金額により検証規則で負数を却下できます。
      * A separate sign makes positive and negative output unambiguous.
      * 中文：独立符号让正负数输出清晰明确。
      * 日本語：独立した符号により正負の出力が明確になります。
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
      * This limit is a teaching rule, not a bank product limit.
      * 中文：此限额是教学规则，不是银行产品限额。
      * 日本語：この上限は学習用規則で、銀行商品の上限ではありません。
      * The transaction amount and limit both have two decimals.
      * 中文：交易金额和限额都有两位小数。
      * 日本語：取引金額と上限はいずれも小数2桁です。
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
      * The reference has no arithmetic meaning in this program.
      * 中文：引用号在本程序中没有算术含义。
      * 日本語：参照番号はこのプログラムでは演算上の意味を持ちません。
      * Account status is a one-character business code.
      * 中文：账户状态是单字符业务代码。
      * 日本語：口座状態は1文字の業務コードです。
      * The signed amount lets us test a negative input value.
      * 中文：带符号金额可用于测试负数输入。
      * 日本語：符号付き金額で負の入力値を試せます。
      * The policy limit is unsigned and has two decimal positions.
      * 中文：规则限额不带符号，并有两位小数。
      * 日本語：規則上限は符号なしで、小数2桁です。
       PROCEDURE DIVISION.
      * Show the input values before selecting a business path.
      * 中文：选择业务路径前先显示输入值。
      * 日本語：業務経路を選ぶ前に入力値を表示します。
           DISPLAY "TRANSACTION-REFERENCE="
               WS-TRANSACTION-REFERENCE
           DISPLAY "ACCOUNT-STATUS=" WS-ACCOUNT-STATUS
           DISPLAY "TRANSACTION-AMOUNT=" WS-TRANSACTION-AMOUNT
           DISPLAY "MAXIMUM-AMOUNT=" WS-MAXIMUM-AMOUNT
      * The first rule handles the lower boundary.
      * 中文：第一条规则处理下边界。
      * 日本語：最初の規則は下限を扱います。
      * Its false path continues to the next validation rule.
      * 中文：条件为假时继续下一条验证规则。
      * 日本語：偽の場合は次の検証規則へ進みます。
      * Nested tests run only while each earlier rule has passed.
      * 中文：只有之前的规则均通过，才会执行后续嵌套检查。
      * 日本語：前の規則を通過した場合だけ、次の入れ子検査を行います。
      * Reject zero and negative values before testing the upper limit.
      * 中文：检查上限前先拒绝零和负数。
      * 日本語：上限を調べる前にゼロと負数を却下します。
      * This ELSE belongs to the lower-bound condition above.
      * 中文：此ELSE属于上方的下界条件。
      * 日本語：このELSEは上の下限条件に対応します。
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "DECISION=REJECTED"
               DISPLAY "REASON=AMOUNT_NOT_POSITIVE"
           ELSE
      * A value exactly equal to the limit passes this comparison.
      * 中文：恰好等于限额的值会通过此比较。
      * 日本語：上限と等しい値はこの比較を通過します。
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "DECISION=REJECTED"
                   DISPLAY "REASON=AMOUNT_OVER_LIMIT"
               ELSE
      * Only an amount within both numeric boundaries reaches this test.
      * 中文：只有处于两个数值边界内的金额才会到达此检查。
      * 日本語：数値の上下限内の金額だけがこの検査に到達します。
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "DECISION=ACCEPTED"
                       DISPLAY "REASON=WITHIN_RULES"
                   ELSE
                       DISPLAY "DECISION=REJECTED"
                       DISPLAY "REASON=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
      * The first END-IF closes the account-status test.
      * 中文：第一个END-IF关闭账户状态检查。
      * 日本語：最初のEND-IFは口座状態検査を閉じます。
      * The second END-IF closes the amount-limit test.
      * 中文：第二个END-IF关闭金额限额检查。
      * 日本語：2番目のEND-IFは金額上限検査を閉じます。
      * The third END-IF closes the positive-amount test.
      * 中文：第三个END-IF关闭正金额检查。
      * 日本語：3番目のEND-IFは正の金額検査を閉じます。
      * Each nested IF has one ELSE for its false path.
      * 中文：每个嵌套IF都用一个ELSE处理假路径。
      * 日本語：各入れ子IFには偽の場合のELSEが1つあります。
      * At the limit, greater-than is false; processing continues.
      * 中文：金额等于限值时，大于比较为假，流程继续。
      * 日本語：上限と等しい場合、大なり比較は偽となり処理を続けます。
      * END-IF closes its condition without ending the sentence.
      * 中文：END-IF关闭条件，但不结束句子。
      * 日本語：END-IFは条件を閉じますが、文は終わりません。
      * A period at STOP RUN closes this COBOL sentence.
      * 中文：STOP RUN处的句点结束此COBOL句子。
      * 日本語：STOP RUNのピリオドでこのCOBOL文が終わります。
      * Explicit scopes show which IF owns each ELSE branch.
      * 中文：显式作用域表明每个ELSE分支属于哪个IF。
      * 日本語：明示した範囲により各ELSEが属するIFが分かります。
      * Reason text identifies the highest-priority failed rule.
      * 中文：原因文本指出优先级最高的失败规则。
      * 日本語：理由テキストは優先順位が最も高い失敗規則を示します。
      * The comparison operator defines the inclusive upper boundary.
      * 中文：比较运算符定义包含边界的上限。
      * 日本語：比較演算子が上限を含む境界を定めます。
      * Indentation helps readers but does not control COBOL scope.
      * 中文：缩进有助阅读，但不决定COBOL作用域。
      * 日本語：字下げは読みやすさを助けますが、COBOLの範囲は決めません。
      * Numeric comparisons use the actual values, not the display text.
      * 中文：数值比较使用实际值，而非显示文本。
      * 日本語：数値比較では表示文字列でなく実際の値を使います。
      * Both values are numeric with two fractional positions.
      * 中文：两个值都是数值型，均有两位小数。
      * 日本語：両方とも数値型で、小数2桁です。
      * No file status or persistent ledger is modeled in this lesson.
      * 中文：本课不模拟文件状态或持久账簿。
      * 日本語：この課ではファイル状態や永続元帳を扱いません。
      * Real systems also need authorization and duplicate checks.
      * 中文：实际系统还需要授权和重复交易检查。
      * 日本語：実システムには認可と重複検査も必要です。
      * They must define currency, transaction type, and posting rules.
      * 中文：系统必须定义币种、交易类型和入账规则。
      * 日本語：通貨、取引種別、記帳規則を定義する必要があります。
      * Rejection reports a business result, not a system error.
      * 中文：拒绝结果属于业务结果，不是系统错误。
      * 日本語：却下は業務結果であり、システムエラーではありません。
      * A later lesson will process several transactions with PERFORM.
      * 中文：后续课程将用PERFORM处理多笔交易。
      * 日本語：後の課でPERFORMを使い複数取引を処理します。
      * EVALUATE will be introduced separately for multiple code values.
      * 中文：后续将另行介绍用EVALUATE处理多个代码值。
      * 日本語：複数のコード値には別の課でEVALUATEを紹介します。
      * Fixed values keep each compile-and-run check deterministic.
      * 中文：固定值使每次编译运行检查都可重现。
      * 日本語：固定値によりコンパイル実行の確認を毎回再現できます。
      * Change one VALUE clause at a time for the boundary exercise.
      * 中文：边界练习中每次只改一个VALUE子句。
      * 日本語：境界の練習では一度に1つのVALUE句を変更します。
      * Test both sides of every rule before trusting a batch decision.
      * 中文：信任批处理判定前，测试每条规则的两侧边界。
      * 日本語：バッチ判定を信頼する前に各規則の境界両側を試します。
      * The amount must be greater than zero to pass the first check.
      * 中文：金额必须大于零才能通过第一项检查。
      * 日本語：最初の検査を通るには金額がゼロより大きい必要があります。
      * The exact maximum is allowed by the previous test.
      * 中文：前一项检查允许金额恰好等于上限。
      * 日本語：直前の検査では上限と等しい金額も許可されます。
      * Any amount above the maximum is rejected by the second check.
      * 中文：任何超过上限的金额都会被第二项检查拒绝。
      * 日本語：上限超過の金額は2番目の検査で却下されます。
      * A valid amount is accepted only when status is active.
      * 中文：只有状态有效时，合规金额才会被接受。
      * 日本語：状態が有効な場合に限り、適正な金額を受理します。
      * Status comparison is a character equality test against A.
      * 中文：状态比较是与A进行字符相等测试。
      * 日本語：状態比較はAとの文字一致検査です。
      * Unknown status characters follow the inactive-account branch.
      * 中文：未知状态字符会进入账户无效分支。
      * 日本語：未知の状態文字は口座無効の分岐へ進みます。
      * The branch output identifies the first failed rule only.
      * 中文：分支输出只指出首条失败规则。
      * 日本語：分岐の出力は最初に失敗した規則だけを示します。
      * The first failed nested test determines the reported reason.
      * 中文：首个失败的嵌套检查决定报告原因。
      * 日本語：最初に失敗した入れ子検査が報告理由を決めます。
      * Rule ordering must match the business contract.
      * 中文：规则顺序必须符合业务约定。
      * 日本語：規則の順序は業務契約に合わせる必要があります。
      * The program displays only one decision for the one fixed record.
      * 中文：程序只为这条固定记录显示一个判定。
      * 日本語：プログラムは固定レコード1件につき判定を1つだけ表示します。
      * No value is changed while the nested IF statements execute.
      * 中文：嵌套IF执行期间不会更改任何值。
      * 日本語：入れ子IFの実行中に値は変更されません。
      * DISPLAY statements inside a selected branch run in source order.
      * 中文：所选分支内的DISPLAY按源码顺序执行。
      * 日本語：選択された分岐内のDISPLAYはソース順に実行されます。
      * Statements in the other branches are skipped for that run.
      * 中文：本次运行会跳过其他分支中的语句。
      * 日本語：今回の実行では他の分岐の文を飛ばします。
      * The final STOP RUN ends this one-record demonstration.
      * 中文：最后的STOP RUN结束这个单记录示例。
      * 日本語：最後のSTOP RUNでこの1レコード例を終了します。
           STOP RUN.
