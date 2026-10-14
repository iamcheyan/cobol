      * Lesson 10: describe two transaction layouts over shared storage.
      * 第 10 课：描述共享存储上的两种事务布局。
      * レッスン 10: 共有ストレージ上の 2 つのトランザクション レイアウトについて説明します。
      * REDEFINES gives two same-level data items the same storage area.
      * REDEFINES赋予两个同级别的数据项相同的存储区域。
      * REDEFINES は、2 つの同じレベルのデータ項目に同じ記憶領域を与えます。
      * The transaction code tells the program which view is meaningful.
      * 事务代码告诉程序哪个视图是有意义的。
      * トランザクション コードは、どのビューが意味を持つかをプログラムに伝えます。
      * Deposit payload: account, amount, and transaction reference.
      * 存款有效负载：账户、金额和交易参考。
      * 入金ペイロード: アカウント、金額、トランザクション参照。
      * Transfer payload: source account, target account, and amount.
      * 转账负载：源账户、目标账户、金额。
      * ペイロードの転送: ソースアカウント、ターゲットアカウント、および金額。
      * Each payload has 27 display character positions in this example.
      * 在此示例中，每个有效负载有 27 个显示字符位置。
      * この例では、各ペイロードに 27 個の表示文字位置があります。
      * The alternate view is not an automatic data conversion.
      * 备用视图不是自动数据转换。
      * 代替ビューは自動データ変換ではありません。
      * Values are moved through the selected elementary fields.
      * 值在选定的基本字段中移动。
      * 値は、選択した基本フィールドを介して移動されます。
      * The program then shows how the other view sees those same bytes.
      * 然后程序显示另一个视图如何看到这些相同的字节。
      * 次にプログラムは、他のビューがそれらの同じバイトをどのように認識するかを示します。
      * No file, external input, or table is used in this demonstration.
      * 本演示中未使用文件、外部输入或表。
      * このデモでは、ファイル、外部入力、テーブルは使用されません。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REDEF10.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      * The transaction code is outside the payload being redefined.
      * 交易代码位于正在重新定义的有效负载之外。
      * トランザクション コードは、再定義されるペイロードの外にあります。
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-CODE PIC X.
      * This subject view describes a deposit-shaped payload.
      * 该主题视图描述了沉积物形状的有效负载。
      * この主題図では、堆積物の形をしたペイロードについて説明します。
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
             10 WS-REFERENCE PIC X(10).
      * The redefining view begins at the same storage position.
      * 重新定义视图从相同的存储位置开始。
      * 再定義ビューは同じ格納位置から始まります。
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             10 WS-TARGET-ACCOUNT PIC X(10).
             10 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       PROCEDURE DIVISION.
      * Show the payload first as a deposit transaction.
      * 首先将有效负载显示为存款交易。
      * 最初にペイロードを入金トランザクションとして表示します。
       0000-MAIN.
           PERFORM 1000-LOAD-DEPOSIT
           PERFORM 2000-LOAD-TRANSFER
           STOP RUN.
      * Load and display fields through the subject layout.
      * 通过主题布局加载和显示字段。
      * 件名レイアウトを通じてフィールドをロードして表示します。
       1000-LOAD-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT
           MOVE "TXN-000001" TO WS-REFERENCE
           DISPLAY "TYPE=" WS-TRANSACTION-CODE
           DISPLAY "DEPOSIT ACCOUNT=" WS-ACCOUNT-NUMBER
           DISPLAY "DEPOSIT AMOUNT=" WS-DEPOSIT-AMOUNT
           DISPLAY "DEPOSIT REFERENCE=" WS-REFERENCE.
      * Write a transfer through the redefining layout.
      * 通过重新定义布局来编写传输。
      * レイアウトを再定義して転送を書き込みます。
       2000-LOAD-TRANSFER.
           MOVE "T" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT
           MOVE "0007654321" TO WS-TARGET-ACCOUNT
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
           DISPLAY "TYPE=" WS-TRANSACTION-CODE
           DISPLAY "TRANSFER SOURCE=" WS-SOURCE-ACCOUNT
           DISPLAY "TRANSFER TARGET=" WS-TARGET-ACCOUNT
           DISPLAY "TRANSFER AMOUNT=" WS-TRANSFER-AMOUNT
      * The subject names now read the transfer payload bytes.
      * 主题名称现在读取传输有效负载字节。
      * サブジェクト名は転送ペイロード バイトを読み取るようになりました。
           DISPLAY "DEPOSIT VIEW OF SAME BYTES:"
           DISPLAY "ACCOUNT=" WS-ACCOUNT-NUMBER
           DISPLAY "AMOUNT=" WS-DEPOSIT-AMOUNT
           DISPLAY "REFERENCE=" WS-REFERENCE.
      * Both layouts start at the same position within the record.
      * 两种布局都从记录中的相同位置开始。
      * どちらのレイアウトもレコード内の同じ位置から始まります。
      * The subject and redefining item are both level 05 groups.
      * 主题和重新定义项目均为05级组。
      * サブジェクトと再定義項目は両方ともレベル 05 グループです。
      * The redefining sibling follows the subject's child entries.
      * 重新定义的兄弟姐妹遵循主题的子条目。
      * 再定義兄弟は、サブジェクトの子エントリの後に続きます。
      * No peer level item is placed between these two definitions.
      * 这两个定义之间没有放置任何对等级别的项目。
      * これら 2 つの定義の間にピア レベルの項目は配置されません。
      * The deposit payload contains 10 + 7 + 10 display positions.
      * 存款有效负载包含 10 + 7 + 10 个显示位置。
      * デポジット ペイロードには 10 + 7 + 10 の表示位置が含まれます。
      * The transfer payload contains 10 + 10 + 7 display positions.
      * 传输有效负载包含 10 + 10 + 7 个显示位置。
      * 転送ペイロードには 10 + 10 + 7 の表示位置が含まれます。
      * Both layouts therefore describe 27 positions in this example.
      * 因此，在本例中，两种布局都描述了 27 个位置。
      * したがって、この例では両方のレイアウトで 27 の位置が記述されます。
      * The base group is the subject named by REDEFINES.
      * 基本组是 REDEFINES 命名的主题。
      * 基本グループは、REDEFINES によって命名されたサブジェクトです。
      * The second group is the redefining object.
      * 第二组是重新定义对象。
      * 2 番目のグループは再定義オブジェクトです。
      * Both descriptions remain in the source program.
      * 这两个描述都保留在源程序中。
      * どちらの記述もソースプログラムに残ります。
      * The payload has one shared set of bytes in memory.
      * 有效负载在内存中具有一组共享字节。
      * ペイロードには、メモリ内に 1 つの共有バイト セットがあります。
      * The code field marks which transaction type is active.
      * 代码字段标记哪种交易类型处于活动状态。
      * コード フィールドは、どのトランザクション タイプがアクティブであるかをマークします。
      * Payload groups are siblings under the 01 record.
      * 有效负载组是 01 记录下的同级组。
      * ペイロード グループは、01 レコードの下の兄弟です。
      * Their PIC clauses describe different business fields.
      * 他们的 PIC 条款描述了不同的业务领域。
      * 彼らの PIC 条項はさまざまなビジネス分野について説明しています。
      * Named numeric fields display using their numeric picture.
      * 命名数字字段使用其数字图片显示。
      * 名前付き数値フィールドは、数値画像を使用して表示されます。
      * Check each transaction type against its declared view.
      * 根据其声明的视图检查每个事务类型。
      * 各トランザクション タイプを宣言されたビューと照合して確認します。
      * GnuCOBOL requires the allocated sizes to match.
      * GnuCOBOL 要求分配的大小相匹配。
      * GnuCOBOL では、割り当てられたサイズが一致する必要があります。
      * The redefining group and its children have no VALUE clauses.
      * 重新定义组及其子组没有 VALUE 子句。
      * 再定義グループとその子には VALUE 句がありません。
      * PROCEDURE DIVISION MOVEs initialize both views.
      * PROCEDURE DIVISION MOVE 初始化两个视图。
      * PROCEDURE DIVISION MOVE は両方のビューを初期化します。
      * Writing through one view changes the other view's bytes.
      * 通过一个视图进行写入会更改另一视图的字节。
      * 一方のビューを介して書き込むと、もう一方のビューのバイトが変更されます。
      * It does not copy data to a second, independent record.
      * 它不会将数据复制到第二个独立记录。
      * データを 2 番目の独立したレコードにコピーすることはありません。
      * The transaction code remains outside the shared payload.
      * 交易代码保留在共享有效负载之外。
      * トランザクション コードは共有ペイロードの外側に残ります。
      * Select a view using the transaction-code contract.
      * 使用事务代码合约选择一个视图。
      * トランザクション コード コントラクトを使用してビューを選択します。
      * The sample uses D for deposit and T for transfer.
      * 样本使用D进行充值，T进行转账。
      * このサンプルでは、​​入金に D、転送に T を使用しています。
      * The deposit amount initially displays as 00125.50.
      * 存款金额最初显示为 00125.50。
      * 入金額は最初は 00125.50 と表示されます。
      * The transfer amount later displays as 00250.75.
      * 转账金额稍后显示为 00250.75。
      * その後、転送金額は 00250.75 と表示されます。
      * In the deposit view, transfer target digits resemble an amount.
      * 在存款视图中，转账目标数字类似于金额。
      * デポジットビューでは、転送対象の数字が金額に似ています。
      * The first seven target digits display as 00076.54 in that view.
      * 前七个目标数字在该视图中显示为 00076.54。
      * このビューでは、ターゲットの最初の 7 桁が 00076.54 として表示されます。
      * Remaining target digits join the transfer amount as reference.
      * 剩余目标数字加入转账金额作为参考。
      * 残りの対象桁は転送金額に参考として加わります。
      * This overlay is not a valid deposit interpretation.
      * 此叠加不是有效的存款解释。
      * このオーバーレイは有効なデポジットの解釈ではありません。
      * Do not treat both views as independent transactions.
      * 不要将两种视图视为独立的事务。
      * 両方のビューを独立したトランザクションとして扱わないでください。
      * REDEFINES does not inspect or validate the transaction code.
      * REDEFINES 不检查或验证交易代码。
      * REDEFINES はトランザクション コードを検査または検証しません。
      * REDEFINES does not convert data representations.
      * REDEFINES 不转换数据表示形式。
      * REDEFINES はデータ表現を変換しません。
      * Field names document interpretations; they do not tag the bytes.
      * 字段名称文档解释；它们不标记字节。
      * フィールド名は解釈を文書化します。バイトにはタグを付けません。
      * The exact layout depends on the declared PIC and USAGE clauses.
      * 确切的布局取决于声明的 PIC 和 USAGE 子句。
      * 正確なレイアウトは、宣言された PIC 句と USAGE 句によって異なります。
      * These display fields are used for a simple visible example.
      * 这些显示字段用于简单可见的示例。
      * これらの表示フィールドは、単純な表示例に使用されます。
      * Packed or binary fields would need a separate layout analysis.
      * 打包或二进制字段需要单独的布局分析。
      * パックされたフィールドまたはバイナリ フィールドの場合は、別のレイアウト分析が必要になります。
      * File interchange additionally needs encoding and record rules.
      * 文件交换还需要编码和记录规则。
      * ファイル交換にはさらにエンコードと記録ルールが必要です。
      * Keep alternate layouts together to compare their size.
      * 将备用布局放在一起以比较它们的大小。
      * サイズを比較するには、交互のレイアウトをまとめて保持します。
      * A size mismatch is a layout error, not conversion.
      * 尺寸不匹配是布局错误，而不是转换错误。
      * サイズの不一致は、変換ではなくレイアウト エラーです。
      * Lesson 14 will combine REDEFINES with tables and lookup logic.
      * 第 14 课将 REDEFINES 与表和查找逻辑结合起来。
      * レッスン 14 では、REDEFINE とテーブルおよびルックアップ ロジックを組み合わせます。
      * STOP RUN ends this fixed-data storage demonstration.
      * STOP RUN 结束该固定数据存储演示。
      * STOP RUN は、この固定データ ストレージのデモを終了します。
