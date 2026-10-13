# COBOL 知识点地图与进阶路线

本课是课程目录的查漏索引，帮助你把前 29 个主题放进完整的 GNUCOBOL 开发图景。COBOL 的标准、历史方言和厂商扩展范围很大，下面明确区分核心批处理课程与需要单独环境的专题，不把少见关键字或 IBM 专有环境伪装成已实操内容。

## 核心语言知识地图

| 知识域 | 知识点 | 对应课程 |
|---|---|---|
| 程序组织 | IDENTIFICATION / ENVIRONMENT / DATA / PROCEDURE DIVISION；SECTION、Paragraph、句点和作用域终止符 | [01](../01-program-anatomy/)、[02](../02-source-format/) |
| 源码规则 | 固定格式、自由格式、Area A/B、指示符、注释、续行、编译器列限制 | [02](../02-source-format/) |
| 标识符 | 用户名、保留字、命名规则、字面量、字符串引号、注释 | [03](../03-names-comments-literals/) |
| 数据层级 | 01–49、66 RENAMES、77、78 常量、88 条件名；组项与基本项；WORKING-STORAGE / LOCAL-STORAGE / LINKAGE | [04](../04-data-hierarchy/)、[07](../07-conditions-88/) |
| 数据描述 | PIC 符号 X/A/9/V/S/P、编辑符号、VALUE、JUSTIFIED、SIGN、USAGE DISPLAY/COMP/COMP-3；REDEFINES；OCCURS / OCCURS DEPENDING ON；SYNCHRONIZED | [05](../05-picture-storage/)、[10](../10-tables-occurs-search/)、[14](../14-copybooks-redefines/) |
| 数据操作 | MOVE、INITIALIZE、SET、CORRESPONDING、算术动词、COMPUTE、ROUNDED、ON SIZE ERROR | [06](../06-values-move-arithmetic/)、[07](../07-conditions-88/) |
| 控制流 | IF/ELSE、EVALUATE、PERFORM、循环、内联 PERFORM、EXIT PERFORM、段落调用 | [08](../08-branching-evaluate/)、[09](../09-loops-perform/) |
| 表格 | OCCURS、下标、INDEXED BY、SEARCH、SEARCH ALL、排序前提和边界 | [10](../10-tables-occurs-search/)、[18](../18-sort-merge/) |
| 字符串 | STRING、UNSTRING、INSPECT、DELIMITED BY、TALLYING、WITH POINTER、引用修改 | [11](../11-strings-unstring-inspect/) |
| 文件处理 | SELECT、ASSIGN、FD/SD、OPEN、READ、WRITE、REWRITE、DELETE、CLOSE、文件状态、顺序/行顺序/相对/索引组织 | [12](../12-sequential-files/)、[13](../13-file-status-errors/) |
| 模块化 | COPY、Copybook、COPY REPLACING、REDEFINES、CALL、CANCEL、LINKAGE、BY REFERENCE/CONTENT/VALUE、RETURNING | [14](../14-copybooks-redefines/)、[15](../15-subprograms-linkage/) |
| 内建函数 | TRIM、LENGTH、NUMVAL、CURRENT-DATE、日期/整数/数值函数及输入转换校验 | [16](../16-intrinsic-functions-dates/) |
| 批处理业务 | 控制断点、小计/总计、报表、SORT/MERGE、错误计数、作业退出码 | [17](../17-reports-control-break/)、[18](../18-sort-merge/)、[25](../25-project-csv-pipeline/)、[26](../26-project-fixed-records/) |
| 工程质量 | 编译方言、警告、诊断、调试、构建依赖、测试夹具、日志和幂等作业 | [19](../19-modules-environment/)、[20](../20-debugging-diagnostics/)、[21](../21-compiler-options/)、[22](../22-bash-build-run/)、[23](../23-bash-tests-batch/)、[24](../24-bash-pipelines-scheduling/) |

## 需要单独开课的 GnuCOBOL 专题

这些能力依赖具体终端、外部数据库/协议、编译构建方式或使用场景；先完成核心课程，再用 GnuCOBOL Programmer's Guide 和本机 `cobc --help` 针对项目版本学习：

- **ACCEPT / DISPLAY 扩展**：命令行参数、环境变量、标准输入、终端属性与返回值。
- **SORT/MERGE 实战**：SD 工作文件、输入/输出过程、临时目录和大数据集资源策略。
- **相对与索引文件**：键定义、INVALID KEY、锁定和并发访问。文件系统行为需实机验证。
- **屏幕节（SCREEN SECTION）**：交互终端输入输出；不适用于纯后台批处理程序。
- **报告编写器（REPORT SECTION）**：报表页控制与旧式运行环境兼容性。
- **调用约定与链接**：静态/动态调用、共享库、C 接口、ABI 和部署依赖。
- **SQL / 嵌入式数据库**：需要相应数据库客户端、预编译器或 GnuCOBOL 集成模块，非基础 `cobc` 环境默认能力。
- **XML / JSON / sockets / CGI / GUI**：通过 GnuCOBOL 库、外部程序或平台扩展实现，先检查目标环境的模块与许可证。
- **面向对象 COBOL 与现代标准差异**：依赖编译器实现和目标运行时；不要把某家大型机方言直接当作 GnuCOBOL 通用语法。
- **国际化、字符集和区域设置**：UTF-8、EBCDIC、排序规则、decimal point 与 locale，需用实际输入和目标系统验证。
- **安全与生产运行**：文件权限、路径穿越、临时文件、敏感数据日志、并发控制、审计、重试与幂等。

## 下一步实践

从结业课 [28](../28-capstone-night-batch/) 选一个实际数据流程，写出输入/输出契约和失败矩阵，再补充你用到的进阶主题。新增主题时沿用“单独目录 + 说明 + 固定格式源码 + 编译运行命令 + 修改练习 + 插件练习”的课程结构。
