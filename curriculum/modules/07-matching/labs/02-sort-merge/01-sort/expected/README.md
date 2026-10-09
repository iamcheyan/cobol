# 手算预期

按三段业务键排序：账户、sequence、transaction_id。逐行人工追踪结果为
Z1(seq1)、A2(seq2)、M3(seq2)、A4(seq3)、A6(acct2/seq1)、B5(acct2/seq1)。
前55字节分别从输入记录原样抄出，每行加一个LF。Z序号先于字典序更小的A，
同sequence下A又排在M之前；这证明结果不是整行ASCII排序，也不是account/id排序。
