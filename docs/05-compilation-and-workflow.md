# 第 5 课：GnuCOBOL 构建、批处理测试与工程实战 (Build, Test & Workflow)

在前面的课程中，我们掌握了如何在 Neovim 中高效编写、排布并检查 COBOL 代码。

本课聚焦于工程化落地：如何使用 `Makefile` 与命令行工具完成 COBOL 项目的编译、链接、测试与批量执行，理解 COBOL 与真实操作系统之间的文件交互。

---

## 1. 核心理论：GnuCOBOL 编译器构建机制

COBOL 不是脚本解释型语言，它是严谨的**编译型语言**。

`cobc`（GnuCOBOL 编译器）在幕后的工作流程非常精妙：
1. **源码解析与预处理（Preprocess）**：展开所有 `COPY "FOO.CPY"` 宏；
2. **源码转译（Transpile）**：将 COBOL 代码转译为极其高效的纯 C 语言源码（`.c`）；
3. **C 编译器驱动（Compile & Link）**：调用宿主系统的 C 编译器（如 GCC 或 Clang），链接 COBOL 运行时支持库（`libcob`），最终生成原生的二进制可执行文件（ELF 或 Mach-O）。

### 常用 `cobc` 编译指令

| 命令 | 用途与参数说明 |
|---|---|
| `cobc -fsyntax-only <file>` | **纯语法飞检**：只检查语法，不生成任何中间或二进制文件，速度极快（插件底层即用此选项） |
| `cobc -x -o <binary> <file>` | **生成独立可执行程序**：`-x` 表示生成可执行文件（包含 `main` 入口），输出指定二进制文件名 |
| `cobc -I <dir>` | **指定 Copybook 搜寻路径**：告知编译器去哪里查找引用的 `.CPY` 文件 |
| `cobc -Wall` | **开启全量警告**：对废弃语法（如 `AUTHOR.`）、跨节跳转等给出专业提示 |

> ⚠️ **新手陷阱**：不要给现代 GnuCOBOL 随意传递 `-std=cobol85` 参数。严格的 COBOL 85 标准不支持 IBM 常用扩展（如 `COMP-3`）与现代内建函数（如 `FUNCTION TRIM`）。使用默认方言即可完美兼容大型机扩展与现代特性。

---

## 2. 学习仓库中的 Makefile 工程化设计

在 `/home/tetsuya/development/cobol` 中，我们配备了标准生产级的 `Makefile`：

```makefile
COBC = cobc
SRC = INPUTCSV.COB
BIN = INPUTCSV
INPUT = input.txt
OUTPUT = output.csv

.PHONY: all check run clean

all: $(BIN)

check:
	$(COBC) -fsyntax-only $(SRC)

$(BIN): $(SRC) EMP-REC.CPY
	$(COBC) -x -o $(BIN) $(SRC)

run: $(BIN)
	./$(BIN)
	@echo "=== Output CSV Preview ==="
	@cat $(OUTPUT)

clean:
	rm -f $(BIN) $(OUTPUT)
```

---

## 3. 实操任务清单 (Step-by-Step)

在终端中执行以下命令体验端到端跑批：

```bash
cd /home/tetsuya/development/cobol
```

### 任务 5.1：语法自检（`make check`）
在正式编译之前，先做语法合法性快速自检：
```bash
make check
```
**观察输出**：无任何报错退出，说明当前所有语法与 Copybook 引用 100% 正确。

### 任务 5.2：编译构建原生程序（`make`）
```bash
make
```
**观察输出**：
- 执行了 `cobc -x -o INPUTCSV INPUTCSV.COB`；
- 生成了一个原生 Linux ELF 可执行程序 `INPUTCSV`。输入 `file INPUTCSV` 可以看到它是标准的 64 位原生二进制。

### 任务 5.3：查看输入原始数据
在批处理运行前，先看一眼待处理的源文本 `input.txt`：
```bash
cat input.txt
```
内容是以竖线 `|` 分隔的管道定长数据：
```text
1001|John Doe|28|75000.50|
1002|Jane Smith|34|92000.00|
1003|Bob Johnson|45|105000.75|
```

### 任务 5.4：运行批处理作业（`make run`）
```bash
make run
```
**观察控制台输出**：
```text
==================================================
COBOL INPUTCSV DEMO: Processing Started...
==================================================
1000-INITIALIZE: Output file ready.
3000-PARSE-RECORD: Record parsed -> ID=1001, Name=John Doe, Age=28, Salary=75000.50
4000-FORMAT-AND-WRITE: Wrote -> 1001,"John Doe",28,75000.50
3000-PARSE-RECORD: Record parsed -> ID=1002, Name=Jane Smith, Age=34, Salary=92000.00
4000-FORMAT-AND-WRITE: Wrote -> 1002,"Jane Smith",34,92000.00
3000-PARSE-RECORD: Record parsed -> ID=1003, Name=Bob Johnson, Age=45, Salary=105000.75
4000-FORMAT-AND-WRITE: Wrote -> 1003,"Bob Johnson",45,105000.75
==================================================
9000-FINALIZE: Processing Complete.
Records Read    : 0000003
Records Written : 0000003
Records Skipped : 0000000
Total Salary    : 00272001.25
==================================================
=== Output CSV Preview ===
EmployeeID,FullName,Age,Salary
1001,"John Doe",28,75000.50
1002,"Jane Smith",34,92000.00
1003,"Bob Johnson",45,105000.75
```
整个批处理执行了以下操作：
1. `1000-INITIALIZE`：打开输入输出流并写入 CSV 头部；
2. `2000-PROCESS-FILE`：主循环逐行读入；
3. `3000-PARSE-RECORD`：使用 `UNSTRING` 按照 `|` 将文本安全拆分进工作区字段；
4. `4000-FORMAT-AND-WRITE`：使用 `STRING` 与 `FUNCTION TRIM` 智能去除名字两侧多余空格、拼接双引号与逗号生成合法 CSV 记录；
5. 自动累加 `COMP-3` 薪资与读取计数器；
6. `9000-FINALIZE`：关闭文件句柄并格式化打印批处理统计报表。

### 任务 5.5：环境清理与重新跑批（`make clean`）
```bash
make clean
```
自动清除生成的可执行文件与输出文件，保持 Git 工作区干净。

---

## 4. 本课速查总结

| 命令 | 作用说明 |
|---|---|
| `make check` | 快速执行语法飞检（`cobc -fsyntax-only`） |
| `make` | 编译链接生成可执行二进制文件（`INPUTCSV`） |
| `make run` | 编译并运行批处理，将 `input.txt` 转换为 `output.csv` 并输出统计指标 |
| `make clean` | 清理编译生成物与运行生成文件 |
