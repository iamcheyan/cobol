# COBOL 现代化实战工坊 (COBOL Hands-on Workshop & Modern Tooling)

> 🚀 从穿孔卡到现代终端：一个现代开发者边学边用的 COBOL 实战演练场与 Neovim 工具链。

本项目是一个专为现代开发者设计的 **COBOL 语言实战学习与现代化开发工坊**。包含完整的生产级固定格式（Fixed-Format）代码范例、Copybook 模块依赖、编译运行工具链，以及专为 Neovim 打造的 COBOL 现代化增强套件体验指南。

---

## 目录

- [1. 快速开始 (Quickstart)](#1-快速开始-quickstart)
- [2. COBOL 核心语法极速入门 (Crash Course)](#2-cobol-核心语法极速入门-crash-course)
  - [2.1 四大部（Four Divisions）骨架](#21-四大部four-divisions骨架)
  - [2.2 穿孔卡 80 列固定格式规则](#22-穿孔卡-80-列固定格式规则)
  - [2.3 变量层级与 88 级条件名 (Enum)](#23-变量层级与-88-级条件名-enum)
  - [2.4 PIC 图像子句与内存存储模式 (COMP / COMP-3)](#24-pic-图像子句与内存存储模式-comp--comp-3)
  - [2.5 Copybook 模块化机制](#25-copybook-模块化机制)
  - [2.6 常用控制流与现代函数](#26-常用控制流与现代函数)
- [3. 范例代码深度拆解 (`INPUTCSV.COB`)](#3-范例代码深度拆解-inputcsvcob)
- [4. Neovim 现代化 COBOL 插件使用指南](#4-neovim-现代化-cobol-插件使用指南)
  - [4.1 快捷键速查表](#41-快捷键速查表)
  - [4.2 七步实战演练法](#42-七步实战演练法)
- [5. 边学边建：插件共建路线图 (Roadmap)](#5-边学边建插件共建路线图-roadmap)

---

## 1. 快速开始 (Quickstart)

本项目使用开源的 **GnuCOBOL (`cobc`)** 编译器。

### 环境依赖安装

```bash
# Arch Linux
sudo pacman -S gnucobol

# Ubuntu / Debian
sudo apt-get install gnucobol

# macOS (Homebrew)
brew install gnu-cobol
```

### 编译与运行

项目内置了便捷的 `Makefile`：

```bash
# 语法静态检查（飞检）
make check

# 编译并运行转换程序（读取 input.txt 并生成 output.csv）
make run

# 清理编译产物
make clean
```

### 运行结果演示

输入文件 `input.txt`：
```text
00001|Taro Yamada|28|350000
00002|Hanako Suzuki|31|420000
00003|Ken Sato|25|280000
```

程序执行输出 `output.csv`：
```csv
employee_id,name,age,salary
00001,"Taro Yamada",28,350000
00002,"Hanako Suzuki",31,420000
00003,"Ken Sato",25,280000
```

---

## 2. COBOL 核心语法极速入门 (Crash Course)

COBOL（Common Business-Oriented Language）由 Grace Hopper 准将于 1959 年设计，是金融、银行和核心大型机系统的顶梁柱。

### 2.1 四大部（Four Divisions）骨架

每个完整的 COBOL 程序自上而下严格由 4 大 Division 构成：

```text
IDENTIFICATION DIVISION.  ── 程序名、作者、元数据声明
ENVIRONMENT DIVISION.     ── 硬件环境与文件 I/O 映射 (FILE-CONTROL)
DATA DIVISION.            ── 所有内存变量、文件结构 (FD)、工作区 (WORKING-STORAGE)
PROCEDURE DIVISION.       ── 所有可执行逻辑、段落 (Paragraphs)、循环与控制流
```

### 2.2 穿孔卡 80 列固定格式规则

COBOL 诞生于穿孔卡片时代，源码严格以 80 字符列对齐：

```text
列号: 1----6  7   8---11  12---------------------------------------------72  73----80
区域: SEQ    IND  Area A  Area B (语句主体)                                  IDENT
刻度: ..SEQ.  *    A...    B............................................72  IDENT...
代码: 000100      0000-MAIN-LOGIC SECTION.
```

* **列 1~6（Sequence Number）**：序列号区（用于穿孔卡乱序时重新排卡，现代通常留空或填入行号）。
* **列 7（Indicator）**：指示符区：
  * `*` 或 `/`：整行注释；
  * `-`：字符串或语句跨行续接；
  * `D`：调试行（开启 Debug 时编译）。
* **列 8~11（Area A）**：**顶格声明区**。以下内容必须从第 8 列开始：
  * `IDENTIFICATION / ENVIRONMENT / DATA / PROCEDURE DIVISION.`
  * 各类 `SECTION.`
  * 过程段落名（如 `1000-INITIALIZE.`）
  * 数据部根结构：`01` 级记录、`77` 级独立项、`FD` / `SD` 文件描述符。
* **列 12~72（Area B）**：**语句执行与子数据区**。
  * 所有具体操作语句（`MOVE`, `PERFORM`, `IF`, `OPEN`, `CLOSE` 等）必须在第 12 列或之后书写；
  * 从属数据级别（`05`, `10`, `15`, `88` 等）必须在第 12 列或之后书写。
* **列 73~80（Identification Area）**：程序库识别区，**编译器完全忽略该区域的所有字符**！

> ⚠️ **新手大坑**：若代码不小心写到了第 73 列以后，编译器会直接当作空白忽略，导致语句神秘截断或变量名不全。

---

### 2.3 变量层级与 88 级条件名 (Enum)

COBOL 的变量通过层级编号（Level Numbers）构建树状结构：

```cobol
01  WS-FLAGS.                          *> 顶层根对象（相当于 C struct 或 JS object）
    05  WS-EOF-FLAG      PIC X VALUE "N". *> 成员字段
        88  EOF-YES      VALUE "Y".    *> 88 级：条件名（枚举/布尔别名）
        88  EOF-NO       VALUE "N".
```

#### 88 级的神奇用法：
`88` 级并不占用额外的内存空间，它赋予了底层变量一个**语义化的布尔谓词**：
* 赋值：`SET EOF-YES TO TRUE` 等价于 `MOVE "Y" TO WS-EOF-FLAG`。
* 判断：`IF EOF-YES` 等价于 `IF WS-EOF-FLAG = "Y"`。

---

### 2.4 PIC 图像子句与内存存储模式 (COMP / COMP-3)

`PIC`（Picture Clause）定义数据的物理呈现与内存字节：

| 语法 | 含义 | 占用字节数 | 示例说明 |
|---|---|---|---|
| `PIC X(20)` | 定长文本（空格右填充） | 20 字节 | 存储 ASCII/EBCDIC 字符串 |
| `PIC 9(5)` | 5 位非负整数（字符形式） | 5 字节 | 例如 `"00123"` |
| `PIC 9(5)V99` | 隐式小数点（5整数+2小数） | 7 字节 | `V` 不占物理空间，仅做编译器换算 |
| `PIC S9(7) COMP-3` | 压缩十进制（Packed-Decimal） | **4 字节** | 核心大型机金融标准：`(7+1)/2 = 4B` |
| `PIC S9(4) COMP` | 二进制整数（半字 Halfword） | **2 字节** | 占用 16 位整型空间 |
| `PIC S9(9) COMP` | 二进制整数（全字 Fullword） | **4 字节** | 占用 32 位整型空间 |

> 💡 **COMP-3 为什么重要？**
> 在大型机中，一个字节可以利用高低 4 位分别存储两个十进制数字，末尾 4 位存储正负符号（`C`/`D`/`F`）。这不仅能节省 50% 的磁盘和内存空间，还能彻底消除浮点数精度丢失问题！

---

### 2.5 Copybook 模块化机制

大型机时代没有 npm 或 import，依赖管理全部通过 **Copybook（`.CPY`）**：

```cobol
COPY "EMP-REC.CPY".
```

在预编译时，编译器会将 `EMP-REC.CPY` 里的数据结构或过程宏原样内联展开到当前代码行中。

---

### 2.6 常用控制流与现代函数

* **循环调用**：
  ```cobol
  PERFORM UNTIL EOF-YES
      PERFORM 2100-PROCESS-RECORD
  END-PERFORM
  ```
* **字符串拆分（UNSTRING）**：
  ```cobol
  UNSTRING INPUT-RECORD
      DELIMITED BY "|"
      INTO IN-EMPLOYEE-ID
           IN-FULL-NAME
           IN-AGE
           IN-SALARY
      TALLYING IN WS-FIELD-COUNT
  END-UNSTRING
  ```
* **字符串拼接与裁剪（STRING + FUNCTION TRIM）**：
  ```cobol
  STRING FUNCTION TRIM(IN-EMPLOYEE-ID) DELIMITED BY SIZE
         "," DELIMITED BY SIZE
         QUOTE DELIMITED BY SIZE
         IN-FULL-NAME DELIMITED BY SIZE
         QUOTE DELIMITED BY SIZE
         INTO CSV-LINE
  END-STRING
  ```

---

## 3. 范例代码深度拆解 (`INPUTCSV.COB`)

整个实战项目分为六大执行阶段，逻辑清晰健壮：

1. **`0000-MAIN`（主控制流）**：
   - 顺序调度 `1000-INITIALIZE` → `2000-PROCESS-FILE` → `9000-FINALIZE`，最后 `STOP RUN` 退出程序。
2. **`1000-INITIALIZE`（初始化与打开）**：
   - 清空标志位，`OPEN INPUT INPUT-FILE` 与 `OPEN OUTPUT OUTPUT-FILE`；
   - 检查文件状态码（`00` 为成功），并写入 CSV 表头。
3. **`2000-PROCESS-FILE`（读取主循环）**：
   - 使用 `READ ... AT END SET EOF-YES TO TRUE` 循环读入每一行。
4. **`3000-PARSE-RECORD`（字段解构）**：
   - 借助 `UNSTRING` 按照 `|` 将单行文本拆分为 ID、姓名、年龄、薪资等独立工作区变量。
5. **`4000-FORMAT-AND-WRITE`（格式化输出）**：
   - 动态计算名字长度，去除多余前导/后缀空格，为姓名包裹双引号并组合成 CSV 行写盘。
6. **`9000-FINALIZE`（收尾与统计）**：
   - `CLOSE` 关闭所有文件，终端打印处理成功与失败计数。

---

## 4. Neovim 现代化 COBOL 插件使用指南

配合安装了专属私有插件 `cobol.nvim` 的 Neovim，你可以享受现代 IDE 般的编辑体验。

### 4.1 快捷键速查表

| 快捷键 | 模式 | 作用对象 | 功能说明 |
|---|---|---|---|
| `<leader>uc` | Normal | 全局 | **一键开关** COBOL 细线标尺与 Winbar 打孔卡刻度 |
| `<leader>cs` | Normal | 全局 | **呼出/隐藏 Aerial 符号大纲侧边栏**（回车可跳转） |
| `<leader>cr` | Normal | 01 记录 / 字段 | **计算 01 记录内存排布与字节总和**（居中弹窗展示偏移量表格） |
| `<leader>cl` | Normal | 全局 | **立即触发 GnuCOBOL 语法飞检**（Cobol Lint，状态栏提示结果） |
| `<leader>cq` | Normal | 全局 | **打开诊断 Quickfix 列表**（集中浏览与跳转所有错误与告警） |
| `gd` | Normal | 段落 / 变量 / Copybook | **直达定义**（跳到段落定义行、数据字段行或 Copybook 文件） |
| `<C-o>` | Normal | 全局 | **跳回原位置**（Neovim 原生 Jumplist/Tagstack 回退） |
| `gf` | Normal | `COPY` 语句 | **打开文件**（直接打开光标处引用的 Copybook 实体文件） |
| `K` | Normal | `COPY` / `PERFORM` / 变量 | **悬停浮窗预览**（就地预览 Copybook 内容或过程代码，按 `q` 退出） |
| `g7` | Normal | 当前行 | 光标直跳 **第 7 列**（Indicator 注释指示列） |
| `g8` | Normal | 当前行 | 光标直跳 **第 8 列**（Area A 起始列） |
| `g12` | Normal | 当前行 | 光标直跳 **第 12 列**（Area B 起始列） |
| `g73` | Normal | 当前行 | 光标直跳 **第 73 列**（Identification 识别区起始列） |
| `<leader>c*` | Normal / Visual | 当前行 / 多选选区 | **在第 7 列切换 `*` 注释**（绝不破坏后续代码缩进） |
| `<Tab>` | Insert | 行首或前导空白 | **智能吸附**：1~6 列跳 Area A（8列），7~11 列跳 Area B（12列） |
| `q` 或 `<Esc>` | Normal | 预览/计算浮窗内 | **随手关闭** 悬停预览或内存计算浮窗 |

---

### 4.2 九步实战演练法（快速自测）

打开测试文件开始动手练习：

```bash
nvim INPUTCSV.COB
```

1. **练习 1：标尺与列穿梭**（`g8` / `g12` / `g7` / `<leader>uc`）
2. **练习 2：智能 Tab 与智能注释**（行首 `<Tab>` 吸附 / `<leader>c*`）
3. **练习 3：72 列越界防线**（超 72 列字符标红波浪线警告）
4. **练习 4：Aerial 层级大纲树**（`<leader>cs` 呼出 3 层符号树并回车跳转）
5. **练习 5：过程与变量定义直达**（`gd` 秒级跳定义，`<C-o>` 原路跳回）
6. **练习 6：Copybook 浮窗预览与打开**（`K` 就地浮窗预览结构，`gf` 直接打开文件）
7. **练习 7：行尾数据层级宿主回溯**（`← 05 PARENT (01 ROOT)` 虚词提示）
8. **练习 8：PIC 字节计算与 01 结构体内存排布报表**（行尾提示 / `<leader>cr` 弹出内存排布 ASCII 表）
9. **练习 9：GnuCOBOL 异步实时语法飞检与诊断**（保存/编辑实时波浪线下划线 / `<leader>cl` / `<leader>cq`）

---

## 5. 边学边练：分章节详细教程手册 (Modular Tutorials)

为了方便系统化循序渐进练习，我们已将全部理论与每一步的实操按主题拆分为独立章节教程，可按顺序逐篇学习：

| 章节手册 | 核心内容与实战重点 | 对应插件功能 |
|---|---|---|
| 📖 **[第 1 课：穿孔卡 80 列标准与标尺列穿梭](docs/01-punchcard-and-ruler.md)** | 80 列穿孔卡历史、Area A/B 规则、Indicator 列、72 列越界截断防线、标尺开关与智能 Tab 吸附 | 细线标尺、Winbar 刻度、`g7/g8/g12/g73`、`<leader>uc`、`<leader>c*` |
| 🗺️ **[第 2 课：结构概览、大纲树与代码定义直达](docs/02-structure-and-navigation.md)** | 四大 Division 体系、Winbar 面包屑、Aerial 侧边栏、`PERFORM` 段落与变量跳转、Copybook 浮窗预览 | `<leader>cs`、`gd`、`<C-o>`、`K`、`gf`、行尾宿主回溯 |
| 🧮 **[第 3 课：数据层级与 PIC 内存计算器](docs/03-pic-and-memory-calculator.md)** | COBOL 数据类型、`COMP-3`（Packed Decimal 压缩十进制）原理与换算、行尾字节提示、`01` 结构体内存排布报表 | 行尾虚拟文本、`<leader>cr`、`:CobolCalcRecord` |
| 🩺 **[第 4 课：GnuCOBOL 异步实时语法飞检与排错](docs/04-syntax-check-and-diagnostics.md)** | 避开新手三大深坑（句号 `.`、Area 错位、未定义标识符）、实时非阻塞飞检、Diagnostics 红色波浪线、Quickfix 排错 | `<leader>cl`、`<leader>cq`、`:CobolLint`、Neovim Diagnostics |
| ⚙️ **[第 5 课：GnuCOBOL 构建、批处理测试与工程实战](docs/05-compilation-and-workflow.md)** | `cobc` 编译机制、Makefile 自动化构建、输入输出管道文件处理、端到端跑批与数据校验 | `make check`、`make`、`make run`、`make clean` |

---

## 6. 边学边建：插件共建路线图 (Roadmap)

我们在实践中一边学习 COBOL 语言特性，一边为其构建现代化的编辑器工具：

- [x] **Phase 1: 穿孔卡标尺与安全边界**（细线标尺、Winbar 打孔卡刻度、72 列越界告警、第 7 列智能注释、智能 Tab 吸附）
- [x] **Phase 2.1: 结构大纲与层级展示**（Winbar 实时面包屑、01/88 级高亮、行尾宿主回溯、Aerial 3 层符号树）
- [x] **Phase 2.2: 代码定义直达与 Copybook 预览**（`gd` 段落/变量定义直达、`<C-o>` 原生回跳、`gf` 文件跳转、`K` 悬停浮窗）
- [x] **Phase 3: 数据层级与 PIC 结构计算器**：
  - 单项 PIC 字节换算（`PIC S9(7) COMP-3` 换算为 `4B`）；
  - `01 RECORD` 自动递归向下累加所有子字段字节数，在行尾显示 `/* Total: 398 Bytes (6 fields) */`；
  - `<leader>cr` / `:CobolCalcRecord` 居中弹窗展示各字段偏移量与内存排布 ASCII 表格。
- [x] **Phase 4: GnuCOBOL (`cobc`) 异步实时语法飞检**：
  - 异步在后台调用 `cobc -fsyntax-only`，保存（`BufWritePost`）、内容修改防抖（`TextChanged`）及离开插入模式（`InsertLeave`）时自动飞检；
  - 将漏写标点 `.`、未定义段落/变量、Area A/B 错位等语法错误直接以 Neovim Diagnostics 红黄波浪线标红；
  - Copybook 穿透联动与 `<leader>cl` / `<leader>cq` Quickfix 列表。
- [ ] **Phase 5: 原生语法折叠与保留字格式化**：
  - 支持 `za` 一键折叠庞大的 `DATA DIVISION` 或各个 Section；
  - 提供 `:CobolFormatCase` 将关键字规范为全大写。

---

## License

MIT © 2026 iamcheyan
