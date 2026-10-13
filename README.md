# GnuCOBOL 实战课程工作台

本仓库以 [32 课主课程](lessons/README.md) 为学习入口：从最小 COBOL 程序开始，逐步学习数据描述、流程控制、表格、文件、模块化、数据库和银行对账项目。课程总目录列出每课目标、先修知识、预计时间、项目联系与源码产物：[`lessons/DIRECTORY.md`](lessons/DIRECTORY.md)。

## 快速开始

需要 GNU/Linux、GnuCOBOL（`cobc`）和 Make。Debian/Ubuntu 可安装：

```sh
sudo apt install gnucobol make
cobc --version
```

先进入 [第 01 课](lessons/01/README.md)，按课内说明编译并运行：

```sh
cd lessons/01
mkdir -p build
cobc -fsyntax-only lesson_01.cob
cobc -x -Wall -o build/lesson_01 lesson_01.cob
./build/lesson_01
```

后续课程可能包含 Copybook、输入夹具、构建脚本或真实数据库依赖；每课的 README 说明需要的依赖、命令和预期结果。编译产物留在各课的 `build/`，不作为课程源码提交。

检查 32 课文件齐全并编译运行第 01 课：

```sh
make course-check
```

旧版扩展课程另有入口：`make legacy-course-check`。

## 仓库导航

| 路径 | 用途 |
|---|---|
| [`lessons/`](lessons/README.md) | CPR #31 主课程，01–32 课；每课保留源码、讲解、练习、答案及所需素材 |
| [`extensions/README.md`](extensions/README.md) | 可选课程、扩展课程、插件教程和独立示例索引 |
| [`extensions/legacy-workshop/`](extensions/legacy-workshop/README.md) | 旧版 00–29 课，作为补充讲义与练习素材 |
| [`extensions/enterprise-batch/`](extensions/enterprise-batch/README.md) | 企业批处理扩展：12 个模块、银行夜间处理案例及验收入口 |
| [`docs/`](docs/01-punchcard-and-ruler.md) | `cobol.nvim` 标尺、导航、PIC、诊断、工作流与插件实验教程 |
| [`Makefile`](Makefile) | 根目录独立 COBOL 示例的语法检查、构建、运行与清理 |

## 独立示例

根目录还保留四个可单独编译的示例：`INPUTCSV.COB`、`FIXEDREC.COB`、`TBLSRCH.COB` 和 `BATCHRPT.COB`。它们演示分隔文本转 CSV、定长记录、表格查找和控制断点报表；相关 Copybook 与输入数据也保留在根目录。

```sh
make check   # 语法检查四个独立示例
make run     # 编译并运行示例，展示输出文件
make clean   # 清理根目录生成的程序和输出
```

Neovim 插件是辅助学习工具，不替代 `cobc` 编译和程序运行。安装与插件练习见 [`docs/07-cobol-nvim-plugin-lab.md`](docs/07-cobol-nvim-plugin-lab.md)。
