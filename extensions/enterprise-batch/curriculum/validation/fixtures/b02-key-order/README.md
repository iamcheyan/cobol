# B02 主代理独立排序键夹具

输入均为交易v1 55字节ASCII记录加LF，营业日20261009。主代理独立编制，供后续验收；尚未证明B02实现通过。

业务键为账户1–10、序号35–40、ID11–26。`unsorted.dat`依次B(seq2)、Z(seq1)、A(seq2)，正确输出为Z、A、B。整行ASCII排序会产生A、B、Z，因此可检测错误排序键。同序号下A必须先于B。

`merge-left.dat`为Z(seq1)、B(seq2)，`merge-right.dat`为A(seq2)，各自有序，真正MERGE应输出与`expected.dat`逐字节一致。3笔全部保留：贷100+5=105、借10，净变化95；若账户期初100，期末应195。交易ID及原字段不得改写。

夹具哈希见SHA256SUMS。排序/归并输出核对应直接比较bytes与末尾LF，不应只比较splitlines。该夹具不覆盖其他输入异常或业务政策。
