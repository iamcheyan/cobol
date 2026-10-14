      *レッスン 09: 1 つのアカウント トランザクションを階層として編成します。
      *グループ項目には、関連する従属データ項目が含まれます。
      *基本項目には独自の PIC があり、フィールド値が格納されます。
      *01 レコードは、顧客、アカウント、トランザクションの詳細をグループ化します。
      *レベル番号は各親子関係を識別します。
      *同じレベルのアイテムは兄弟です。子供のレベルを上げる必要があります。
      *このサンプルでは固定値を使用し、外部入力は行いません。
      *重複する STATUS 名には親修飾が必要です。
      *グループ表示は、ファイル契約としてではなく、観察のために表示されます。
      *このレッスンでは、OCCURS 句または REDEFINES 句は使用されません。
      *レコード グループには、グループと基本フィールドを含めることができます。
      *グループ名は、レコードからフィールドへのパスを提供します。
      *このサンプルではレベル 01、05、10 を使用します。
      *兄弟サブグループは同じ 05 レベル番号を使用します。
      *顧客およびアカウントの識別子はテキスト キーです。
      *アカウント番号の先頭のゼロは引き続き重要です。
      *金額はテキスト識別子とは異なり、数値です。
      *ステータス フィールドには、名前が共有されているにもかかわらず、別々の役割が表示されます。
      *宣言の順序によって、グループ内の各フィールドの位置が決まります。
      *親名は、基本フィールド名にビジネス コンテキストを追加します。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. GROUP09.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *01 レベルのレコードには 3 つのビジネス サブグループが含まれています。
       01 WS-TRANSACTION-RECORD.
      *顧客フィールドは、1 つの 05 レベルのグループにまとめて属します。
          05 WS-CUSTOMER-INFO.
      *基本項目には PIC 句と初期サンプル値が含まれます。
             10 WS-CUSTOMER-ID PIC X(8) VALUE "C0001042".
             10 WS-CUSTOMER-NAME PIC X(12)
                VALUE "ADA LOVELACE".
      *アカウント ID とアカウント ステータスはこの親を共有します。
          05 WS-ACCOUNT-INFO.
             10 WS-ACCOUNT-NUMBER PIC X(10)
                VALUE "0001234567".
      *STATUS は以下でも使用されるため、参照はその親を修飾します。
             10 WS-STATUS PIC X VALUE "A".
      *トランザクションの詳細は、同じレコード内の別のグループを形成します。
          05 WS-TXN-INFO.
             10 WS-TXN-ID PIC X(12) VALUE "TXN-00000001".
             10 WS-TXN-CODE PIC X VALUE "D".
      *V は、金額に暗黙の小数点以下 2 桁を与えます。
             10 WS-TXN-AMOUNT PIC 9(5)V99 VALUE 125.50.
             10 WS-STATUS PIC X(7) VALUE "PENDING".
       PROCEDURE DIVISION.
      *各基本フィールドをビジネス ラベルとともに表示します。
           DISPLAY "CUSTOMER ID="
               WS-CUSTOMER-ID OF WS-CUSTOMER-INFO
           DISPLAY "CUSTOMER NAME="
               WS-CUSTOMER-NAME OF WS-CUSTOMER-INFO
           DISPLAY "ACCOUNT NUMBER="
               WS-ACCOUNT-NUMBER OF WS-ACCOUNT-INFO
      *修飾子は、目的の STATUS 基本項目を選択します。
           DISPLAY "ACCOUNT STATUS=" WS-STATUS OF WS-ACCOUNT-INFO
           DISPLAY "TRANSACTION ID=" WS-TXN-ID OF WS-TXN-INFO
           DISPLAY "TRANSACTION CODE=" WS-TXN-CODE OF WS-TXN-INFO
           DISPLAY "TRANSACTION AMOUNT="
               WS-TXN-AMOUNT OF WS-TXN-INFO
           DISPLAY "TRANSACTION STATUS=" WS-STATUS OF WS-TXN-INFO
      *グループ表示では、その連続した従属コンテンツが公開されます。
      *フィールド間に区切り文字は追加されず、暗黙の V が省略されます。
           DISPLAY "GROUP DATA=[" WS-TRANSACTION-RECORD "]"
           STOP RUN.
      *WS-TRANSACTION-RECORD は最上位のレコード グループです。
      *WS-CUSTOMER-INFO、WS-ACCOUNT-INFO、および WS-TXN-INFO はグループです。
      *WS-CUSTOMER-ID および WS-TXN-AMOUNT は基本データ項目です。
      *グループには子がいます。基本的な PIC 句はありません。
      *各基本 PIC は、クラス、幅、および小数位取りを定義します。
      *レベル 01 がレコードを開始します。以下の05アイテムが該当します。
      *レベル 10 の項目は、直前の 05 の親に属します。
      *インデントにより、読者はネストされたレベルを確認することができます。
      *COBOL では、親子関係を定義するためにインデントではなくレベル番号を使用します。
      *グループの子は宣言順にストレージを占有します。
      *グループ データは、区切り文字なしで子コンテンツを結合します。
      *金額フィールドを単独で参照すると、00125.50 と表示されます。
      *グループ表示では、その数字文字は 0012550 として表示されます。
      *暗黙の小数点はグループ文字として保存されません。
      *このデモンストレーションは、ポータブルな交換形式ではありません。
      *直接参照しても、金額は数値のままです。
      *繰り返される名前はその親グループで修飾されます。
      *アカウントのステータスは、WS-ACCOUNT-INFO の下の 1 文字です。
      *トランザクション STATUS は、WS-TXN-INFO の下の 7 文字です。
      *資格によって名前が解決されます。フィールドの名前は変更されません。
      *親グループを表示せずにリーフを表示できます。
      *一意のフィールド名は修飾子なしで参照できます。
      *このサンプルでは、​​修飾子を使用して STATUS を明確にします。
      *1 つのレコード定義に複数の関連コンポーネントを含めることができます。
      *グループはステータスまたはトランザクション コードの値を検証しません。
      *この 01 アイテムは、サンプルの作業用ストレージ レコードです。
      *ファイル レコードは、ファイル セクション内の関連定義を使用します。
      *ファイル レイアウトの詳細は、ファイル処理フェーズで到着します。
      *ここのすべてのフィールドは、基本的な VALUE 句によって初期化されます。
      *このプログラムにはグループ自体に VALUE 句がありません。
      *ここでは、ファイル、テーブル、ループ、入力、または算術演算は使用されません。
      *次のレッスンでは、REDEFINES を使用した代替ビューを示します。
      *後のレッスンでは、繰り返しの記録に OCCURS を使用します。
      *グループ項目を使用すると、論理レコードの移動と確認が容易になります。
      *フィールドの内容を検証したり、ビジネス ルールを適用したりすることはありません。
      *STOP RUN はこのデータ構造のデモを終了します。
