      *第 10 课：描述共享存储上的两种事务布局。
      *REDEFINES赋予两个同级别的数据项相同的存储区域。
      *事务代码告诉程序哪个视图是有意义的。
      *存款有效负载：账户、金额和交易参考。
      *转账负载：源账户、目标账户、金额。
      *在此示例中，每个有效负载有 27 个显示字符位置。
      *备用视图不是自动数据转换。
      *值在选定的基本字段中移动。
      *然后程序显示另一个视图如何看到这些相同的字节。
      *本演示中未使用文件、外部输入或表。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REDEF10.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *交易代码位于正在重新定义的有效负载之外。
       01 WS-TRANSACTION-RECORD.
          05 WS-TRANSACTION-CODE PIC X.
      *此基本布局描述的是存款交易格式的负载。
          05 WS-DEPOSIT-PAYLOAD.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-DEPOSIT-AMOUNT PIC 9(5)V99.
             10 WS-REFERENCE PIC X(10).
      *重新定义视图从相同的存储位置开始。
          05 WS-TRANSFER-PAYLOAD REDEFINES WS-DEPOSIT-PAYLOAD.
             10 WS-SOURCE-ACCOUNT PIC X(10).
             10 WS-TARGET-ACCOUNT PIC X(10).
             10 WS-TRANSFER-AMOUNT PIC 9(5)V99.
       PROCEDURE DIVISION.
      *首先将有效负载显示为存款交易。
       0000-MAIN.
           PERFORM 1000-LOAD-DEPOSIT
           PERFORM 2000-LOAD-TRANSFER
           STOP RUN.
      *通过基本布局加载并显示字段。
       1000-LOAD-DEPOSIT.
           MOVE "D" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER
           MOVE 125.50 TO WS-DEPOSIT-AMOUNT
           MOVE "TXN-000001" TO WS-REFERENCE
           DISPLAY "TYPE=" WS-TRANSACTION-CODE
           DISPLAY "DEPOSIT ACCOUNT=" WS-ACCOUNT-NUMBER
           DISPLAY "DEPOSIT AMOUNT=" WS-DEPOSIT-AMOUNT
           DISPLAY "DEPOSIT REFERENCE=" WS-REFERENCE.
      *通过重新定义布局来编写传输。
       2000-LOAD-TRANSFER.
           MOVE "T" TO WS-TRANSACTION-CODE
           MOVE "0001234567" TO WS-SOURCE-ACCOUNT
           MOVE "0007654321" TO WS-TARGET-ACCOUNT
           MOVE 250.75 TO WS-TRANSFER-AMOUNT
           DISPLAY "TYPE=" WS-TRANSACTION-CODE
           DISPLAY "TRANSFER SOURCE=" WS-SOURCE-ACCOUNT
           DISPLAY "TRANSFER TARGET=" WS-TARGET-ACCOUNT
           DISPLAY "TRANSFER AMOUNT=" WS-TRANSFER-AMOUNT
      *基本布局中的字段名现在读取的是转账负载字节。
           DISPLAY "DEPOSIT VIEW OF SAME BYTES:"
           DISPLAY "ACCOUNT=" WS-ACCOUNT-NUMBER
           DISPLAY "AMOUNT=" WS-DEPOSIT-AMOUNT
           DISPLAY "REFERENCE=" WS-REFERENCE.
      *两种布局都从记录中的相同位置开始。
      *基本项和重定义项都是 05 级组项。
      *重定义的同级组项紧接在基本项的子项之后。
      *这两个定义之间没有放置任何对等级别的项目。
      *存款有效负载包含 10 + 7 + 10 个显示位置。
      *传输有效负载包含 10 + 10 + 7 个显示位置。
      *因此，在本例中，两种布局都描述了 27 个位置。
      *基本组项是 REDEFINES 子句所指名的被重定义项。
      *第二组是重新定义对象。
      *这两个描述都保留在源程序中。
      *有效负载在内存中具有一组共享字节。
      *代码字段标记哪种交易类型处于活动状态。
      *有效负载组是 01 记录下的同级组。
      *他们的 PIC 条款描述了不同的业务领域。
      *命名数字字段使用其数字图片显示。
      *根据其声明的视图检查每个事务类型。
      *GnuCOBOL 要求分配的大小相匹配。
      *重新定义组及其子组没有 VALUE 子句。
      *PROCEDURE DIVISION MOVE 初始化两个视图。
      *通过一个视图进行写入会更改另一视图的字节。
      *它不会将数据复制到第二个独立记录。
      *交易代码保留在共享有效负载之外。
      *使用事务代码合约选择一个视图。
      *示例使用 D 表示存款，T 表示转账。
      *存款金额最初显示为 00125.50。
      *转账金额稍后显示为 00250.75。
      *在存款视图中，转账目标数字类似于金额。
      *前七个目标数字在该视图中显示为 00076.54。
      *剩余目标数字加入转账金额作为参考。
      *此叠加不是有效的存款解释。
      *不要将两种视图视为独立的事务。
      *REDEFINES 不检查或验证交易代码。
      *REDEFINES 不转换数据表示形式。
      *字段名称文档解释；它们不标记字节。
      *确切的布局取决于声明的 PIC 和 USAGE 子句。
      *这些显示字段用于简单可见的示例。
      *打包或二进制字段需要单独的布局分析。
      *文件交换还需要编码和记录规则。
      *将备用布局放在一起以比较它们的大小。
      *尺寸不匹配是布局错误，而不是转换错误。
      *第 14 课将 REDEFINES 与表和查找逻辑结合起来。
      *STOP RUN 结束该固定数据存储演示。
