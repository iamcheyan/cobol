      * 第04課：1件の取引が口座規則を満たすか判定します。
      * この例では入れ子のIFと明示的なELSE経路を示します。
      * 再現可能な実行のため値をWORKING-STORAGEに固定します。
      * この例では単一金額と口座状態だけを検証します。
      * ここでは残高、ファイル、外部入力を使いません。
      * 正の金額という規則により、ゼロと負数は却下されます。
      * 上限値を含み、ちょうど上限と等しい金額も受理します。
      * この例を通過するには口座が有効状態である必要もあります。
      * 各分岐がそれぞれ判定と理由を表示します。
      * PROGRAM-IDはこのソースのコンパイル時に使うプログラム名です。
      * DATA DIVISIONはデータと実行ロジックを分けます。
      * この例では各01項目が基本フィールドを1つ定義します。
      * 手続き部では条件とDISPLAY文だけを使います。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF04.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 参照番号はハイフンも含め識別子文字列として保持します。
       01 WS-TRANSACTION-REFERENCE PIC X(12)
          VALUE "TXN-00000001".
      * ここで明示した簡易状態体系ではAが有効を示します。
      * この例では他の状態値を無効として扱います。
       01 WS-ACCOUNT-STATUS PIC X VALUE "A".
      * 符号付き金額により検証規則で負数を却下できます。
      * 独立した符号により正負の出力が明確になります。
       01 WS-TRANSACTION-AMOUNT PIC S9(7)V99
          SIGN IS LEADING SEPARATE CHARACTER VALUE 125.50.
      * この上限は学習用規則で、銀行商品の上限ではありません。
      * 取引金額と上限はいずれも小数2桁です。
       01 WS-MAXIMUM-AMOUNT PIC 9(7)V99 VALUE 1000.00.
      * 参照番号はこのプログラムでは演算上の意味を持ちません。
      * 口座状態は1文字の業務コードです。
      * 符号付き金額で負の入力値を試せます。
      * 規則上限は符号なしで、小数2桁です。
       PROCEDURE DIVISION.
      * 業務経路を選ぶ前に入力値を表示します。
           DISPLAY "取引参照番号="
               WS-TRANSACTION-REFERENCE
           DISPLAY "口座状態=" WS-ACCOUNT-STATUS
           DISPLAY "取引金額=" WS-TRANSACTION-AMOUNT
           DISPLAY "上限金額=" WS-MAXIMUM-AMOUNT
      * 最初の規則は下限を扱います。
      * 偽の場合は次の検証規則へ進みます。
      * 前の規則を通過した場合だけ、次の入れ子検査を行います。
      * 上限を調べる前にゼロと負数を却下します。
      * このELSEは上の下限条件に対応します。
           IF WS-TRANSACTION-AMOUNT <= ZERO
               DISPLAY "判定=REJECTED"
               DISPLAY "理由=AMOUNT_NOT_POSITIVE"
           ELSE
      * 上限と等しい値はこの比較を通過します。
               IF WS-TRANSACTION-AMOUNT > WS-MAXIMUM-AMOUNT
                   DISPLAY "判定=REJECTED"
                   DISPLAY "理由=AMOUNT_OVER_LIMIT"
               ELSE
      * 数値の上下限内の金額だけがこの検査に到達します。
                   IF WS-ACCOUNT-STATUS = "A"
                       DISPLAY "判定=ACCEPTED"
                       DISPLAY "理由=WITHIN_RULES"
                   ELSE
                       DISPLAY "判定=REJECTED"
                       DISPLAY "理由=ACCOUNT_INACTIVE"
                   END-IF
               END-IF
           END-IF
      * 最初のEND-IFは口座状態検査を閉じます。
      * 2番目のEND-IFは金額上限検査を閉じます。
      * 3番目のEND-IFは正の金額検査を閉じます。
      * 各入れ子IFには偽の場合のELSEが1つあります。
      * 上限と等しい場合、大なり比較は偽となり処理を続けます。
      * END-IFは条件を閉じますが、文は終わりません。
      * STOP RUNのピリオドでこのCOBOL文が終わります。
      * 明示した範囲により各ELSEが属するIFが分かります。
      * 理由テキストは優先順位が最も高い失敗規則を示します。
      * 比較演算子が上限を含む境界を定めます。
      * 字下げは読みやすさを助けますが、COBOLの範囲は決めません。
      * 数値比較では表示文字列でなく実際の値を使います。
      * 両方とも数値型で、小数2桁です。
      * この課ではファイル状態や永続元帳を扱いません。
      * 実システムには認可と重複検査も必要です。
      * 通貨、取引種別、記帳規則を定義する必要があります。
      * 却下は業務結果であり、システムエラーではありません。
      * 後の課でPERFORMを使い複数取引を処理します。
      * 複数のコード値には別の課でEVALUATEを紹介します。
      * 固定値によりコンパイル実行の確認を毎回再現できます。
      * 境界の練習では一度に1つのVALUE句を変更します。
      * IFの明示スコープで範囲を示し、文末はピリオドで閉じます。
      * 金額判定は表示文字列でなく数値項目を比較します。
      * 拒否は業務結果で、I/O障害などのシステムエラーとは異なります。
      * 実運用では通貨、取引種別、認可と重複検査を定義します。
      * 本課は固定データ1件を判定し、残高記帳は行いません。
      * 次課ではPERFORMで複数取引を処理します。
           STOP RUN.
