# 未选用候选：Open-COBOL-ESQL

源码固定commit `e116b6ad12d73f8849667fd1f98da62eda2153db`（1.4.0）。上游[README](https://github.com/opensourcecobol/Open-COBOL-ESQL)列出的GnuCOBOL测试版本是2.2，不能据此认定3.2完全兼容。

复现入口 `bash curriculum/validation/rejected-ocesql/check.sh`。这不是通过检查，**预期失败**，保留用于说明选型依据。会构建独立镜像、启动一次性PostgreSQL，退出清理容器和网络。

本机观察：COMP/COMP-5 Indicator声明被预编译器拒绝；改为DISPLAY后可预编译，但FETCH把Indicator当作额外结果参数，返回YE002/参数与结果数量不匹配，没能完成真实NULL游标门禁。保留源码供再次复核，不把失败隐藏成“已支持”。同一候选将 `:VALUE :IND` 和 `:VALUE:IND` 两种写法分别验证；本包保留后一种。

构建必须有pkg-config；SQLCA实际安装路径是`/usr/local/share/open-cobol-esql/copy`。本系统需明确预加载绝对路径libocesql.so才能找到动态CALL模块。修复构建和加载并未解决NULL门禁，因此最终转向GixSQL并继续做真实断言。
