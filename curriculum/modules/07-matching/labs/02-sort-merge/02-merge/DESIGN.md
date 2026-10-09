# 07.2 MERGE：合并已排序交易流

## 接口与顺序

每个源均为TRANSACTION v1：55 ASCII字节+LF；每源独立按(account_id 1–10, sequence_no 35–40, transaction_id 11–26)严格升序。空源允许。全局输出同一全键升序、规范LF，逐记录保留原55字节，不重解释/改写transaction_id或sequence。日期、ID、方向、金额和状态校验同07.1，金额零保留给下游业务分类；状态仅N。完整键相同等价重复全局transaction_id，RC8；不同ID、相同账户和sequence合法，以ID升序打破并列；重复ID跨源或相距任意远均RC8。

MERGE先流式检查每个源的物理宽度、LF、字段和各自排序，再由COBOL `MERGE ... USING source-1 source-2 ... OUTPUT PROCEDURE` 实际合并；不允许先连接再SORT，也不依赖输入流偶然相序。相同全键不定义稳定源优先级，因为该键必定被重复ID契约拒绝。

人工预期：Feed-A含(1,1,Z…001),(1,2,M…003),(2,1,B…005)；Feed-B含(1,2,A…002),(1,3,A…004),(2,1,A…006)。两流各自已排序；正确输出为Feed-B A…002先于Feed-A M…003，同序号由ID决定。L2桥接使用ACCOUNT 1期初1000、ACCOUNT 2期初100，T01入500、同序号A…002入100/M…003出50、T04冲正T01出500、账户2收10/支10，期末分别1050与100。

## RC与发布

RC0仅在所有输入先校验、MERGE完成、全局ID唯一、SORT-RETURN=0、输出逐字节验证后发布。RC8表示格式/日期/字段/单流逆序/重复ID；RC12表示系统/临时空间/权限/锁/构建/意外SORT-RETURN/核验/发布失败。所有非成功RC无正式输出。流式核验从每条源顺序与merge输出检查计数、全键顺序、字段字节保持及跨源全局ID唯一。
