       IDENTIFICATION DIVISION.
       PROGRAM-ID. LESSON32.
      * 日本語：このプログラムは照合バッチ全体を統括する。
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * 日本語：ワーカーモジュールはこれらと同一のレコードおよびカウンター構成を共有する。
       COPY "BATCH-INTERFACE.CPY".
       01 WS-CHECK-COUNT PIC 999 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
      * 日本語：口座テーブル、カウンター、ワーカーエラーフラグをリセットする。
           INITIALIZE WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           MOVE "N" TO WS-FAILED
      * 日本語：口座マスターを読み込み、取引ストリームを適用する。
      * 日本語：記帳モジュールが2つの入力ファイルと業務ルールを管理する。
           CALL "LOADPOST32" USING BY REFERENCE
               WS-ACCOUNT-TABLE WS-BATCH-COUNTS
      * 日本語：ファイル障害後に不完全な口座テーブルを同期しない。
           IF WS-FAILED NOT = "Y"
      * 日本語：同期モジュールが SQLite、レポート、データベース状態を管理する。
               CALL "SYNCDB32" USING BY REFERENCE
                   WS-ACCOUNT-TABLE WS-BATCH-COUNTS
           END-IF
      * 日本語：最終カウンターを報告する前にバッチの計算整合性を検証する。
           PERFORM 3000-CHECK-COUNTS
           PERFORM 1000-REPORT-SUMMARY
           PERFORM 2000-RETURN-STATUS
           GOBACK.
       1000-REPORT-SUMMARY.
      * 日本語：業務上の拒否は拒否件数に数え、システム障害とはしない。
           DISPLAY "SUMMARY ACCOUNTS=" WS-ACCOUNT-COUNT
                   " TX=" WS-TRANSACTION-COUNT
                   " POSTED=" WS-POSTED-COUNT
                   " REJECTED=" WS-REJECTED-COUNT
                   " UPDATED=" WS-UPDATED-COUNT
                   " UNCHANGED=" WS-UNCHANGED-COUNT
                   " INSERTED=" WS-INSERTED-COUNT.
       2000-RETURN-STATUS.
      * 日本語：システム障害の場合に限り、シェルにゼロ以外のステータスを返す。
           IF WS-FAILED = "Y"
               MOVE 1 TO RETURN-CODE
           ELSE
               MOVE 0 TO RETURN-CODE
           END-IF.
       3000-CHECK-COUNTS.
      * 日本語：読み込んだ各取引は記帳または拒否のいずれかに分類する。
           COMPUTE WS-CHECK-COUNT =
               WS-POSTED-COUNT + WS-REJECTED-COUNT
           IF WS-CHECK-COUNT NOT = WS-TRANSACTION-COUNT
               DISPLAY "ERROR=TRANSACTION COUNT MISMATCH"
               MOVE "Y" TO WS-FAILED
           END-IF
      * 日本語：同期が成功すると、読み込んだ各口座をちょうど1回分類する。
           IF WS-FAILED NOT = "Y"
               COMPUTE WS-CHECK-COUNT =
                   WS-UPDATED-COUNT + WS-UNCHANGED-COUNT
                   + WS-INSERTED-COUNT
               IF WS-CHECK-COUNT NOT = WS-ACCOUNT-COUNT
                   DISPLAY "ERROR=SYNC COUNT MISMATCH"
                   MOVE "Y" TO WS-FAILED
               END-IF
           END-IF.
      * 日本語：LOADPOST32 は27文字および20文字の固定長レコードを読み込む。
      * 日本語：金額項目には暗黙の小数点を持つ整数セントを格納する。
      * 日本語：ワーカーは共有テーブルに最大20口座を保持する。
      * 日本語：口座キーが重複していると、記帳開始前に失敗する。
      * 日本語：入金と許可された出金によってテーブルを更新する。
      * 日本語：残高不足、未知の取引種別や口座は業務上の拒否となる。
      * 日本語：業務上の拒否では最終的な口座残高は変わらない。
      * 日本語：受理レコードと拒否レコードは別々の順編成ファイルに書き込む。
      * 日本語：バッチログに各取引の判定を記録する。
      * 日本語：SYNCDB32 は主キーで最終口座を検索する。
      * 日本語：データベース残高が一致すれば UNCHANGED と報告する。
      * 日本語：残高が異なる場合は、ファイルから計算した結果に更新する。
      * 日本語：データベースにキーがない場合、口座マスターから挿入する。
      * 日本語：レポートに読み込んだ各口座への判定を記載する。
      * 日本語：同じ入力で再実行すると、最終残高は同じ結果に収束する。
      * 日本語：入力を再処理する際は、宣言された開始残高から始める。
      * 日本語：したがって、データベース状態に入金を二重適用しない。
      * 日本語：出力とデータベース変更は単一の原子トランザクションではない。
      * 日本語：実行スクリプトは再現可能な SQLite 初期データベースを用意する。
      * 日本語：既存データでの実行操作により、決定的な再起動動作を確認する。
      * 日本語：本番バッチでは永続的なバッチ識別子を追加する。
      * 日本語：さらにトランザクションのコミットおよび復旧プロトコルを定める。
      * 日本語：ここではシミュレーションせず、これらの境界を文書化する。
      * 日本語：モジュール呼び出しでは共有 Copybook 構成を参照渡しで使用する。
      * 日本語：このドライバーが最終集計とプロセスの戻りステータスを管理する。
      * 日本語：記帳モジュールと同期モジュールは、それぞれのファイルと SQL 処理を管理する。
      * 日本語：この統合バッチに関する追加の設計メモ。
      * 日本語：ドライバーはワーカーの状態をプロセス戻りコードに変換する。
      * 日本語：ワーカーは各テーブルを参照で受け取り、状態を更新する。
      * 日本語：各カウンターは上記のバッチ計算チェックで役割を持つ。
      * 日本語：記帳件数と拒否件数で取引入力全体を区分する。
      * 日本語：SQL 処理の成功後、同期件数で各口座を分類する。
      * 日本語：金額テキストは地域別小数表記ではなく、整数セントを表す。
      * 日本語：入力取引ごとに口座検索のスキャンが1回必要となる。
      * 日本語：より大きなマスターには、テーブル設計または索引検索を計画する必要がある。
      * 日本語：このサンプルはメモリ使用量を予測可能にするため、マスター行数を制限する。
      * 日本語：再構築では空のデータベースを用意し、再実行ではデータベース行を保持する。
      * 日本語：チェックでは一時データを使い、レッスンのフィクスチャを変更しない。
       END PROGRAM LESSON32.
