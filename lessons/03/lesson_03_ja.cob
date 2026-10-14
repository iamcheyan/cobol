      * 日本語：第03課：取引を記帳し、簡単な口座利息を計算します。
      * 日本語：これは学習用で、本番用の利息計算システムではありません。
      * 日本語：金額データはすべてPICTUREで小数桁を明示します。
      * 日本語：値はVALUE句によりWORKING-STORAGEで初期化されます。
      * 日本語：COMPUTEは演算を行い、結果を項目に格納します。
      * 日本語：MOVEは値を複写し、金額を加減しません。
      * 日本語：ROUNDEDがなければ余分な小数桁は切り捨てられます。
      * 日本語：口座1件と固定取引により結果を一定にします。
      * 日本語：出力は元帳のスナップショットで、ファイルや操作者入力は使いません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE03.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 日本語：本日の例示取引前の口座期首残高です。
      * 日本語：この課の例では小数2桁をセントとして表します。
       01 WS-OPENING-BALANCE PIC 9(7)V99 VALUE 1000.00.
      * 日本語：入金は残高を増やしますが、PIC句が反映するわけではありません。
      * 日本語：実際の加算は手続き部のCOMPUTEが行います。
       01 WS-DEPOSIT PIC 9(7)V99 VALUE 250.55.
      * 日本語：引落額は差し引く正の金額として表します。
      * 日本語：業務上の方向はCOMPUTE式で決まります。
       01 WS-WITHDRAWAL PIC 9(7)V99 VALUE 40.10.
      * 日本語：固定サービス料も差し引く正の金額です。
      * 日本語：この例では通貨換算や税規則を扱いません。
       01 WS-SERVICE-FEE PIC 9(5)V99 VALUE 5.25.
      * 日本語：利率は小数4桁で、「1.25%」のような文字列ではありません。
      * 日本語：例では日数調整なしで0.0125を1回適用します。
       01 WS-PERIOD-RATE PIC 9(1)V9(4) VALUE 0.0125.
      * 日本語：期首残高に入金を加え、引落額を引いた値を受け取ります。
      * 日本語：セント単位の精度を後の利息計算に使います。
       01 WS-PRE-INTEREST-BALANCE PIC 9(7)V99 VALUE ZERO.
      * 日本語：演算結果を確認できるよう小数4桁を保持します。
      * 日本語：格納先の桁数で保持する小数桁が決まります。
       01 WS-INTEREST-RAW PIC 9(5)V9999 VALUE ZERO.
      * 日本語：MOVEでセント精度にし、ROUNDEDなしの桁縮小を示します。
      * 日本語：受け取り項目は小数4桁でなく2桁です。
       01 WS-INTEREST-MOVE PIC 9(5)V99 VALUE ZERO.
      * 日本語：ここではROUNDEDなしのCOMPUTEも同様に切り捨てます。
      * 日本語：両方の結果を保持し、2つの文を比較できます。
       01 WS-INTEREST-TRUNC PIC 9(5)V99 VALUE ZERO.
      * 日本語：ROUNDEDは受け取り項目の桁数への算術丸めを指定します。
      * 日本語：GnuCOBOLの既定方式はゼロから遠ざかる最近値への丸めです。
       01 WS-INTEREST-ROUNDED PIC 9(5)V99 VALUE ZERO.
      * 日本語：記帳する期末残高には丸め後の利息額を使います。
      * 日本語：これは練習用に明示した業務規則です。
       01 WS-CLOSING-BALANCE PIC 9(7)V99 VALUE ZERO.
       PROCEDURE DIVISION.
      * 日本語：まず取引額適用後の残高を計算します。
      * 日本語：記述順に入金、出金、手数料を適用します。
           COMPUTE WS-PRE-INTEREST-BALANCE =
               WS-OPENING-BALANCE + WS-DEPOSIT
                   - WS-WITHDRAWAL - WS-SERVICE-FEE.
      * 日本語：セント単位の残高に小数4桁の利率を掛けます。
      * 日本語：このデータ項目では結果を小数4桁で保持します。
           COMPUTE WS-INTEREST-RAW =
               WS-PRE-INTEREST-BALANCE * WS-PERIOD-RATE.
      * 日本語：MOVEで小数4桁から2桁へ精度を変えます。
      * 日本語：MOVEでは算術のROUNDED句を使いません。
           MOVE WS-INTEREST-RAW TO WS-INTEREST-MOVE.
      * 日本語：COMPUTEは数値式を受け取り項目に代入できます。
      * 日本語：ROUNDEDがなければ余分な小数桁は切り捨てられます。
           COMPUTE WS-INTEREST-TRUNC = WS-INTEREST-RAW.
      * 日本語：ROUNDEDが変えるのはこの受け取り項目に保存する結果だけです。
      * 日本語：元項目WS-INTEREST-RAWは変更されません。
           COMPUTE WS-INTEREST-ROUNDED ROUNDED =
               WS-INTEREST-RAW.
      * 日本語：選択した丸め額を期末残高に記帳します。
      * 日本語：この例では丸め後の金額を記帳する規則です。
           COMPUTE WS-CLOSING-BALANCE =
               WS-PRE-INTEREST-BALANCE + WS-INTEREST-ROUNDED.
      * 日本語：計算値の前に元の入力値を表示します。
           DISPLAY "OPENING-BALANCE=" WS-OPENING-BALANCE
           DISPLAY "DEPOSIT=" WS-DEPOSIT
           DISPLAY "WITHDRAWAL=" WS-WITHDRAWAL
           DISPLAY "SERVICE-FEE=" WS-SERVICE-FEE
           DISPLAY "PERIOD-RATE=" WS-PERIOD-RATE
      * 日本語：利息計算前の残高と全桁の利息結果を比較します。
           DISPLAY "PRE-INTEREST-BALANCE="
               WS-PRE-INTEREST-BALANCE
           DISPLAY "INTEREST-RAW-4DP=" WS-INTEREST-RAW
      * 日本語：続く出力で、2桁の受け取り項目へのMOVEとCOMPUTEを示します。
           DISPLAY "INTEREST-MOVE-2DP=" WS-INTEREST-MOVE
           DISPLAY "INTEREST-COMPUTE-TRUNC=" WS-INTEREST-TRUNC
           DISPLAY "INTEREST-COMPUTE-ROUNDED="
               WS-INTEREST-ROUNDED
           DISPLAY "CLOSING-BALANCE=" WS-CLOSING-BALANCE
      * 日本語：表示する金額には受け取り項目の桁数が宣言されています。
      * 日本語：DISPLAYは小数点を表示し、PIC Vは格納桁を使いません。
      * 日本語：ここでのCOMPUTE式は元の金額を変更しません。
      * 日本語：MOVE文が変更するのは受け取りデータ項目だけです。
      * 日本語：COMPUTEは等号の左側の項目に結果を格納します。
      * 日本語：受け取り項目が小さすぎるとサイズエラー条件が発生します。
      * 日本語：ON SIZE ERRORでサイズエラーを明示的に処理できます。
      * 日本語：例の値は宣言した項目に収まります。
      * 日本語：実運用のバッチには丸めと記帳規則の文書化が必要です。
      * 日本語：この例は口座1件を扱い、外部ファイルを読みません。
      * 日本語：取引検証と却下処理は後の課で扱います。
      * 日本語：段落、ループ、条件も後の課で学びます。
      * 日本語：計算値を表示した後、STOP RUNで例を終了します。
           STOP RUN.
