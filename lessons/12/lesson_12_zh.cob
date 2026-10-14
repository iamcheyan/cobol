      *第 12 课：使用 INDEXED BY 项遍历 OCCURS 表。
      *表索引在表的 OCCURS 子句中声明。
      *SET 分配并递增表引用中使用的索引。
      *与下标不同，索引具有 USAGE INDEX，而不是数字 PIC。
      *程序按表项顺序显示已加载的账户表。
      *开始用索引遍历之前，先加载全部四个表项。
      *不使用搜索、索引算术或外部输入。
      *最后条目计数控制遍历何时结束。
      *此示例使表和遍历范围保持同步。
      *没有索引值显示，就好像它是数字字段一样。
      *文字下标初始化表中的已知位置。
      *每个数字常量按其编号写入一个表项。
      *表条目是两个基本项的组。
      *该索引在 OCCURS 中命名，而不是在 WORKING-STORAGE 中命名。
      *同一个索引可选择当前表项中的各个子项。
      *SET 显式指定起始表项。
      *SET UP BY 使索引前进到下一个表项。
      *数字计数可以与索引进行比较。
      *循环在显示帐户之前检查其条件。
      *最后一个增量不显示另一个表条目。
      *索引引用不需要额外的下标。
      *字段名称在任一选择器下均保留其含义。
       IDENTIFICATION DIVISION.
       PROGRAM-ID. INDEX12.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *每个帐户条目都包含其密钥和当前样本余额。
       01 WS-ACCOUNT-TABLE.
          05 WS-ACCOUNT-ENTRY OCCURS 4 TIMES
             INDEXED BY WS-ACCOUNT-IDX.
             10 WS-ACCOUNT-NUMBER PIC X(10).
             10 WS-ACCOUNT-BALANCE PIC 9(7)V99.
      *索引是隐含在INDEXED BY中的；它没有 PIC 声明。
       01 WS-LAST-ACCOUNT PIC 9 VALUE 4.
       01 WS-PROCESSED-COUNT PIC 9(3) VALUE ZERO.
       PROCEDURE DIVISION.
      *在索引遍历表之前加载每个表出现的位置。
       0000-MAIN.
           PERFORM 1000-LOAD-ACCOUNTS
           PERFORM 2000-DISPLAY-ACCOUNTS
           PERFORM 9000-REPORT
           STOP RUN.
      *用其普通数字下标填充每个帐户。
       1000-LOAD-ACCOUNTS.
           MOVE "0001234567" TO WS-ACCOUNT-NUMBER(1)
           MOVE 1000.00 TO WS-ACCOUNT-BALANCE(1)
           MOVE "0007654321" TO WS-ACCOUNT-NUMBER(2)
           MOVE 250.75 TO WS-ACCOUNT-BALANCE(2)
           MOVE "0000000042" TO WS-ACCOUNT-NUMBER(3)
           MOVE 0.00 TO WS-ACCOUNT-BALANCE(3)
           MOVE "0002468101" TO WS-ACCOUNT-NUMBER(4)
           MOVE 520.00 TO WS-ACCOUNT-BALANCE(4).
      *设置表索引，访问每个事件，然后递增它。
       2000-DISPLAY-ACCOUNTS.
           SET WS-ACCOUNT-IDX TO 1
           PERFORM UNTIL WS-ACCOUNT-IDX > WS-LAST-ACCOUNT
               PERFORM 2100-DISPLAY-ONE-ACCOUNT
               SET WS-ACCOUNT-IDX UP BY 1
           END-PERFORM.
      *在帐户条目的两个字段中使用当前索引。
       2100-DISPLAY-ONE-ACCOUNT.
           DISPLAY "ACCOUNT="
               WS-ACCOUNT-NUMBER(WS-ACCOUNT-IDX)
               " BALANCE="
               WS-ACCOUNT-BALANCE(WS-ACCOUNT-IDX)
           COMPUTE WS-PROCESSED-COUNT =
               WS-PROCESSED-COUNT + 1.
      *报告索引循环访问了多少加载条目。
       9000-REPORT.
           DISPLAY "PROCESSED=" WS-PROCESSED-COUNT.
      *INDEXED BY 声明与此 OCCURS 表关联的索引。
      *WS-ACCOUNT-IDX 不是 PIC 数字工作存储字段。
      *SET WS-ACCOUNT-IDX TO 1 选择第一个表项。
      *SET UP BY 1 使索引前进到下一个表项。
      *两个选择器在表引用中都使用括号。
      *数据项声明告诉我们正在使用哪个选择器。
      *第 11 课改为使用 WS-SAMPLE-INDEX PIC 9(2) 作为下标。
      *数字下标存储用于指定表项编号的数值。
      *索引是一个单独的选择器，其值通过 SET 设置。
      *索引不是用于数值计算的 PIC 字段。
      *使用 SET UP 或 SET DOWN 在表条目中移动索引。
      *该表声明最多包含四个表项。
      *WS-LAST-ACCOUNT 是一个数字计数，而不是索引本身。
      *该索引与填充的帐户数进行比较。
      *在索引 4 之后，下一个索引超出最后一个条目。
      *然后循环在尝试另一个表引用之前结束。
      *帐号在文本键中保留前导零。
      *零余额仍然属于已填充的条目。
      *每访问一次，处理的计数就会增加一次。
      *索引本身不用作已处理的计数。
      *一组出现中的所有索引字段都使用相同的索引。
      *每个表项都包含重复的账号和余额字段。
      *该程序不会搜索或排序任何表值。
      *第 13 课使用表搜索来关联键和记录。
      *这里的顺序是声明的出现顺序，从1到4。
      *将加载的条目计数保持在声明的 OCCURS 范围内。
      *卸载的条目不得被视为有效的帐户记录。
      *这是内存中的遍历，而不是文件读取操作。
      *GnuCOBOL 支持此固定格式源中的表索引。
      *STOP RUN 结束该索引表演示。
