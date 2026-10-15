# 课程导航

每课固定交付 `lesson.cob`、`README.md`、`exercise.md`、`answer.md` 以及该课需要的脚本、Copybook、数据夹具和预期结果；有答案的修改练习与无答案的迁移练习分列在 `exercise.md`，参考答案只回答修改练习。

- [32 课总目录](DIRECTORY.md)：六个阶段的目标、先修关系、耗时估算和源码交付物。
- [第 01 课：Hello COBOL](01_hello-cobol/README.md)：从固定格式程序编译并运行第一条 `DISPLAY`。

想继续练习旧版专题、企业批处理或 Neovim 工作流时，按当前课号查阅[拓展课程索引](../extensions/README.md)；拓展材料不改变本课程的先修顺序。

## 全课程公共约定

- **语言**：README 与源码注释用中文；程序运行输出的业务文本沿用仓库既有的日文（部分接口标记保留英文，如 `POSTED`、`SQLSTATE`）。每课 README 都给出输出标签的中文对照，判断程序行为以实际输出与 README 说明为准。
- **编译器与方言**：GnuCOBOL 3.2.x，使用默认方言，**不加** `-std=cobol85`（严格 85 不支持 `COMP-3`、`FUNCTION TRIM` 等本课程使用的扩展）。
- **源文件格式**：固定格式。第 7 列是指示符区（`*` 为注释），Area A 从第 8 列开始（Division、`FD`/`SD`、`01` 级、段落名），仓库约定 `05` 级从第 11 列、语句从第 12 列开始；有效程序文本不越过第 72 列。本工具链按**字节**判定该边界，含中日文的行会更早触界。
- **构建与清理**：`mkdir -p build` 后用 `cobc` 把可执行文件写进 `build/`（多程序课另用 `copybooks/` 作为 `-I` 路径）；`build/` 已被 `.gitignore` 忽略，`rm -rf build` 一次清理。需要读写业务数据文件的课（16、22、26、27）在 `build/` 里放输入副本并运行，避免改写仓库夹具。
- **数据库课（29–32）**：使用 GixSQL 1.0.20b + SQLite；工具链由第 29 课的 `install-toolchain.sh` 解包到 `build/toolchain/`（不修改系统软件包，仓库不提交二进制），第 30–32 课默认复用它。缺少工具链时这些课的 `build.sh check` 会直接报错，**不要**用模拟 SQL 顶替。
- **完整性检查**：仓库根目录 `make course-check` 检查全部 32 课的交付物存在，并对第 01–28 课做语法检查加第 01 课行为 smoke test；`make course-check-sql` 覆盖第 29–32 课的预编译检查与第 32 课端到端场景。

具体命令、预期输出与未验证范围以每课 README 为准。不要把可执行文件、日志或运行输出当作源文件。
