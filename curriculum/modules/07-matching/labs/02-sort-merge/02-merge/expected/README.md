# 手算预期

Feed-A顺序为Z1、M3、B5；Feed-B顺序为A2、A4、A6。逐步比较完整业务键后，
合并顺序为Z1、A2、M3、A4、A6、B5。输出保留原55字节并追加LF。相同账户和
sequence的A2/M3按ID打破并列。L2桥接预期见`l2-report.txt`与`l2-master.dat`。
