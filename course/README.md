# GNUCOBOL 全栈课程：从第一条 DISPLAY 到批处理项目

本课程把 COBOL 语言、GnuCOBOL 工具链、Bash 自动化和 `cobol.nvim` 学习工作流放在同一套可运行练习中。目标是让学习者能够读懂并独立完成一个实际批处理程序：定义记录、读取文件、校验数据、执行业务计算、写出结果、打印汇总、提供可靠的 shell 构建与回归测试。

> 课程按“概念 -> 运行 -> 修改 -> 故意出错 -> 工具辅助定位 -> 自己解释”的顺序设计。示例针对 GnuCOBOL，传统源代码遵守固定格式；具体存储布局和扩展行为以当前安装的 GnuCOBOL 与目标平台为准。

## 环境准备

需要 GNU/Linux、macOS 或 WSL；GnuCOBOL（`cobc`）、GNU Make、Bash。建议另装 Neovim 与 `iamcheyan/cobol.nvim`。安装例：

```sh
# Debian / Ubuntu
sudo apt install gnucobol make
# Arch Linux
sudo pacman -S gnucobol make
# macOS
brew install gnu-cobol make

cobc --version
make check
```

每课目录包含 `README.md` 和独立 `.COB` 示例；需要多个文件或测试数据的课程会在该目录里附加 `.CPY`、数据夹具或 Bash 脚本。进入课程目录后，通常这样编译和运行：

```sh
cobc -x -Wall -o build/lesson lesson.COB
./build/lesson
```

`build/` 需要先创建：`mkdir -p build`。若课程含脚本，README 会给出更精确的命令。只做语法检查用 `cobc -fsyntax-only lesson.COB`。

## 学习路线

### 阶段 A：语言与数据基础

| 课 | 内容 |
|---|---|
| [00](lessons/00-environment/) | 环境与第一个程序 |
| [01](lessons/01-program-anatomy/) | 四大部、程序骨架、段落 |
| [02](lessons/02-source-format/) | 固定格式、Area A/B、列边界 |
| [03](lessons/03-names-comments-literals/) | 命名、注释、字面量、句点 |
| [04](lessons/04-data-hierarchy/) | 层级号、分组项、数据区 |
| [05](lessons/05-picture-storage/) | PIC、数值、编辑格式、存储 |
| [06](lessons/06-values-move-arithmetic/) | VALUE、MOVE、算术与溢出 |

### 阶段 B：控制流和数据处理

| 课 | 内容 |
|---|---|
| [07](lessons/07-conditions-88/) | 条件表达式与 88 级条件名 |
| [08](lessons/08-branching-evaluate/) | IF、EVALUATE、分支范围 |
| [09](lessons/09-loops-perform/) | PERFORM 与循环 |
| [10](lessons/10-tables-occurs-search/) | OCCURS、表格、SEARCH |
| [11](lessons/11-strings-unstring-inspect/) | STRING、UNSTRING、INSPECT |
| [12](lessons/12-sequential-files/) | 顺序文件和 READ/WRITE |
| [13](lessons/13-file-status-errors/) | 文件状态、校验和异常路径 |

### 阶段 C：模块化与生产程序

| 课 | 内容 |
|---|---|
| [14](lessons/14-copybooks-redefines/) | COPY、Copybook、REDEFINES |
| [15](lessons/15-subprograms-linkage/) | CALL、LINKAGE、参数传递 |
| [16](lessons/16-intrinsic-functions-dates/) | 内建函数、日期、类型转换 |
| [17](lessons/17-reports-control-break/) | 报表、累计器、控制断点 |
| [18](lessons/18-sort-merge/) | 排序、合并与作业流 |
| [19](lessons/19-modules-environment/) | 多文件工程与运行环境 |
| [20](lessons/20-debugging-diagnostics/) | 调试、编译诊断和定位 |
| [21](lessons/21-compiler-options/) | cobc 选项、格式与方言 |

### 阶段 D：Bash、端到端项目与插件协作

| 课 | 内容 |
|---|---|
| [22](lessons/22-bash-build-run/) | Bash 编译和运行脚本 |
| [23](lessons/23-bash-tests-batch/) | 批量构建与回归测试 |
| [24](lessons/24-bash-pipelines-scheduling/) | 管道、日志、调度和可重跑性 |
| [25](lessons/25-project-csv-pipeline/) | 综合项目：分隔文件到 CSV |
| [26](lessons/26-project-fixed-records/) | 综合项目：固定宽度记录 |
| [27](lessons/27-plugin-learning-workflow/) | 用 cobol.nvim 练习与排错 |
| [28](lessons/28-capstone-night-batch/) | 结业项目：完整批处理系统 |
| [29](lessons/29-reference-topic-map/) | 知识点总览与 GnuCOBOL 进阶路线 |

## 每课学习闭环

1. 阅读 `README.md` 的目标、概念和注意事项。
2. 先运行原始示例，保存预期输出。
3. 按“修改练习”做小改动，再执行语法检查、编译和运行。
4. 人为制造一个可控错误，分别使用 `cobc` 和插件定位。
5. 修复后检查输入、输出、退出码和边界情况。
6. 用自己的话写下该知识点的规则与尚不确定之处。

课程程序遵循当前仓库的固定格式约定：第 7 列是指示符，第 8 列开始 Area A，第 12 列开始 Area B，有效程序文本到第 72 列。自由格式可作为独立主题练习，但不要把 `-free` 的习惯误用于本仓库固定格式示例。

## 插件学习卡

Neovim 插件是辅助，不是编译器替代品。每个适用课都提供“插件练习”步骤：

- 固定格式：标尺、`g7` / `g8` / `g12` / `g73`、智能注释、格式整理。
- 结构导航：Aerial 大纲、Winbar 面包屑、`gd`、`<C-o>`、折叠。
- 数据：`<leader>cr` / `:CobolCalcRecord` 检查记录长度；数组、重定义和编译 ABI 需要结合目标平台复核。
- 模块：`gf` 打开 Copybook，`K` 预览，`<C-o>` 返回。
- 诊断：`<leader>cl` / `:CobolLint`，`<leader>cq` / `:CobolQuickfix`。

插件安装及按键详情见 [仓库 README](../README.md) 的 Neovim 章节和 [第 27 课](lessons/27-plugin-learning-workflow/)。

## 课程范围与参考

课程按实际开发主题覆盖 COBOL 程序结构、数据描述、运算、条件与循环、表格、字符串、顺序文件、模块化、子程序、报表、排序、编译、诊断和作业自动化。COBOL 标准与厂商方言十分庞大；课程会明确标出 GnuCOBOL 行为，不声称每个历史方言关键字都能在单套教程中穷尽。继续查阅本机 `info gnucobol`、`cobc --help`、GnuCOBOL Programmer's Guide 和 ISO COBOL 标准。

已有实战程序：[`INPUTCSV.COB`](../INPUTCSV.COB)、[`FIXEDREC.COB`](../FIXEDREC.COB)、[`TBLSRCH.COB`](../TBLSRCH.COB)、[`BATCHRPT.COB`](../BATCHRPT.COB)。已有 COBOL 插件专题练习：[`docs/`](../docs/)。
