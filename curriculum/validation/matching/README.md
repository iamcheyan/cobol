# P1：双流状态原型

这是用于验证状态机的微实验，不替代正式账户模型。每条7字节：3位数字键+4位无符号金额，LINE SEQUENTIAL；此原型允许末条无LF，正式银行接口明确要求LF。

`python3 curriculum/validation/matching/check.py` 编译真实COBOL并运行24个正常/边界/异常用例。expected由人工三类键比较定义；Python只写夹具/断言，不做匹配。

原型有两个固定4096字节缓冲、独立EOF和上一个键；不同数据量不增加工作区。更严格的原始字节校验和大数据RSS测量由[正式L1](../../modules/07-matching/labs/01-one-to-one/README.md)提供。本原型stdout只是候选，数据后段失败时可能已经输出部分行，不能直接对外发布。

原型RC0=完成，8=数据异常，12=文件异常。正式课程使用独立运行目录发布，解决候选明细泄露问题。
