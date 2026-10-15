       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
      * このプログラムは照合バッチ全体を統括する。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * ドライバーとワーカーは同じCopybookでレコードと件数を共有します。
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * 実行開始時に口座表、件数、ワーカーエラーフラグを初期化します。
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
      * 記帳ワーカーが口座マスターと取引を順に処理します。
      * 正常に完了した場合だけ、計算済み残高をデータベースと同期します。
      * 読込障害後に部分的な口座表を同期すると残高を誤るため、
      * エラーフラグを確認してから後続処理へ進みます。
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * ファイル障害後は不完全な口座表を同期しません。
           IF WS-FAILED NOT = "Y"
      * 同期ワーカーはSQLiteの口座行を照合し、結果を報告します。
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
      * 出力件数を表示する前に、入力・受理・拒否件数の整合性を確認します。
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
      * 残高不足や未知コードは業務上の拒否として集計します。
      * ファイルやSQLの失敗とは区別し、処理可能な取引を続けます。
           DISPLAY "集計 口座=" WS-ACCOUNT-COUNT
                   " 取引=" WS-TRANSACTION-COUNT
                   " 記帳=" WS-POSTED-COUNT
                   " 拒否=" WS-REJECTED-COUNT
                   " 更新=" WS-UPDATED-COUNT
                   " 変更なし=" WS-UNCHANGED-COUNT
                   " 挿入=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
      * 業務拒否だけなら正常終了し、システム障害時は非ゼロを返します。
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
      * 受理件数と拒否件数を照合し、入力取引全件の行先を確認します。
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "エラー=取引件数不一致"
               MOVE "Y" TO WS-FAILED
           END-IF
      * DB同期後、各口座は未変更・更新・挿入のいずれかに分類されます。
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "エラー=同期件数不一致"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      * LOADPOST32は27バイトの口座行と20バイトの取引行を読みます。
      * 金額は整数のセントで保持し、Vで小数点位置を示します。
      * 口座表は最大20件です。重複キーがあれば記帳前に失敗します。
      * 入金と残高内の引出しは残高へ反映し、その他は業務拒否にします。
      * 拒否取引は残高を変えず、受理・拒否ファイルとバッチログに残します。
      * SYNCDB32は口座キーでDBを照合し、同額ならUNCHANGEDを報告します。
      * 差額は計算済み残高で更新し、未登録口座はマスターから挿入します。
      * レポートには各口座の同期結果を記載します。再実行時も入力の
      * 期首残高から計算するため、DBへ入金を二重加算しません。
      * ただしファイルとDBは単一トランザクションではありません。
      * 実行スクリプトは再現可能なSQLite初期DBを用意します。既存DBでの
      * 既存DBで再実行し、同じ入力から同じ残高になることを確認します。
      * コミット境界を別途定義する必要があります。
      * CALL境界ではCopybookの共有項目を参照渡しにします。
      * ドライバーは集計とプロセス状態を管理し、各ワーカーは担当する
      * ファイル操作またはSQL処理を実行して結果を返します。
      * 受理数と拒否数の合計が取引入力数になります。同期結果の件数は
      * 処理成功後に口座ごとに分類されます。入力金額は地域設定に依存
      * しない整数セントです。大きなマスターには索引検索が適します。
      * この例では使用量を予測できるよう口座数を制限しています。
      * 再構築はDBを初期化し、再実行は既存行を保って同期します。
      * チェックは一時データを使い、教材の入力ファイルを変更しません。
       END PROGRAM LESSON32.
